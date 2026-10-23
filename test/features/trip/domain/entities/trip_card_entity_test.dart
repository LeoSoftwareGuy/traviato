import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/trip/domain/entities/trip_card_entity.dart';
import 'package:traviato/features/trip/domain/entities/trip_entity.dart';

import '../../fakes/fake_trip_repository.dart';

void main() {
  group('TripCardEntity.isPastCreated (#164)', () {
    final created = DateTime(2026, 9, 10, 12);

    test('is true when the whole trip ended before the creation day', () {
      final trip = buildTripCard(
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 5),
        createdAt: created,
      );
      expect(trip.isPastCreated, isTrue);
    });

    test('is true when the trip ended the day before creation', () {
      final trip = buildTripCard(
        startDate: DateTime(2026, 9, 5),
        endDate: DateTime(2026, 9, 9),
        createdAt: created,
      );
      expect(trip.isPastCreated, isTrue);
    });

    test('is false when created mid-trip (day 3 of 5)', () {
      final trip = buildTripCard(
        startDate: DateTime(2026, 9, 8),
        endDate: DateTime(2026, 9, 12),
        createdAt: created,
      );
      expect(trip.isPastCreated, isFalse);
    });

    test('is false when created on the last day of the trip', () {
      final trip = buildTripCard(
        startDate: DateTime(2026, 9, 6),
        endDate: DateTime(2026, 9, 10),
        createdAt: DateTime(2026, 9, 10, 23, 59),
      );
      expect(trip.isPastCreated, isFalse);
    });

    test('is false for an upcoming trip', () {
      final trip = buildTripCard(
        startDate: DateTime(2026, 10, 1),
        endDate: DateTime(2026, 10, 5),
        createdAt: created,
      );
      expect(trip.isPastCreated, isFalse);
    });

    test('is false for an undated trip', () {
      expect(buildTripCard(createdAt: created).isPastCreated, isFalse);
    });

    test('compares against the local creation date, not the UTC one', () {
      // Late on the trip's last evening locally — in UTC this may already be
      // the next day, which must not flip the trip to past-created.
      final trip = buildTripCard(
        startDate: DateTime(2026, 9, 6),
        endDate: DateTime(2026, 9, 10),
        createdAt: DateTime(2026, 9, 10, 23, 30).toUtc(),
      );
      expect(trip.isPastCreated, isFalse);
    });

    test('a freshly created past trip is also finished, so Home only ever '
        'shows it under Kept forever (no Plan entry point)', () {
      final now = DateTime.now();
      final card = TripCardEntity.fromNewTrip(
        TripEntity(
          id: 't1',
          userId: 'u1',
          name: 'Lisbon last spring',
          startDate: DateTime(now.year - 1, 4, 1),
          endDate: DateTime(now.year - 1, 4, 5),
          createdAt: now,
          updatedAt: now,
        ),
      );
      expect(card.isPastCreated, isTrue);
      expect(card.status, TripStatus.finished);
    });
  });

  group('TripCardEntity status around the start day (#287)', () {
    TripCardEntity startingIn(int days) {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day + days);
      return TripCardEntity.fromNewTrip(
        TripEntity(
          id: 't1',
          userId: 'u1',
          name: 'Rome',
          startDate: start,
          endDate: DateTime(start.year, start.month, start.day + 4),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    test('a memory starting today is current — Home shows Journal', () {
      expect(startingIn(0).status, TripStatus.current);
    });

    test('a memory starting tomorrow is still upcoming', () {
      expect(startingIn(1).status, TripStatus.upcoming);
    });
  });

  group('TripCardEntity.isUnderwayOn (#219)', () {
    final trip = buildTripCard(
      startDate: DateTime(2026, 10, 21),
      endDate: DateTime(2026, 10, 24),
    );

    test('includes the first and last day, ignoring the time of day', () {
      expect(trip.isUnderwayOn(DateTime(2026, 10, 21)), isTrue);
      expect(trip.isUnderwayOn(DateTime(2026, 10, 24, 23, 59)), isTrue);
    });

    test('is false the day before and the day after', () {
      expect(trip.isUnderwayOn(DateTime(2026, 10, 20, 23, 59)), isFalse);
      expect(trip.isUnderwayOn(DateTime(2026, 10, 25)), isFalse);
    });

    test('an undated trip is never under way', () {
      expect(buildTripCard().isUnderwayOn(DateTime(2026, 10, 21)), isFalse);
    });
  });
}
