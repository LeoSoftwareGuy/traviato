import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/subscription/domain/entities/subscription_offering_entity.dart';
import 'package:traviato/features/subscription/presentation/pages/subscription_offerings_page.dart';
import 'package:traviato/features/subscription/presentation/providers/subscription_providers.dart';

import '../../fakes/fake_subscription_repository.dart';

Future<void> _pump(
  WidgetTester tester, {
  required FakeSubscriptionRepository repo,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [subscriptionRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const SubscriptionOfferingsPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows both offerings with their prices', (tester) async {
    final repo = FakeSubscriptionRepository()
      ..offeringsResult = Right([
        buildOffering(
          identifier: r'$rc_monthly',
          period: SubscriptionPeriod.monthly,
          priceString: r'$9.99',
        ),
        buildOffering(
          identifier: r'$rc_annual',
          period: SubscriptionPeriod.annual,
          priceString: r'$44.99',
        ),
      ]);

    await _pump(tester, repo: repo);

    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text(r'$9.99'), findsOneWidget);
    expect(find.text('Annual'), findsOneWidget);
    expect(find.text(r'$44.99'), findsOneWidget);
  });

  testWidgets('a retry scaffold shows on a failed offerings load', (
    tester,
  ) async {
    final repo = FakeSubscriptionRepository()
      ..offeringsResult = const Left(NetworkFailure());

    await _pump(tester, repo: repo);

    expect(find.text('Please check your connection.'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Retry'), findsOneWidget);
  });

  testWidgets(
    'tapping Start trial purchases the pre-selected (annual) plan',
    (tester) async {
      final proEntitlement = buildProEntitlement();
      final repo = FakeSubscriptionRepository()
        ..offeringsResult = Right([
          buildOffering(
            identifier: r'$rc_monthly',
            period: SubscriptionPeriod.monthly,
          ),
          buildOffering(
            identifier: r'$rc_annual',
            period: SubscriptionPeriod.annual,
          ),
        ])
        ..purchaseResult = Right(proEntitlement);

      await _pump(tester, repo: repo);
      await tester.tap(find.text('Start 7-day free trial'));
      await tester.pumpAndSettle();

      expect(repo.purchaseCallCount, 1);
      expect(repo.lastPurchasedOfferingIdentifier, r'$rc_annual');
      expect(find.text('Trial started · 7 days free'), findsOneWidget);
    },
  );

  testWidgets('selecting the monthly plan purchases that identifier', (
    tester,
  ) async {
    final repo = FakeSubscriptionRepository()
      ..offeringsResult = Right([
        buildOffering(
          identifier: r'$rc_monthly',
          period: SubscriptionPeriod.monthly,
        ),
        buildOffering(
          identifier: r'$rc_annual',
          period: SubscriptionPeriod.annual,
        ),
      ])
      ..purchaseResult = Right(buildProEntitlement());

    await _pump(tester, repo: repo);
    await tester.tap(find.text('Monthly'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start 7-day free trial'));
    await tester.pumpAndSettle();

    expect(repo.lastPurchasedOfferingIdentifier, r'$rc_monthly');
  });

  testWidgets(
    'a cancelled purchase shows no confirmation and stays on the page',
    (tester) async {
      final repo = FakeSubscriptionRepository()
        ..offeringsResult = Right([buildOffering()])
        ..purchaseResult = const Right(null);

      await _pump(tester, repo: repo);
      await tester.tap(find.text('Start 7-day free trial'));
      await tester.pumpAndSettle();

      expect(find.text('Trial started · 7 days free'), findsNothing);
      expect(find.text('Traviato Pro'), findsOneWidget);
    },
  );

  testWidgets('a purchase failure shows an error snackbar', (tester) async {
    final repo = FakeSubscriptionRepository()
      ..offeringsResult = Right([buildOffering()])
      ..purchaseResult = const Left(
        ServerFailure(message: 'store unavailable'),
      );

    await _pump(tester, repo: repo);
    await tester.tap(find.text('Start 7-day free trial'));
    await tester.pumpAndSettle();

    expect(find.text('store unavailable'), findsOneWidget);
  });

  testWidgets('tapping Restore purchases restores and confirms', (
    tester,
  ) async {
    final repo = FakeSubscriptionRepository()
      ..offeringsResult = Right([buildOffering()])
      ..restoreResult = Right(buildProEntitlement());

    await _pump(tester, repo: repo);
    await tester.tap(find.text('Restore purchases'));
    await tester.pumpAndSettle();

    expect(repo.restoreCallCount, 1);
    expect(find.text('Purchases restored'), findsOneWidget);
  });
}
