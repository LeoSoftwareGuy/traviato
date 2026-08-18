import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/trip/domain/entities/trip_card_entity.dart';
import 'package:traviato/features/trip/domain/entities/trip_entity.dart';
import 'package:traviato/features/trip/domain/repositories/trip_repository.dart';

/// Test double for [TripRepository]. Returns [tripsResult] (defaulting to an
/// empty list) and records how many times it was called.
class FakeTripRepository implements TripRepository {
  Either<Failure, List<TripCardEntity>>? tripsResult;
  Either<Failure, TripEntity>? createTripResult;
  var callCount = 0;
  var createTripCallCount = 0;
  Duration delay = Duration.zero;

  @override
  Future<Either<Failure, List<TripCardEntity>>> getTripCards() async {
    callCount++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return tripsResult ?? const Right([]);
  }

  @override
  Future<Either<Failure, TripEntity>> createTrip({
    required String name,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    List<String> vibes = const [],
  }) async {
    createTripCallCount++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return createTripResult ??
        Right(
          buildTripEntity(
            name: name,
            destination: destination,
            startDate: startDate,
            endDate: endDate,
            vibes: vibes,
          ),
        );
  }
}

TripEntity buildTripEntity({
  String id = 't1',
  String userId = 'u1',
  String name = 'Weekend in the woods',
  String? destination,
  DateTime? startDate,
  DateTime? endDate,
  List<String> vibes = const [],
}) {
  final now = DateTime(2026, 1, 1);
  return TripEntity(
    id: id,
    userId: userId,
    name: name,
    destination: destination,
    startDate: startDate,
    endDate: endDate,
    vibes: vibes,
    createdAt: now,
    updatedAt: now,
  );
}

TripCardEntity buildTripCard({
  String id = 't1',
  String userId = 'u1',
  String name = 'Weekend in the woods',
  String? destination,
  DateTime? startDate,
  DateTime? endDate,
  List<String> vibes = const [],
  TripStatus status = TripStatus.upcoming,
  int? durationDays,
  int photoCount = 0,
  int stars = 0,
  double expenseTotal = 0,
}) {
  final now = DateTime(2026, 1, 1);
  return TripCardEntity(
    id: id,
    userId: userId,
    name: name,
    destination: destination,
    startDate: startDate,
    endDate: endDate,
    vibes: vibes,
    createdAt: now,
    updatedAt: now,
    status: status,
    durationDays: durationDays,
    photoCount: photoCount,
    stars: stars,
    expenseTotal: expenseTotal,
  );
}
