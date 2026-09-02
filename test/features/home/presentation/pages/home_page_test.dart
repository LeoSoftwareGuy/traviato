import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:traviato/core/config/router/route_constants.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/auth/domain/entities/user_entity.dart';
import 'package:traviato/features/auth/presentation/providers/auth_providers.dart';
import 'package:traviato/features/checklist/presentation/providers/checklist_providers.dart';
import 'package:traviato/features/expense/presentation/providers/expense_providers.dart';
import 'package:traviato/features/home/presentation/pages/home_page.dart';
import 'package:traviato/features/home/presentation/providers/profile_stats_provider.dart';
import 'package:traviato/features/home/presentation/widgets/upcoming_hero_card.dart';
import 'package:traviato/features/quest/presentation/providers/quest_providers.dart';
import 'package:traviato/features/trip/domain/entities/trip_card_entity.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';

import '../../../auth/fakes/fake_auth_repository.dart';
import '../../../checklist/fakes/fake_checklist_repository.dart';
import '../../../expense/fakes/fake_expense_repository.dart';
import '../../../quest/fakes/fake_quest_repository.dart';
import '../../../trip/fakes/fake_trip_repository.dart';
import '../../fakes/fake_profile_stats_repository.dart';

Future<void> _pump(
  WidgetTester tester, {
  required FakeTripRepository tripRepo,
  FakeAuthRepository? authRepo,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          authRepo ?? FakeAuthRepository(),
        ),
        tripRepositoryProvider.overrideWithValue(tripRepo),
        questRepositoryProvider.overrideWithValue(FakeQuestRepository()),
        checklistRepositoryProvider.overrideWithValue(
          FakeChecklistRepository(),
        ),
        profileStatsRepositoryProvider.overrideWithValue(
          FakeProfileStatsRepository(),
        ),
      ],
      child: MaterialApp(theme: AppTheme.dark, home: const HomePage()),
    ),
  );
}

