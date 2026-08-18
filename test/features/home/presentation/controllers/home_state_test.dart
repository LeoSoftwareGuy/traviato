import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/home/presentation/controllers/home_state.dart';
import 'package:traviato/features/trip/domain/entities/trip_card_entity.dart';

import '../../../trip/fakes/fake_trip_repository.dart';

void main() {
  group('HomeState', () {
    test('isEmpty is true with no trips', () {
      const state = HomeState(trips: []);
      expect(state.isEmpty, isTrue);
      expect(state.heroTrip, isNull);
      expect(state.upcomingTrips, isEmpty);
      expect(state.finishedTrips, isEmpty);
    });

    test('heroTrip is the soonest current/upcoming trip', () {
      final far = buildTripCard(
        id: 'far',
        startDate: DateTime(2026, 12, 1),
        status: TripStatus.upcoming,
      );
      final soon = buildTripCard(
        id: 'soon',
        startDate: DateTime(2026, 9, 1),
        status: TripStatus.upcoming,
      );
      final state = HomeState(trips: [far, soon]);

      expect(state.heroTrip?.id, 'soon');
      expect(state.upcomingTrips.single.id, 'far');
    });

    test('finished trips are sorted by end date, most recent first', () {
      final older = buildTripCard(
        id: 'older',
        status: TripStatus.finished,
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 5),
      );
      final newer = buildTripCard(
        id: 'newer',
        status: TripStatus.finished,
        startDate: DateTime(2025, 6, 1),
        endDate: DateTime(2025, 6, 5),
      );
      final state = HomeState(trips: [older, newer]);

      expect(state.finishedTrips.map((t) => t.id), ['newer', 'older']);
    });

    test('undated trips are excluded from hero, upcoming and finished', () {
      final undated = buildTripCard(id: 'undated', status: TripStatus.undated);
      const state = HomeState(trips: []);
      final withUndated = state.copyWith(trips: [undated]);

      expect(withUndated.heroTrip, isNull);
      expect(withUndated.upcomingTrips, isEmpty);
      expect(withUndated.finishedTrips, isEmpty);
      expect(withUndated.isEmpty, isFalse);
    });
  });
}
