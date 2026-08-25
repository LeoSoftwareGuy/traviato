import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/features/quest/presentation/controllers/plan_controller.dart';
import 'package:traviato/features/quest/presentation/providers/quest_providers.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';

import '../../../trip/fakes/fake_trip_repository.dart';
import '../../fakes/fake_quest_repository.dart';

ProviderContainer _buildContainer({
  required FakeTripRepository tripRepo,
  required FakeQuestRepository questRepo,
}) {
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      tripRepositoryProvider.overrideWithValue(tripRepo),
      questRepositoryProvider.overrideWithValue(questRepo),
    ],
  );
  return container;
}

void main() {
  test('clamps the initial day to today when the trip is running', () async {
    final today = DateTime.now();
    final tripRepo = FakeTripRepository()
      ..tripCardResult = Right(
        buildTripCard(
          id: 't1',
          startDate: today.subtract(const Duration(days: 2)),
          endDate: today.add(const Duration(days: 2)),
        ),
      );
    final questRepo = FakeQuestRepository();
    final container = _buildContainer(tripRepo: tripRepo, questRepo: questRepo);
    addTearDown(container.dispose);

    final state = await container.read(planControllerProvider('t1').future);
    final expectedToday = DateTime(today.year, today.month, today.day);
    expect(state.currentDayDate, expectedToday);
  });

  test(
    'clamps the initial day to the start date for an upcoming trip',
    () async {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day + 10);
      final tripRepo = FakeTripRepository()
        ..tripCardResult = Right(
          buildTripCard(
            id: 't1',
            startDate: start,
            endDate: start.add(const Duration(days: 3)),
          ),
        );
      final questRepo = FakeQuestRepository();
      final container = _buildContainer(
        tripRepo: tripRepo,
        questRepo: questRepo,
      );
      addTearDown(container.dispose);

      final state = await container.read(planControllerProvider('t1').future);
      expect(
        state.currentDayDate,
        DateTime(start.year, start.month, start.day),
      );
    },
  );

  test('leaves currentDayDate null when the trip has no dates', () async {
    final tripRepo = FakeTripRepository()
      ..tripCardResult = Right(buildTripCard(id: 't1'));
    final questRepo = FakeQuestRepository();
    final container = _buildContainer(tripRepo: tripRepo, questRepo: questRepo);
    addTearDown(container.dispose);

    final state = await container.read(planControllerProvider('t1').future);
    expect(state.currentDayDate, isNull);
    expect(state.hasDateRange, isFalse);
  });

  test('goToNextDay/goToPreviousDay respect the trip range', () async {
    final start = DateTime(2026, 8, 18);
    final end = DateTime(2026, 8, 19);
    final tripRepo = FakeTripRepository()
      ..tripCardResult = Right(
        buildTripCard(id: 't1', startDate: start, endDate: end),
      );
    final questRepo = FakeQuestRepository();
    final container = _buildContainer(tripRepo: tripRepo, questRepo: questRepo);
    addTearDown(container.dispose);
    container.listen(planControllerProvider('t1'), (_, _) {});

    await container.read(planControllerProvider('t1').future);
    final notifier = container.read(planControllerProvider('t1').notifier);

    // Trip only spans 2 days; starting day depends on "today" vs range, so
    // force to the start date first via repeated previous-day calls.
    notifier.goToPreviousDay();
    notifier.goToPreviousDay();
    expect(
      container.read(planControllerProvider('t1')).value?.currentDayDate,
      isNotNull,
    );

    notifier.goToNextDay();
    notifier.goToNextDay();
    notifier.goToNextDay();
    final finalState = container.read(planControllerProvider('t1')).value!;
    expect(finalState.currentDayDate, end);
    expect(finalState.canGoToNextDay, isFalse);
  });

  test(
    'applyQuestUpserted adds a new quest and replaces an existing one',
    () async {
      final tripRepo = FakeTripRepository()
        ..tripCardResult = Right(
          buildTripCard(
            id: 't1',
            startDate: DateTime(2026, 8, 18),
            endDate: DateTime(2026, 8, 18),
          ),
        );
      final questRepo = FakeQuestRepository()..questsResult = const Right([]);
      final container = _buildContainer(
        tripRepo: tripRepo,
        questRepo: questRepo,
      );
      addTearDown(container.dispose);
      container.listen(planControllerProvider('t1'), (_, _) {});

      await container.read(planControllerProvider('t1').future);
      final notifier = container.read(planControllerProvider('t1').notifier);

      final quest = buildQuestEntity(id: 'q1', title: 'Pack the car');
      notifier.applyQuestUpserted(quest);
      expect(
        container.read(planControllerProvider('t1')).value?.quests.single.title,
        'Pack the car',
      );

      final updated = buildQuestEntity(
        id: 'q1',
        title: 'Pack the car (edited)',
      );
      notifier.applyQuestUpserted(updated);
      final state = container.read(planControllerProvider('t1')).value!;
      expect(state.quests, hasLength(1));
      expect(state.quests.single.title, 'Pack the car (edited)');

      notifier.applyQuestRemoved('q1');
      expect(
        container.read(planControllerProvider('t1')).value?.quests,
        isEmpty,
      );
    },
  );

  test(
    'applyTripUpdated replaces the held trip without touching quests',
    () async {
      final tripRepo = FakeTripRepository()
        ..tripCardResult = Right(
          buildTripCard(
            id: 't1',
            name: 'Old name',
            startDate: DateTime(2026, 8, 18),
            endDate: DateTime(2026, 8, 19),
          ),
        );
      final quest = buildQuestEntity(id: 'q1', dayDate: DateTime(2026, 8, 18));
      final questRepo = FakeQuestRepository()..questsResult = Right([quest]);
      final container = _buildContainer(
        tripRepo: tripRepo,
        questRepo: questRepo,
      );
      addTearDown(container.dispose);
      container.listen(planControllerProvider('t1'), (_, _) {});

      await container.read(planControllerProvider('t1').future);
      final notifier = container.read(planControllerProvider('t1').notifier);

      final renamed = buildTripCard(
        id: 't1',
        name: 'New name',
        startDate: DateTime(2026, 8, 18),
        endDate: DateTime(2026, 8, 19),
      );
      notifier.applyTripUpdated(renamed);

      final state = container.read(planControllerProvider('t1')).value!;
      expect(state.trip.name, 'New name');
      expect(state.quests.single.id, 'q1');
      expect(state.quests.single.dayDate, DateTime(2026, 8, 18));
    },
  );

  test(
    'applyDatesShifted moves the trip, every quest, and the current day '
    'by the same delta — both directions',
    () async {
      final tripRepo = FakeTripRepository()
        ..tripCardResult = Right(
          buildTripCard(
            id: 't1',
            startDate: DateTime(2026, 8, 18),
            endDate: DateTime(2026, 8, 19),
          ),
        );
      final quest = buildQuestEntity(id: 'q1', dayDate: DateTime(2026, 8, 18));
      final questRepo = FakeQuestRepository()..questsResult = Right([quest]);
      final container = _buildContainer(
        tripRepo: tripRepo,
        questRepo: questRepo,
      );
      addTearDown(container.dispose);
      container.listen(planControllerProvider('t1'), (_, _) {});

      await container.read(planControllerProvider('t1').future);
      final notifier = container.read(planControllerProvider('t1').notifier);
      final before = container.read(planControllerProvider('t1')).value!;
      final beforeDay = before.currentDayDate!;

      final shiftedForward = buildTripCard(
        id: 't1',
        startDate: DateTime(2026, 8, 19),
        endDate: DateTime(2026, 8, 20),
      );
      notifier.applyDatesShifted(shiftedForward, 1);
      final forwardState = container.read(planControllerProvider('t1')).value!;
      expect(forwardState.trip.startDate, DateTime(2026, 8, 19));
      expect(forwardState.trip.endDate, DateTime(2026, 8, 20));
      expect(forwardState.quests.single.dayDate, DateTime(2026, 8, 19));
      expect(
        forwardState.currentDayDate,
        beforeDay.add(const Duration(days: 1)),
      );

      final shiftedBack = buildTripCard(
        id: 't1',
        startDate: DateTime(2026, 8, 18),
        endDate: DateTime(2026, 8, 19),
      );
      notifier.applyDatesShifted(shiftedBack, -1);
      final backState = container.read(planControllerProvider('t1')).value!;
      expect(backState.trip.startDate, DateTime(2026, 8, 18));
      expect(backState.trip.endDate, DateTime(2026, 8, 19));
      expect(backState.quests.single.dayDate, DateTime(2026, 8, 18));
      expect(backState.currentDayDate, beforeDay);
    },
  );
}
