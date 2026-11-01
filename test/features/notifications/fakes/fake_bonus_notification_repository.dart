import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/notifications/domain/entities/planned_reminder_entity.dart';
import 'package:traviato/features/notifications/domain/repositories/bonus_notification_repository.dart';

/// Records every schedule/cancel call so use-case tests can assert on
/// exactly what was decided, without a real plugin (issue #65 AC).
class FakeBonusNotificationRepository implements BonusNotificationRepository {
  bool permissionGranted = false;
  Either<Failure, void>? nextResult;

  /// Every `replaceReminders` call, in order; the last one is what's
  /// pending now.
  final replacedReminders = <List<PlannedReminderEntity>>[];
  final scheduledArrival = <(DateTime, String)>[];
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
  Future<Either<Failure, void>> replaceReminders(
    List<PlannedReminderEntity> reminders,
  ) async {
    replacedReminders.add(reminders);
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
  Future<Either<Failure, void>> cancelArrival(String tripId) async {
    cancelledArrivalTripIds.add(tripId);
    return nextResult ?? const Right(null);
  }
}
