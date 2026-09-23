import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/subscription/domain/entities/entitlement_entity.dart';
import 'package:traviato/features/subscription/domain/entities/subscription_offering_entity.dart';
import 'package:traviato/features/subscription/presentation/pages/paywall_page.dart';
import 'package:traviato/features/subscription/presentation/providers/subscription_providers.dart';

import '../../fakes/fake_subscription_repository.dart';

/// A bounded stand-in for `pumpAndSettle()` — the paywall's star specks and
/// its "Start trial" CTA both carry a `repeat(reverse: true)` animation
/// (twinkle / pulse-glow) that never stops requesting frames, so
/// `pumpAndSettle` would hang forever. This just advances a fixed amount of
/// time, which is plenty for the fakes' async futures and any route
/// transition to resolve.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The paywall's body is a plain (non-builder) `ListView`, which still only
/// builds children within the viewport + cache extent — the CTA block and
/// everything below it sits well past that on the default test surface, so
/// tests that need it must scroll it into existence first.
Future<void> _scrollToVisible(WidgetTester tester, Finder finder) {
  return tester.dragUntilVisible(
    finder,
    find.byType(Scrollable).first,
    const Offset(0, -150),
  );
}

/// Renders [PaywallPage] as the app root — enough for content/behavior tests
/// that don't care about a real navigation stack.
Future<void> _pump(
  WidgetTester tester, {
  required FakeSubscriptionRepository repo,
  PaywallEntryPoint entryPoint = PaywallEntryPoint.profile,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [subscriptionRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: PaywallPage(entryPoint: entryPoint),
      ),
    ),
  );
  await _settle(tester);
}

