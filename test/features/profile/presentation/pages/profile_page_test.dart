import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:traviato/core/config/router/route_constants.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/core/theme/app_colors.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/auth/presentation/providers/auth_providers.dart';
import 'package:traviato/features/home/domain/entities/profile_stats_entity.dart';
import 'package:traviato/features/home/presentation/providers/profile_stats_provider.dart';
import 'package:traviato/features/profile/domain/entities/achievement_entity.dart';
import 'package:traviato/features/profile/presentation/pages/profile_page.dart';
import 'package:traviato/features/profile/presentation/providers/profile_providers.dart';
import 'package:traviato/features/subscription/domain/entities/entitlement_entity.dart';
import 'package:traviato/features/subscription/domain/entities/subscription_offering_entity.dart';
import 'package:traviato/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../../auth/fakes/fake_auth_repository.dart';
import '../../../home/fakes/fake_profile_stats_repository.dart';
import '../../../subscription/fakes/fake_subscription_repository.dart';
import '../../../trip/fakes/fake_trip_repository.dart';
import '../../fakes/fake_profile_repository.dart';
import '../../fakes/fake_url_launcher_platform.dart';

const _stats = ProfileStatsEntity(
  memories: 4,
  places: 6,
  countries: 3,
  days: 12,
  stars: 40,
  photos: 8,
  notes: 5,
);

Future<void> _pump(
  WidgetTester tester, {
  required FakeProfileRepository profileRepo,
  FakeAuthRepository? authRepo,
  FakeProfileStatsRepository? statsRepo,
  FakeSubscriptionRepository? subscriptionRepo,
  FakeTripRepository? tripRepo,
}) async {
  final resolvedAuthRepo = authRepo ?? FakeAuthRepository();
  addTearDown(resolvedAuthRepo.dispose);
  // The subscription section adds enough content that the page's ListView
  // no longer fits the default 800x600 test surface — tall enough that
  // everything (Achievements grid, Log out, Restore purchases) builds and
  // is hittable without a scroll-to-visible step in every test.
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        profileRepositoryProvider.overrideWithValue(profileRepo),
        authRepositoryProvider.overrideWithValue(resolvedAuthRepo),
        profileStatsRepositoryProvider.overrideWithValue(
          statsRepo ??
              (FakeProfileStatsRepository()..statsResult = const Right(_stats)),
        ),
        subscriptionRepositoryProvider.overrideWithValue(
          subscriptionRepo ?? FakeSubscriptionRepository(),
        ),
        tripRepositoryProvider.overrideWithValue(
          tripRepo ?? FakeTripRepository(),
        ),
      ],
      child: MaterialApp(theme: AppTheme.dark, home: const ProfilePage()),
    ),
  );
  await tester.pumpAndSettle();
}

