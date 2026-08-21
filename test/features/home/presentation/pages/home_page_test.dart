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
import 'package:traviato/features/expense/presentation/providers/expense_providers.dart';
import 'package:traviato/features/home/presentation/pages/home_page.dart';
import 'package:traviato/features/trip/domain/entities/trip_card_entity.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';

import '../../../auth/fakes/fake_auth_repository.dart';
import '../../../expense/fakes/fake_expense_repository.dart';
import '../../../trip/fakes/fake_trip_repository.dart';

Future<void> _pump(
  WidgetTester tester, {
  required FakeTripRepository tripRepo,
  FakeAuthRepository? authRepo,
}) async {
  final auth = authRepo ?? FakeAuthRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        tripRepositoryProvider.overrideWithValue(tripRepo),
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
    expect(find.text('Coming up'), findsNothing);
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
    expect(find.text('Up next'), findsOneWidget);
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

  testWidgets('the hero-card Checklist shortcut navigates to the checklist '
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
    'the hero-card Add expense button opens the sheet pre-selecting that '
    'trip',
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
            expenseRepositoryProvider.overrideWithValue(expenseRepo),
          ],
          child: MaterialApp(theme: AppTheme.dark, home: const HomePage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add expense'));
      await tester.pumpAndSettle();

      expect(expenseRepo.getSummariesCallCount, 1);
      expect(find.text('What was it?'), findsOneWidget); // sheet is open
      // The hero card's trip is pre-selected in the memory dropdown.
      expect(find.text('Mountain cabin retreat'), findsWidgets);
    },
  );
}
