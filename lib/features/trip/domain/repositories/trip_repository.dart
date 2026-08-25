import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/trip_card_entity.dart';
import '../entities/trip_entity.dart';

abstract interface class TripRepository {
  Future<Either<Failure, List<TripCardEntity>>> getTripCards();

  Future<Either<Failure, TripCardEntity>> getTripCard(String tripId);

  Future<Either<Failure, TripEntity>> createTrip({
    required String name,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    List<String> vibes,
    String? coverImagePath,
  });

  Future<Either<Failure, void>> deleteTrip(String id);

  /// Plain authenticated update — used for both a rename and a cover
  /// change. Pass only the field(s) being changed.
  Future<Either<Failure, TripEntity>> updateTrip({
    required String id,
    String? name,
    String? coverImagePath,
  });

  /// Shifts the trip's start/end dates and every one of its quests'
  /// `day_date` by [deltaDays] in one transaction (the `shift_trip_dates`
  /// RPC) — a client-side batched update across two tables risks a partial
  /// failure leaving them out of sync.
  Future<Either<Failure, TripEntity>> shiftTripDates({
    required String id,
    required int deltaDays,
  });
}
