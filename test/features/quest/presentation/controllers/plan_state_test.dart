import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/quest/presentation/controllers/plan_state.dart';

import '../../../trip/fakes/fake_trip_repository.dart';
import '../../fakes/fake_quest_repository.dart';

void main() {
  group('PlanState.hasDateRange', () {
    test('is false when either date is missing', () {
      final trip = buildTripCard(startDate: DateTime(2026, 8, 18));
      final state = PlanState(trip: trip, quests: const []);
      expect(state.hasDateRange, isFalse);
      expect(state.totalDays, 0);
    });

    test('is true when both dates are set', () {
      final trip = buildTripCard(
        startDate: DateTime(2026, 8, 18),
        endDate: DateTime(2026, 8, 22),
      );
      final state = PlanState(trip: trip, quests: const []);
      expect(state.hasDateRange, isTrue);
      expect(state.totalDays, 5);
    });
  });

  group('PlanState day navigation bounds', () {
    final trip = buildTripCard(
      startDate: DateTime(2026, 8, 18),
      endDate: DateTime(2026, 8, 22),
    );

    test('cannot go before the start date', () {
      final state = PlanState(
        trip: trip,
        quests: const [],
        currentDayDate: DateTime(2026, 8, 18),
      );
      expect(state.canGoToPreviousDay, isFalse);
      expect(state.canGoToNextDay, isTrue);
      expect(state.currentDayNumber, 1);
    });

    test('cannot go past the end date', () {
      final state = PlanState(
        trip: trip,
        quests: const [],
        currentDayDate: DateTime(2026, 8, 22),
      );
      expect(state.canGoToNextDay, isFalse);
      expect(state.canGoToPreviousDay, isTrue);
      expect(state.currentDayNumber, 5);
    });
  });

  group('PlanState.questsForCurrentDay ordering', () {
    test('orders by time (nulls last) then position', () {
      final trip = buildTripCard(
        startDate: DateTime(2026, 8, 18),
        endDate: DateTime(2026, 8, 18),
      );
      final noTime = buildQuestEntity(
        id: 'no-time',
        dayDate: DateTime(2026, 8, 18),
        position: 0,
      );
      final morning = buildQuestEntity(
        id: 'morning',
        dayDate: DateTime(2026, 8, 18),
        time: const Duration(hours: 8),
        position: 1,
      );
      final afternoon = buildQuestEntity(
        id: 'afternoon',
        dayDate: DateTime(2026, 8, 18),
        time: const Duration(hours: 14),
        position: 2,
      );
      final otherDay = buildQuestEntity(
        id: 'other-day',
        dayDate: DateTime(2026, 8, 19),
      );

      final state = PlanState(
        trip: trip,
        quests: [noTime, afternoon, morning, otherDay],
        currentDayDate: DateTime(2026, 8, 18),
      );

      expect(
        state.questsForCurrentDay.map((q) => q.id),
        ['morning', 'afternoon', 'no-time'],
      );
    });
  });
}
