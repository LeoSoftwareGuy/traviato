import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:traviato/core/config/router/route_constants.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/quest/presentation/pages/plan_page.dart';
import 'package:traviato/features/quest/presentation/providers/quest_providers.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';

import '../../../trip/fakes/fake_trip_repository.dart';
import '../../fakes/fake_quest_repository.dart';

DateTime get _today {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

Future<void> _pump(
  WidgetTester tester, {
  required FakeTripRepository tripRepo,
  required FakeQuestRepository questRepo,
}) async {
  final router = GoRouter(
    initialLocation: '/plan',
    routes: [
      GoRoute(
        path: '/plan',
        builder: (context, state) => const PlanPage(tripId: 't1'),
      ),
      GoRoute(
        path: '/back',
        builder: (context, state) => const Scaffold(body: Text('back')),
      ),
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
        tripRepositoryProvider.overrideWithValue(tripRepo),
        questRepositoryProvider.overrideWithValue(questRepo),
      ],
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    ),
  );
}

void main() {
  testWidgets('renders the timeline for the current day', (tester) async {
    final tripRepo = FakeTripRepository()
      ..tripCardResult = Right(
        buildTripCard(
          id: 't1',
          startDate: _today.subtract(const Duration(days: 30)),
          endDate: _today.add(const Duration(days: 30)),
        ),
      );
    final questRepo = FakeQuestRepository()
      ..questsResult = Right([
        buildQuestEntity(
          id: 'q1',
          dayDate: _today,
          title: 'Pack the car',
          placeText: 'Cooler, blankets, hiking boots',
          time: const Duration(hours: 8),
        ),
      ]);
    await _pump(tester, tripRepo: tripRepo, questRepo: questRepo);
    await tester.pumpAndSettle();

    expect(find.text('Pack the car'), findsOneWidget);
    expect(find.text('Cooler, blankets, hiking boots'), findsOneWidget);
    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('1 quests planned'), findsOneWidget);
  });

  testWidgets('shows the empty-day state with no quests', (tester) async {
    final tripRepo = FakeTripRepository()
      ..tripCardResult = Right(
        buildTripCard(
          id: 't1',
          startDate: _today.subtract(const Duration(days: 1)),
          endDate: _today.add(const Duration(days: 1)),
        ),
      );
    final questRepo = FakeQuestRepository()..questsResult = const Right([]);
    await _pump(tester, tripRepo: tripRepo, questRepo: questRepo);
    await tester.pumpAndSettle();

    expect(find.text('No quests added yet'), findsOneWidget);
  });

  testWidgets('shows the blocking message for a memory with no dates', (
    tester,
  ) async {
    final tripRepo = FakeTripRepository()
      ..tripCardResult = Right(buildTripCard(id: 't1'));
    final questRepo = FakeQuestRepository();
    await _pump(tester, tripRepo: tripRepo, questRepo: questRepo);
    await tester.pumpAndSettle();

    expect(
      find.text('Add dates to this memory to start planning your days.'),
      findsOneWidget,
    );
  });

  testWidgets('add-quest sheet validates the required name', (tester) async {
    final tripRepo = FakeTripRepository()
      ..tripCardResult = Right(
        buildTripCard(
          id: 't1',
          startDate: _today.subtract(const Duration(days: 1)),
          endDate: _today.add(const Duration(days: 1)),
        ),
      );
    final questRepo = FakeQuestRepository()..questsResult = const Right([]);
    await _pump(tester, tripRepo: tripRepo, questRepo: questRepo);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Add plan'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Give this plan a name.'), findsOneWidget);
    expect(questRepo.addQuestCallCount, 0);
  });

  testWidgets('tapping the check circle toggles completion', (tester) async {
    final tripRepo = FakeTripRepository()
      ..tripCardResult = Right(
        buildTripCard(
          id: 't1',
          startDate: _today.subtract(const Duration(days: 1)),
          endDate: _today.add(const Duration(days: 1)),
        ),
      );
    final quest = buildQuestEntity(
      id: 'q1',
      dayDate: _today,
      title: 'Pack the car',
    );
    final questRepo = FakeQuestRepository()..questsResult = Right([quest]);
    await _pump(tester, tripRepo: tripRepo, questRepo: questRepo);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('quest-check-q1')));
    await tester.pumpAndSettle();

    expect(questRepo.toggleCallCount, 1);
  });

  testWidgets('the app-bar checklist action navigates to the checklist '
      'route', (tester) async {
    final tripRepo = FakeTripRepository()
      ..tripCardResult = Right(
        buildTripCard(
          id: 't1',
          startDate: _today.subtract(const Duration(days: 1)),
          endDate: _today.add(const Duration(days: 1)),
        ),
      );
    final questRepo = FakeQuestRepository()..questsResult = const Right([]);
    await _pump(tester, tripRepo: tripRepo, questRepo: questRepo);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('plan-checklist-action')));
    await tester.pumpAndSettle();

    expect(find.text('checklist page'), findsOneWidget);
  });
}
