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
}