/// Only the "Upgrade to Pro" navigation test needs a real router — every
/// other test above uses the plain `MaterialApp(home:)` harness.
Future<void> _pumpWithRouter(
  WidgetTester tester, {
  required FakeProfileRepository profileRepo,
}) async {
  final authRepo = FakeAuthRepository();
  addTearDown(authRepo.dispose);
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(
    initialLocation: RoutePaths.profile,
    routes: [
      GoRoute(
        path: RoutePaths.profile,
        name: RouteNames.profile,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: RoutePaths.subscriptionOfferings,
        name: RouteNames.subscriptionOfferings,
        builder: (context, state) =>
            const Scaffold(body: Text('Offerings screen')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        profileRepositoryProvider.overrideWithValue(profileRepo),
        authRepositoryProvider.overrideWithValue(authRepo),
        profileStatsRepositoryProvider.overrideWithValue(
          FakeProfileStatsRepository()..statsResult = const Right(_stats),
        ),
        subscriptionRepositoryProvider.overrideWithValue(
          FakeSubscriptionRepository(),
        ),
        tripRepositoryProvider.overrideWithValue(FakeTripRepository()),
      ],
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'renders an earned badge filled and a locked badge with progress',
    (
      tester,
    ) async {
      final profileRepo = FakeProfileRepository()
        ..achievementsResult = Right([
          buildAchievement(
            id: 1,
            code: 'first_adventure',
            title: 'First Adventure',
            earnedAt: DateTime(2026, 1, 1),
          ),
          buildAchievement(
            id: 2,
            code: 'century',
            title: 'Century',
            metric: AchievementMetric.daysLogged,
            target: 100,
            currentValue: 12,
          ),
        ]);

      await _pump(tester, profileRepo: profileRepo);

      expect(find.text('First Adventure'), findsOneWidget);
      expect(find.text('Century'), findsOneWidget);
      expect(find.text('12 OF 100 DAYS'), findsOneWidget);
      expect(find.text('1/2 earned'), findsOneWidget);
    },
  );

  testWidgets('shows the stats row from profile_stats_view', (tester) async {
    await _pump(tester, profileRepo: FakeProfileRepository());

    expect(find.text('4'), findsOneWidget); // memories
    expect(find.text('3'), findsOneWidget); // countries
    expect(find.text('12'), findsOneWidget); // days
    expect(find.text('40'), findsOneWidget); // stars
  });

  testWidgets('tapping Edit opens the edit sheet with the current username', (
    tester,
  ) async {
    final profileRepo = FakeProfileRepository()
      ..profileResult = Right(buildProfile(username: 'ada'));
    await _pump(tester, profileRepo: profileRepo);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Edit your profile'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'ada'), findsOneWidget);
  });

  testWidgets('saving the username in the edit sheet calls updateProfile', (
    tester,
  ) async {
    final profileRepo = FakeProfileRepository()
      ..profileResult = Right(buildProfile(username: 'ada'));
    await _pump(tester, profileRepo: profileRepo);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'ada'), 'nadia');
    await tester.tap(find.widgetWithText(TextButton, 'Save').first);
    await tester.pumpAndSettle();

    expect(profileRepo.lastUpdateArgs?['username'], 'nadia');
  });

  testWidgets('tapping Log out calls repository.logout()', (tester) async {
    final authRepo = FakeAuthRepository();
    await _pump(
      tester,
      profileRepo: FakeProfileRepository(),
      authRepo: authRepo,
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Log out'));
    await tester.pumpAndSettle();

    expect(authRepo.logoutCalled, isTrue);
  });

  testWidgets('shows a spinner while the logout mutation is pending', (
    tester,
  ) async {
    final authRepo = FakeAuthRepository()
      ..delay = const Duration(milliseconds: 200);
    await _pump(
      tester,
      profileRepo: FakeProfileRepository(),
      authRepo: authRepo,
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Log out'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Log out'), findsNothing);

    await tester.pumpAndSettle();
  });

  testWidgets('shows an error snackbar when logout fails', (tester) async {
    final authRepo = FakeAuthRepository()
      ..logoutResult = const Left(UnknownFailure(message: 'boom'));
    await _pump(
      tester,
      profileRepo: FakeProfileRepository(),
      authRepo: authRepo,
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Log out'));
    await tester.pumpAndSettle();

    expect(find.text('boom'), findsOneWidget);
  });

  testWidgets('tapping Upgrade to Pro navigates to the offerings screen', (
    tester,
  ) async {
    await _pumpWithRouter(tester, profileRepo: FakeProfileRepository());

    await tester.tap(find.text('Upgrade to Pro'));
    await tester.pumpAndSettle();

    expect(find.text('Offerings screen'), findsOneWidget);
  });

  testWidgets(
    'tapping Restore purchases with an active entitlement confirms',
    (tester) async {
      final subscriptionRepo = FakeSubscriptionRepository()
        ..restoreResult = Right(buildProEntitlement());
      await _pump(
        tester,
        profileRepo: FakeProfileRepository(),
        subscriptionRepo: subscriptionRepo,
      );

      await tester.tap(find.text('Restore purchases'));
      // Not pumpAndSettle: the star toast (#141's pattern) is a
      // time-bound ~1.65s animation, not a persistent SnackBar — settling
      // fully would run right past its auto-dismiss before this checks it.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(subscriptionRepo.restoreCallCount, 1);
      expect(find.text('Purchases restored'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping Restore purchases with nothing to restore says so, not as '
    'an error',
    (tester) async {
      final subscriptionRepo = FakeSubscriptionRepository()
        ..restoreResult = const Right(EntitlementEntity.free);
      await _pump(
        tester,
        profileRepo: FakeProfileRepository(),
        subscriptionRepo: subscriptionRepo,
      );

      await tester.tap(find.text('Restore purchases'));
      await tester.pumpAndSettle();

      expect(subscriptionRepo.restoreCallCount, 1);
      expect(find.text('Nothing to restore on this account'), findsOneWidget);
    },
  );

  testWidgets(
    'shows an error snackbar when restoring purchases fails',
    (tester) async {
      final subscriptionRepo = FakeSubscriptionRepository()
        ..restoreResult = const Left(UnknownFailure(message: 'restore boom'));
      await _pump(
        tester,
        profileRepo: FakeProfileRepository(),
        subscriptionRepo: subscriptionRepo,
      );

      await tester.tap(find.text('Restore purchases'));
      await tester.pumpAndSettle();

      expect(find.text('restore boom'), findsOneWidget);
    },
  );

  group('Subscription section (#142)', () {
    ProfileStatsEntity statsWithMemories(int memories) => ProfileStatsEntity(
      memories: memories,
      places: _stats.places,
      countries: _stats.countries,
      days: _stats.days,
      stars: _stats.stars,
      photos: _stats.photos,
      notes: _stats.notes,
    );

    Color barColor(WidgetTester tester, Key meterKey) {
      final indicator = tester.widget<LinearProgressIndicator>(
        find.descendant(
          of: find.byKey(meterKey),
          matching: find.byType(LinearProgressIndicator),
        ),
      );
      return (indicator.valueColor! as AlwaysStoppedAnimation<Color?>).value!;
    }

    testWidgets('Free, 2 of 3 memories: primary bar, Upgrade visible', (
      tester,
    ) async {
      await _pump(
        tester,
        profileRepo: FakeProfileRepository(),
        statsRepo: FakeProfileStatsRepository()
          ..statsResult = Right(statsWithMemories(2)),
      );

      expect(find.text('2 OF 3'), findsOneWidget);
      expect(find.text('Upgrade to Pro'), findsOneWidget);
      expect(barColor(tester, const Key('memories-meter')), AppColors.primary);
    });

    testWidgets('Free, 3 of 3 memories: coral bar, still allowed to view', (
      tester,
    ) async {
      await _pump(
        tester,
        profileRepo: FakeProfileRepository(),
        statsRepo: FakeProfileStatsRepository()
          ..statsResult = Right(statsWithMemories(3)),
      );

      expect(find.text('3 OF 3'), findsOneWidget);
      expect(
        barColor(tester, const Key('memories-meter')),
        AppColors.accentCoral,
      );
    });

    testWidgets(
      "photos meter reflects whichever memory has the most (Profile's own "
      'no-current-memory rule)',
      (tester) async {
        final tripRepo = FakeTripRepository()
          ..tripsResult = Right([
            buildTripCard(id: 't1', photoCount: 12),
            buildTripCard(id: 't2', photoCount: 40),
          ]);
        await _pump(
          tester,
          profileRepo: FakeProfileRepository(),
          tripRepo: tripRepo,
        );

        expect(find.text('40 OF 40'), findsOneWidget);
        expect(
          barColor(tester, const Key('photos-meter')),
          AppColors.accentCoral,
        );
      },
    );

    testWidgets(
      'Pro: both bars full/primary, Manage subscription, no Upgrade CTA '
      'anywhere',
      (tester) async {
        final subscriptionRepo = FakeSubscriptionRepository()
          ..entitlementResult = Right(buildProEntitlement())
          ..activeSubscriptionResult = Right(
            buildActiveSubscription(period: SubscriptionPeriod.annual),
          )
          ..offeringsResult = Right([
            buildOffering(
              period: SubscriptionPeriod.annual,
              priceString: r'$44.99',
            ),
          ]);
        await _pump(
          tester,
          profileRepo: FakeProfileRepository(),
          subscriptionRepo: subscriptionRepo,
        );

        expect(find.text('UNLIMITED'), findsOneWidget);
        expect(find.textContaining('NO LIMIT'), findsOneWidget);
        expect(find.text('Manage subscription'), findsOneWidget);
        expect(find.text('Upgrade to Pro'), findsNothing);
        expect(
          barColor(tester, const Key('memories-meter')),
          AppColors.primary,
        );
        expect(barColor(tester, const Key('photos-meter')), AppColors.primary);
      },
    );

    testWidgets(
      "Pro's renewal line shows the real matching-period price, not a "
      'hardcoded one',
      (tester) async {
        final subscriptionRepo = FakeSubscriptionRepository()
          ..entitlementResult = Right(
            buildProEntitlement(expiresAt: DateTime(2027, 3, 15)),
          )
          ..activeSubscriptionResult = Right(
            buildActiveSubscription(period: SubscriptionPeriod.monthly),
          )
          ..offeringsResult = Right([
            buildOffering(
              period: SubscriptionPeriod.monthly,
              priceString: r'$9.99',
            ),
            buildOffering(
              period: SubscriptionPeriod.annual,
              priceString: r'$44.99',
            ),
          ]);
        await _pump(
          tester,
          profileRepo: FakeProfileRepository(),
          subscriptionRepo: subscriptionRepo,
        );

        expect(find.textContaining(r'$9.99/month'), findsOneWidget);
        expect(find.textContaining(r'$44.99'), findsNothing);
      },
    );

    testWidgets('tapping Manage subscription opens the RevenueCat URL', (
      tester,
    ) async {
      final fakePlatform = FakeUrlLauncherPlatform();
      final previousPlatform = UrlLauncherPlatform.instance;
      UrlLauncherPlatform.instance = fakePlatform;
      addTearDown(() => UrlLauncherPlatform.instance = previousPlatform);

      final subscriptionRepo = FakeSubscriptionRepository()
        ..entitlementResult = Right(buildProEntitlement())
        ..activeSubscriptionResult = Right(
          buildActiveSubscription(
            managementUrl: 'https://apps.apple.com/account/subscriptions',
          ),
        );
      await _pump(
        tester,
        profileRepo: FakeProfileRepository(),
        subscriptionRepo: subscriptionRepo,
      );

      await tester.tap(find.text('Manage subscription'));
      await tester.pumpAndSettle();

      expect(fakePlatform.launchCallCount, 1);
      expect(
        fakePlatform.lastLaunchedUrl,
        'https://apps.apple.com/account/subscriptions',
      );
    });

    testWidgets(
      'Manage subscription with no management URL shows a friendly message',
      (tester) async {
        final subscriptionRepo = FakeSubscriptionRepository()
          ..entitlementResult = Right(buildProEntitlement())
          ..activeSubscriptionResult = Right(
            buildActiveSubscription(managementUrl: null),
          );
        await _pump(
          tester,
          profileRepo: FakeProfileRepository(),
          subscriptionRepo: subscriptionRepo,
        );

        await tester.tap(find.text('Manage subscription'));
        await tester.pumpAndSettle();

        expect(find.text('No subscription found to manage.'), findsOneWidget);
      },
    );
  });
}
