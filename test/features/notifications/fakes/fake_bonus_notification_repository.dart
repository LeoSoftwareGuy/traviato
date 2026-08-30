import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/notifications/domain/repositories/bonus_notification_repository.dart';

/// Records every schedule/cancel call so use-case tests can assert on
/// exactly what was decided, without a real plugin (issue #65 AC).
class FakeBonusNotificationRepository implements BonusNotificationRepository {
  bool permissionGranted = false;
  Either<Failure, void>? nextResult;

  final scheduledMorning = <DateTime>[];
  final scheduledEvening = <DateTime>[];
  final scheduledArrival = <(DateTime, String)>[];
  var cancelMorningCallCount = 0;
  var cancelEveningCallCount = 0;
  final cancelledArrivalTripIds = <String>[];

  @override
  Future<Either<Failure, void>> init({
    required void Function(String? payload) onNotificationTap,
  }) async => nextResult ?? const Right(null);

  @override
  Future<Either<Failure, bool>> hasPermission() async =>
      Right(permissionGranted);

  @override
  Future<Either<Failure, bool>> requestPermission() async {
    permissionGranted = true;
    return const Right(true);
  }

  @override
  Future<Either<Failure, void>> scheduleMorning({
    required DateTime fireAt,
    required String tripId,
  }) async {
    scheduledMorning.add(fireAt);
    return nextResult ?? const Right(null);
  }

  @override
  Future<Either<Failure, void>> scheduleEvening({
    required DateTime fireAt,
    required String tripId,
  }) async {
    scheduledEvening.add(fireAt);
    return nextResult ?? const Right(null);
  }

  @override
  Future<Either<Failure, void>> scheduleArrival({
    required DateTime fireAt,
    required String tripId,
  }) async {
    scheduledArrival.add((fireAt, tripId));
    return nextResult ?? const Right(null);
  }

  @override
  Future<Either<Failure, void>> cancelMorning() async {
    cancelMorningCallCount++;
    return nextResult ?? const Right(null);
  }

  @override
  Future<Either<Failure, void>> cancelEvening() async {
    cancelEveningCallCount++;
    return nextResult ?? const Right(null);
  }

  @override
  Future<Either<Failure, void>> cancelArrival(String tripId) async {
    cancelledArrivalTripIds.add(tripId);
    return nextResult ?? const Right(null);
  }
}
