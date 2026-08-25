import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:traviato/core/config/router/route_constants.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/journal/presentation/providers/day_note_providers.dart';
import 'package:traviato/features/photo/presentation/providers/photo_providers.dart';
import 'package:traviato/features/quest/presentation/pages/plan_page.dart';
import 'package:traviato/features/quest/presentation/providers/quest_providers.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';

import '../../../journal/fakes/fake_day_note_repository.dart';
import '../../../photo/fakes/fake_photo_repository.dart';
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
  FakePhotoRepository? photoRepo,
  FakeDayNoteRepository? noteRepo,
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
      GoRoute(
        path: '/home',
        name: RouteNames.home,
        builder: (context, state) => const Scaffold(body: Text('home page')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tripRepositoryProvider.overrideWithValue(tripRepo),
        questRepositoryProvider.overrideWithValue(questRepo),
        photoRepositoryProvider.overrideWithValue(
          photoRepo ?? FakePhotoRepository(),
        ),
        dayNoteRepositoryProvider.overrideWithValue(
          noteRepo ?? FakeDayNoteRepository(),
        ),
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
    expect(find.text('1 quests planned · 61 days total'), findsOneWidget);
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

    expect(find.text('+ Add a quest to Day 2'), findsOneWidget);
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

    await tester.tap(find.text('+ Add a quest to Day 2'));
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

  testWidgets('checking a quest shows the star toast', (tester) async {
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
    await tester.pump();

    expect(find.text('✦ +1 star · quest done'), findsOneWidget);
  });

  testWidgets('unchecking a quest does not show the star toast', (
    tester,
  ) async {
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
      completedAt: DateTime(2026, 1, 2),
    );
    final questRepo = FakeQuestRepository()..questsResult = Right([quest]);
    await _pump(tester, tripRepo: tripRepo, questRepo: questRepo);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('quest-check-q1')));
    await tester.pump();

    expect(find.text('✦ +1 star · quest done'), findsNothing);
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

  testWidgets('renders the cover banner with dates, place, and the day pill', (
    tester,
  ) async {
    final tripRepo = FakeTripRepository()
      ..tripCardResult = Right(
        buildTripCard(
          id: 't1',
          destination: 'Cortina d\'Ampezzo',
          startDate: _today,
          endDate: _today.add(const Duration(days: 4)),
        ),
      );
    final questRepo = FakeQuestRepository()..questsResult = const Right([]);
    await _pump(tester, tripRepo: tripRepo, questRepo: questRepo);
    await tester.pumpAndSettle();

    expect(find.text('Cortina d\'Ampezzo'), findsOneWidget);
    expect(find.text('Day 1 of 5'), findsOneWidget);
  });

  testWidgets('tapping a pager segment jumps to that day', (tester) async {
    final tripRepo = FakeTripRepository()
      ..tripCardResult = Right(
        buildTripCard(
          id: 't1',
          startDate: _today.subtract(const Duration(days: 2)),
          endDate: _today.add(const Duration(days: 2)),
        ),
      );
    final questRepo = FakeQuestRepository()..questsResult = const Right([]);
    await _pump(tester, tripRepo: tripRepo, questRepo: questRepo);
    await tester.pumpAndSettle();

    // Today is Day 3 of the 5-day range.
    expect(find.text('Day 3'), findsOneWidget);

    await tester.tap(find.byKey(const Key('day-segment-1')));
    await tester.pumpAndSettle();

    expect(find.text('Day 1'), findsOneWidget);
  });

  group('manage memory sheet', () {
    testWidgets('opens with the current name, dates, and delete resting', (
      tester,
    ) async {
      final tripRepo = FakeTripRepository()
        ..tripCardResult = Right(
          buildTripCard(
            id: 't1',
            name: 'Dolomites, slowly',
            startDate: DateTime(2026, 8, 22),
            endDate: DateTime(2026, 8, 26),
          ),
        );
      final questRepo = FakeQuestRepository()..questsResult = const Right([]);
      await _pump(tester, tripRepo: tripRepo, questRepo: questRepo);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('plan-manage-action')));
      await tester.pumpAndSettle();

      expect(find.text('Edit this memory'), findsOneWidget);
      expect(find.text('Dolomites, slowly'), findsWidgets);
      expect(find.text('22 Aug 2026'), findsOneWidget);
      expect(find.text('26 Aug 2026'), findsOneWidget);
      expect(find.text('Delete this memory'), findsOneWidget);
      expect(find.text('Yes — delete it forever'), findsNothing);
    });

    testWidgets('renaming calls the repository with the new name', (
      tester,
    ) async {
      final tripRepo = FakeTripRepository()
        ..tripCardResult = Right(buildTripCard(id: 't1', name: 'Old name'))
        ..updateTripResult = Right(
          buildTripEntity(id: 't1', name: 'New name'),
        );
      final questRepo = FakeQuestRepository()..questsResult = const Right([]);
      await _pump(tester, tripRepo: tripRepo, questRepo: questRepo);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('plan-manage-action')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'New name');
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      expect(tripRepo.updateTripCallCount, 1);
      expect(tripRepo.lastUpdateName, 'New name');
    });

    testWidgets('tapping a date shifts it and every quest forward a day', (
      tester,
    ) async {
      final tripRepo = FakeTripRepository()
        ..tripCardResult = Right(
          buildTripCard(
            id: 't1',
            startDate: DateTime(2026, 8, 22),
            endDate: DateTime(2026, 8, 26),
          ),
        )
        ..shiftTripDatesResult = Right(
          buildTripEntity(
            id: 't1',
            startDate: DateTime(2026, 8, 23),
            endDate: DateTime(2026, 8, 27),
          ),
        );
      final questRepo = FakeQuestRepository()..questsResult = const Right([]);
      await _pump(tester, tripRepo: tripRepo, questRepo: questRepo);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('plan-manage-action')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('22 Aug 2026'));
      await tester.pumpAndSettle();

      expect(tripRepo.shiftTripDatesCallCount, 1);
      expect(tripRepo.lastShiftDeltaDays, 1);
      expect(find.text('23 Aug 2026'), findsOneWidget);
    });

    testWidgets('delete arms on first tap, showing real photo/note counts', (
      tester,
    ) async {
      final tripRepo = FakeTripRepository()
        ..tripCardResult = Right(buildTripCard(id: 't1'));
      final questRepo = FakeQuestRepository()..questsResult = const Right([]);
      final photoRepo = FakePhotoRepository()
        ..photosResult = Right([
          buildPhotoEntity(id: 'p1'),
          buildPhotoEntity(id: 'p2'),
        ]);
      final noteRepo = FakeDayNoteRepository()
        ..notesForTripResult = Right([buildDayNoteEntity(id: 'n1')]);
      await _pump(
        tester,
        tripRepo: tripRepo,
        questRepo: questRepo,
        photoRepo: photoRepo,
        noteRepo: noteRepo,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('plan-manage-action')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete this memory'));
      await tester.pumpAndSettle();

      expect(find.text('Yes — delete it forever'), findsOneWidget);
      expect(
        find.textContaining('This removes 2 photos and 1 days of notes'),
        findsOneWidget,
      );
      expect(tripRepo.deleteTripCallCount, 0);
    });

    testWidgets('confirming delete deletes the trip and navigates Home', (
      tester,
    ) async {
      final tripRepo = FakeTripRepository()
        ..tripCardResult = Right(buildTripCard(id: 't1'))
        ..deleteTripResult = const Right(null);
      final questRepo = FakeQuestRepository()..questsResult = const Right([]);
      await _pump(tester, tripRepo: tripRepo, questRepo: questRepo);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('plan-manage-action')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete this memory'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes — delete it forever'));
      await tester.pumpAndSettle();

      expect(tripRepo.deleteTripCallCount, 1);
      expect(find.text('home page'), findsOneWidget);
    });

    testWidgets('closing the sheet disarms delete', (tester) async {
      final tripRepo = FakeTripRepository()
        ..tripCardResult = Right(buildTripCard(id: 't1'));
      final questRepo = FakeQuestRepository()..questsResult = const Right([]);
      await _pump(tester, tripRepo: tripRepo, questRepo: questRepo);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('plan-manage-action')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete this memory'));
      await tester.pumpAndSettle();
      expect(find.text('Yes — delete it forever'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('plan-manage-action')));
      await tester.pumpAndSettle();

      expect(find.text('Delete this memory'), findsOneWidget);
      expect(find.text('Yes — delete it forever'), findsNothing);
    });
  });
}
