import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/auth/presentation/providers/auth_providers.dart';
import 'package:traviato/features/home/domain/entities/profile_stats_entity.dart';
import 'package:traviato/features/home/presentation/providers/profile_stats_provider.dart';
import 'package:traviato/features/profile/domain/entities/achievement_entity.dart';
import 'package:traviato/features/profile/presentation/pages/profile_page.dart';
import 'package:traviato/features/profile/presentation/providers/profile_providers.dart';

import '../../../auth/fakes/fake_auth_repository.dart';
import '../../../home/fakes/fake_profile_stats_repository.dart';
import '../../fakes/fake_profile_repository.dart';

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
}) async {
  final resolvedAuthRepo = authRepo ?? FakeAuthRepository();
  addTearDown(resolvedAuthRepo.dispose);
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
      ],
      child: MaterialApp(theme: AppTheme.dark, home: const ProfilePage()),
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
}