void main() {
  testWidgets('shows a spinner while loading', (tester) async {
    final tripRepo = FakeTripRepository()
      ..tripsResult = const Right([])
      ..delay = const Duration(milliseconds: 50);
    await _pump(tester, tripRepo: tripRepo);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('shows the retry scaffold on failure', (tester) async {
    final tripRepo = FakeTripRepository()
      ..tripsResult = const Left(NetworkFailure());
    await _pump(tester, tripRepo: tripRepo);
    await tester.pumpAndSettle();

    expect(find.text('Please check your connection.'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Retry'), findsOneWidget);
  });

  testWidgets('shows the empty prompt when there are no trips', (
    tester,
  ) async {
    final tripRepo = FakeTripRepository()..tripsResult = const Right([]);
    await _pump(tester, tripRepo: tripRepo);
    await tester.pumpAndSettle();

    expect(find.text('No memories yet'), findsOneWidget);
    expect(find.text('HAPPENING NOW'), findsNothing);
  });

  testWidgets('shows the hero card only when a trip is current/upcoming', (
    tester,
  ) async {
    final trip = buildTripCard(
      id: 't1',
      name: 'Mountain cabin retreat',
      startDate: DateTime.now().add(const Duration(days: 5)),
      status: TripStatus.upcoming,
    );
    final tripRepo = FakeTripRepository()..tripsResult = Right([trip]);
    await _pump(tester, tripRepo: tripRepo);
    await tester.pumpAndSettle();

    expect(find.text('Mountain cabin retreat'), findsOneWidget);
    expect(find.byType(UpcomingHeroCard), findsOneWidget);
  });

  testWidgets('renders the greeting from the authenticated user', (
    tester,
  ) async {
    final authRepo = FakeAuthRepository();
    final tripRepo = FakeTripRepository()..tripsResult = const Right([]);
    await _pump(tester, tripRepo: tripRepo, authRepo: authRepo);
    // AuthController only subscribes to the stream once the widget tree
    // (and thus authControllerProvider) has built, so emit after pumping.
    authRepo.emit(
      const UserEntity(id: 'u1', email: 'ada@example.com', username: 'ada'),
    );
    await tester.pumpAndSettle();

    final greeting = tester.widget<Text>(
      find.byKey(const Key('home-greeting')),
    );
    expect(greeting.textSpan?.toPlainText(), 'Hello, ada');
  });

  testWidgets('the hero-card Checklist row navigates to the checklist '
      'route', (tester) async {
    final trip = buildTripCard(
      id: 't1',
      name: 'Mountain cabin retreat',
      startDate: DateTime.now().add(const Duration(days: 5)),
      status: TripStatus.upcoming,
    );
    final tripRepo = FakeTripRepository()..tripsResult = Right([trip]);
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomePage()),
        GoRoute(
          path: '/memory/:tripId/checklist',
          name: RouteNames.tripChecklist,
          builder: (context, state) =>
              const Scaffold(body: Text('checklist page')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          tripRepositoryProvider.overrideWithValue(tripRepo),
          questRepositoryProvider.overrideWithValue(FakeQuestRepository()),
          checklistRepositoryProvider.overrideWithValue(
            FakeChecklistRepository(),
          ),
        ],
        child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Checklist'));
    await tester.pumpAndSettle();

    expect(find.text('checklist page'), findsOneWidget);
  });

  testWidgets(
    'the hero-card Expenses button opens the sheet pre-selecting that trip',
    (tester) async {
      final trip = buildTripCard(
        id: 't1',
        name: 'Mountain cabin retreat',
        startDate: DateTime.now().add(const Duration(days: 5)),
        status: TripStatus.upcoming,
      );
      final tripRepo = FakeTripRepository()..tripsResult = Right([trip]);
      final expenseRepo = FakeExpenseRepository()
        ..summariesResult = Right([
          buildExpenseSummaryEntity(
            tripId: 't1',
            tripName: 'Mountain cabin retreat',
          ),
        ]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            tripRepositoryProvider.overrideWithValue(tripRepo),
            questRepositoryProvider.overrideWithValue(FakeQuestRepository()),
            checklistRepositoryProvider.overrideWithValue(
              FakeChecklistRepository(),
            ),
            expenseRepositoryProvider.overrideWithValue(expenseRepo),
          ],
          child: MaterialApp(theme: AppTheme.dark, home: const HomePage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Expenses'));
      await tester.pumpAndSettle();

      expect(expenseRepo.getSummariesCallCount, 1);
      expect(find.text('Description'), findsOneWidget); // sheet is open
      // The hero card's trip is pre-selected in the memory dropdown.
      expect(find.text('Mountain cabin retreat'), findsWidgets);
    },
  );

  testWidgets('a Coming-up card navigates to Plan for that memory', (
    tester,
  ) async {
    final hero = buildTripCard(
      id: 't1',
      name: 'Mountain cabin retreat',
      startDate: DateTime.now().add(const Duration(days: 1)),
      status: TripStatus.upcoming,
    );
    final comingUp = buildTripCard(
      id: 't2',
      name: 'Lisbon winter',
      startDate: DateTime.now().add(const Duration(days: 20)),
      status: TripStatus.upcoming,
    );
    final tripRepo = FakeTripRepository()
      ..tripsResult = Right([hero, comingUp]);
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomePage()),
        GoRoute(
          path: '/memory/:tripId/plan',
          name: RouteNames.tripPlan,
          builder: (context, state) => Scaffold(
            body: Text('plan page ${state.pathParameters['tripId']}'),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          tripRepositoryProvider.overrideWithValue(tripRepo),
          questRepositoryProvider.overrideWithValue(FakeQuestRepository()),
          checklistRepositoryProvider.overrideWithValue(
            FakeChecklistRepository(),
          ),
        ],
        child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Lisbon winter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lisbon winter'));
    await tester.pumpAndSettle();

    expect(find.text('plan page t2'), findsOneWidget);
  });

  testWidgets('a Kept-forever card navigates to Journal, not Wrap-up (#101)', (
    tester,
  ) async {
    final finished = buildTripCard(
      id: 't1',
      name: 'Atlas high road',
      startDate: DateTime(2025, 1, 1),
      endDate: DateTime(2025, 1, 9),
      status: TripStatus.finished,
    );
    final tripRepo = FakeTripRepository()..tripsResult = Right([finished]);
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomePage()),
        GoRoute(
          path: '/memory/:tripId/journal',
          name: RouteNames.tripJournal,
          builder: (context, state) => const Scaffold(body: Text('Journal')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          tripRepositoryProvider.overrideWithValue(tripRepo),
          questRepositoryProvider.overrideWithValue(FakeQuestRepository()),
          checklistRepositoryProvider.overrideWithValue(
            FakeChecklistRepository(),
          ),
        ],
        child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Atlas high road'));
    await tester.pumpAndSettle();

    expect(find.text('Journal'), findsOneWidget);
  });

  testWidgets(
    'a kept-forever card shows the "Kept forever" badge, not "Recap" (#95)',
    (tester) async {
      final finished = buildTripCard(
        id: 't1',
        name: 'Atlas high road',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 9),
        status: TripStatus.finished,
        wrapUpPublishedAt: DateTime(2025, 1, 10),
      );
      final tripRepo = FakeTripRepository()..tripsResult = Right([finished]);
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomePage(),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            tripRepositoryProvider.overrideWithValue(tripRepo),
            questRepositoryProvider.overrideWithValue(FakeQuestRepository()),
            checklistRepositoryProvider.overrideWithValue(
              FakeChecklistRepository(),
            ),
          ],
          child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('✦ Kept forever'), findsOneWidget);
      expect(find.text('▸ Recap'), findsNothing);
    },
  );

  testWidgets('the stars badge navigates to the Bonus tasks placeholder', (
    tester,
  ) async {
    final tripRepo = FakeTripRepository()..tripsResult = const Right([]);
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomePage()),
        GoRoute(
          path: '/bonus-tasks',
          name: RouteNames.bonusTasks,
          builder: (context, state) =>
              const Scaffold(body: Text('Bonus tasks')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          tripRepositoryProvider.overrideWithValue(tripRepo),
          questRepositoryProvider.overrideWithValue(FakeQuestRepository()),
          checklistRepositoryProvider.overrideWithValue(
            FakeChecklistRepository(),
          ),
        ],
        child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home-stars-badge')));
    await tester.pumpAndSettle();

    expect(find.text('Bonus tasks'), findsOneWidget);
  });
}