/// Pushes [PaywallPage] on top of a real host route, so "close always
/// dismisses" tests have somewhere to dismiss back to.
Future<void> _pumpPushed(
  WidgetTester tester, {
  required FakeSubscriptionRepository repo,
  PaywallEntryPoint entryPoint = PaywallEntryPoint.profile,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [subscriptionRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PaywallPage(entryPoint: entryPoint),
                  ),
                ),
                child: const Text('open paywall'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open paywall'));
  await _settle(tester);
}

final _bothOfferings = Right<Failure, List<SubscriptionOfferingEntity>>([
  buildOffering(
    identifier: r'$rc_monthly',
    period: SubscriptionPeriod.monthly,
    priceString: r'$9.99',
    priceAmount: 9.99,
  ),
  buildOffering(
    identifier: r'$rc_annual',
    period: SubscriptionPeriod.annual,
    priceString: r'$44.99',
    priceAmount: 44.99,
  ),
]);

void main() {
  group('contextual sub-copy per entry point', () {
    testWidgets('profile entry shows the generic upgrade copy', (
      tester,
    ) async {
      final repo = FakeSubscriptionRepository()
        ..offeringsResult = _bothOfferings;
      await _pump(tester, repo: repo);

      expect(
        find.text(
          'Every memory deserves a place to live. Upgrade any time for '
          'unlimited room.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('memoryCap entry shows the memory-cap copy', (tester) async {
      final repo = FakeSubscriptionRepository()
        ..offeringsResult = _bothOfferings;
      await _pump(tester, repo: repo, entryPoint: PaywallEntryPoint.memoryCap);

      expect(
        find.text(
          'Your three free memories are full. Upgrade to keep every trip '
          'you take, not just three.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('photoCap entry shows the photo-cap copy', (tester) async {
      final repo = FakeSubscriptionRepository()
        ..offeringsResult = _bothOfferings;
      await _pump(tester, repo: repo, entryPoint: PaywallEntryPoint.photoCap);

      expect(
        find.text(
          'This memory is full at 40 photos. Upgrade for unlimited photos '
          'on every trip.',
        ),
        findsOneWidget,
      );
    });
  });

  testWidgets('shows both plan cards with prices and the annual SAVE pill', (
    tester,
  ) async {
    final repo = FakeSubscriptionRepository()..offeringsResult = _bothOfferings;
    await _pump(tester, repo: repo);

    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text(r'$9.99'), findsOneWidget);
    expect(find.text('Annual'), findsOneWidget);
    expect(find.text(r'$44.99'), findsOneWidget);
    expect(find.text('SAVE 63%'), findsOneWidget);
    expect(find.text(r'$3.75 A MONTH'), findsOneWidget);
  });

  testWidgets('an offerings-load failure shows a retry scaffold', (
    tester,
  ) async {
    final repo = FakeSubscriptionRepository()
      ..offeringsResult = const Left(NetworkFailure());

    await _pump(tester, repo: repo);

    expect(find.text('Please check your connection.'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Retry'), findsOneWidget);
  });

  testWidgets(
    'trial terms default to the preselected annual plan and switch to '
    'monthly on selection',
    (tester) async {
      final repo = FakeSubscriptionRepository()
        ..offeringsResult = _bothOfferings;
      await _pump(tester, repo: repo);
      await _scrollToVisible(tester, find.text('Start 7-day free trial'));

      expect(
        find.text(
          'Free for 7 days, then \$44.99/year. Cancel anytime in Settings.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Monthly'));
      await _settle(tester);

      expect(
        find.text(
          'Free for 7 days, then \$9.99/month. Cancel anytime in Settings.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'tapping Start trial purchases the pre-selected (annual) plan and shows '
    'the star toast',
    (tester) async {
      final repo = FakeSubscriptionRepository()
        ..offeringsResult = _bothOfferings
        ..purchaseResult = Right(buildProEntitlement());

      await _pump(tester, repo: repo);
      await _scrollToVisible(tester, find.text('Start 7-day free trial'));
      await tester.tap(find.text('Start 7-day free trial'));
      await _settle(tester);

      expect(repo.purchaseCallCount, 1);
      expect(repo.lastPurchasedOfferingIdentifier, r'$rc_annual');
      expect(find.text('Trial started · 7 days free'), findsOneWidget);
    },
  );

  testWidgets(
    'a cancelled purchase shows no confirmation and stays on the page',
    (tester) async {
      final repo = FakeSubscriptionRepository()
        ..offeringsResult = _bothOfferings
        ..purchaseResult = const Right(null);

      await _pump(tester, repo: repo);
      await _scrollToVisible(tester, find.text('Start 7-day free trial'));
      await tester.tap(find.text('Start 7-day free trial'));
      await _settle(tester);

      expect(find.text('Trial started · 7 days free'), findsNothing);
      expect(find.text('Start 7-day free trial'), findsOneWidget);
    },
  );

  testWidgets('a purchase failure shows an error snackbar', (tester) async {
    final repo = FakeSubscriptionRepository()
      ..offeringsResult = _bothOfferings
      ..purchaseResult = const Left(
        ServerFailure(message: 'store unavailable'),
      );

    await _pump(tester, repo: repo);
    await _scrollToVisible(tester, find.text('Start 7-day free trial'));
    await tester.tap(find.text('Start 7-day free trial'));
    await _settle(tester);

    expect(find.text('store unavailable'), findsOneWidget);
  });

  group('restore purchases outcomes', () {
    testWidgets('a successful restore with an active entitlement confirms', (
      tester,
    ) async {
      final repo = FakeSubscriptionRepository()
        ..offeringsResult = _bothOfferings
        ..restoreResult = Right(buildProEntitlement());

      await _pump(tester, repo: repo);
      await tester.tap(find.text('Restore purchases'));
      await _settle(tester);

      expect(repo.restoreCallCount, 1);
      expect(find.text('Purchases restored'), findsOneWidget);
    });

    testWidgets('a restore with nothing to restore says so, not as an error', (
      tester,
    ) async {
      final repo = FakeSubscriptionRepository()
        ..offeringsResult = _bothOfferings
        ..restoreResult = const Right(EntitlementEntity.free);

      await _pump(tester, repo: repo);
      await tester.tap(find.text('Restore purchases'));
      await _settle(tester);

      expect(find.text('Nothing to restore on this account'), findsOneWidget);
    });

    testWidgets('a restore failure shows an error snackbar', (tester) async {
      final repo = FakeSubscriptionRepository()
        ..offeringsResult = _bothOfferings
        ..restoreResult = const Left(NetworkFailure());

      await _pump(tester, repo: repo);
      await tester.tap(find.text('Restore purchases'));
      await _settle(tester);

      expect(find.text('Please check your connection.'), findsOneWidget);
    });
  });

  group('close always dismisses', () {
    testWidgets('while the offerings load has failed', (tester) async {
      final repo = FakeSubscriptionRepository()
        ..offeringsResult = const Left(NetworkFailure());
      await _pumpPushed(tester, repo: repo);

      await tester.tap(find.byIcon(Icons.close));
      await _settle(tester);

      expect(find.text('open paywall'), findsOneWidget);
    });

    testWidgets('after offerings have loaded normally', (tester) async {
      final repo = FakeSubscriptionRepository()
        ..offeringsResult = _bothOfferings;
      await _pumpPushed(tester, repo: repo);

      await tester.tap(find.byIcon(Icons.close));
      await _settle(tester);

      expect(find.text('open paywall'), findsOneWidget);
    });
  });
}
