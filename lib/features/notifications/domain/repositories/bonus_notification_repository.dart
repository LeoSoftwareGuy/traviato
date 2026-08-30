import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';

/// Local OS notification scheduling for the bonus daily-tray nudge loop
/// (issue #65). No server/push component — every schedule call is a plain
/// device-local alarm; "cancel" always means "cancel if pending," never an
/// error when nothing was scheduled.
abstract interface class BonusNotificationRepository {
  /// Initializes the platform plugin once. [onNotificationTap] is invoked
  /// with the tapped notification's payload (a `tripId`, or empty for the
  /// no-active-memory landing) — including a cold-start tap, delivered
  /// once after this call resolves.
  Future<Either<Failure, void>> init({
    required void Function(String? payload) onNotificationTap,
  });

  Future<Either<Failure, bool>> hasPermission();

  Future<Either<Failure, bool>> requestPermission();

  Future<Either<Failure, void>> scheduleMorning({
    required DateTime fireAt,
    required String tripId,
  });

  Future<Either<Failure, void>> scheduleEvening({
    required DateTime fireAt,
    required String tripId,
  });

  Future<Either<Failure, void>> scheduleArrival({
    required DateTime fireAt,
    required String tripId,
  });

  Future<Either<Failure, void>> cancelMorning();

  Future<Either<Failure, void>> cancelEvening();

  Future<Either<Failure, void>> cancelArrival(String tripId);
}
