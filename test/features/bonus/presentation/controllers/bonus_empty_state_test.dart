import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/bonus/domain/entities/star_ledger_group_entity.dart';
import 'package:traviato/features/bonus/domain/entities/star_summary.dart';
import 'package:traviato/features/bonus/presentation/controllers/bonus_empty_state.dart';

import '../../../trip/fakes/fake_trip_repository.dart';

void main() {
  final today = DateTime(2026, 10, 17, 9);
  const someStars = StarSummary(
    totalStars: 3,
    bySource: [
      StarSourceTotal(source: StarSource.photo, count: 1, points: 2),
      StarSourceTotal(source: StarSource.note, count: 1, points: 1),
    ],
    byMemory: [],
    memoryCount: 1,
  );

  final past = buildTripCard(
    id: 'past',
    startDate: DateTime(2026, 8, 1),
    endDate: DateTime(2026, 8, 5),
  );
  final lisbon = buildTripCard(
    id: 'lisbon',
    startDate: DateTime(2026, 10, 21),
    endDate: DateTime(2026, 10, 24),
  );
  final later = buildTripCard(
    id: 'later',
    startDate: DateTime(2026, 12, 1),
    endDate: DateTime(2026, 12, 3),
  );

  group('BonusEmptyState.resolve', () {
    test('a memory under way today → its tray', () {
      final now = buildTripCard(
        id: 'now',
        startDate: DateTime(2026, 10, 15),
        endDate: DateTime(2026, 10, 17),
      );
      expect(
        BonusEmptyState.resolve(
          trips: [lisbon, now],
          summary: someStars,
          today: today,
        ),
        const BonusTrayActive(tripId: 'now'),
      );
    });

    test('upcoming only → the soonest future memory, with days until', () {
      final state = BonusEmptyState.resolve(
        trips: [later, past, lisbon],
        summary: someStars,
        today: today,
      );
      expect(state, isA<BonusUpcoming>());
      state as BonusUpcoming;
      expect(state.trip.id, 'lisbon');
      expect(state.daysUntil, 4);
      expect(state.summary, someStars);
    });

    test('upcoming beats the star count: 0 stars still shows upcoming', () {
      final state = BonusEmptyState.resolve(
        trips: [lisbon],
        summary: const StarSummary.empty(),
        today: today,
      );
      expect(state, isA<BonusUpcoming>());
    });

    test('nothing upcoming with stars → nothing upcoming', () {
      expect(
        BonusEmptyState.resolve(
          trips: [past],
          summary: someStars,
          today: today,
        ),
        const BonusNothingUpcoming(summary: someStars),
      );
    });

    test('nothing upcoming and no stars → brand new', () {
      expect(
        BonusEmptyState.resolve(
          trips: const [],
          summary: const StarSummary.empty(),
          today: today,
        ),
        const BonusBrandNew(),
      );
    });

    test('an undated memory is neither under way nor upcoming', () {
      expect(
        BonusEmptyState.resolve(
          trips: [buildTripCard(id: 'undated')],
          summary: const StarSummary.empty(),
          today: today,
        ),
        const BonusBrandNew(),
      );
    });

    test('a memory starting tomorrow is upcoming in 1 day; at midnight it '
        'turns into the tray', () {
      final tomorrow = buildTripCard(
        id: 'tomorrow',
        startDate: DateTime(2026, 10, 18),
        endDate: DateTime(2026, 10, 19),
      );
      final lateEvening = BonusEmptyState.resolve(
        trips: [tomorrow],
        summary: someStars,
        today: DateTime(2026, 10, 17, 23, 59, 59),
      );
      expect((lateEvening as BonusUpcoming).daysUntil, 1);

      expect(
        BonusEmptyState.resolve(
          trips: [tomorrow],
          summary: someStars,
          today: DateTime(2026, 10, 18),
        ),
        const BonusTrayActive(tripId: 'tomorrow'),
      );
    });
  });

  group('BonusEmptyState.daysUntil', () {
    test('counts calendar days, whatever the time of day', () {
      final start = DateTime(2026, 10, 21);
      expect(
        BonusEmptyState.daysUntil(start, today: DateTime(2026, 10, 17)),
        4,
      );
      expect(
        BonusEmptyState.daysUntil(
          start,
          today: DateTime(2026, 10, 17, 23, 59),
        ),
        4,
      );
      expect(
        BonusEmptyState.daysUntil(start, today: DateTime(2026, 10, 20, 0, 1)),
        1,
      );
    });

    test('a DST change in between does not lose a day', () {
      // Clocks go back on 25 Oct 2026 in the EU: that local "day" is 25h.
      expect(
        BonusEmptyState.daysUntil(
          DateTime(2026, 10, 27),
          today: DateTime(2026, 10, 24, 22),
        ),
        3,
      );
      // And forward on 29 Mar 2026 (a 23h day).
      expect(
        BonusEmptyState.daysUntil(
          DateTime(2026, 3, 30),
          today: DateTime(2026, 3, 28, 1),
        ),
        2,
      );
    });
  });
}
