import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/trip_card_entity.dart';

abstract interface class TripRepository {
  Future<Either<Failure, List<TripCardEntity>>> getTripCards();
}
