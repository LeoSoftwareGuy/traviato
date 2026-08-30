import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/bonus_notification_repository.dart';
import '../datasources/bonus_notification_local_data_source.dart';

class BonusNotificationRepositoryImpl implements BonusNotificationRepository {
  BonusNotificationRepositoryImpl({
    required BonusNotificationLocalDataSource local,
  }) : _local = local;

  final BonusNotificationLocalDataSource _local;

  @override
  Future<Either<Failure, void>> init({
    required void Function(String? payload) onNotificationTap,
  }) => _run(() => _local.init(onTap: onNotificationTap));

  @override
  Future<Either<Failure, bool>> hasPermission() => _run(_local.hasPermission);

  @override
  Future<Either<Failure, bool>> requestPermission() =>
      _run(_local.requestPermission);

  @override
  Future<Either<Failure, void>> scheduleMorning({
    required DateTime fireAt,
    required String tripId,
  }) => _run(() => _local.scheduleMorning(fireAt: fireAt, tripId: tripId));

  @override
  Future<Either<Failure, void>> scheduleEvening({
    required DateTime fireAt,
    required String tripId,
  }) => _run(() => _local.scheduleEvening(fireAt: fireAt, tripId: tripId));

  @override
  Future<Either<Failure, void>> scheduleArrival({
    required DateTime fireAt,
    required String tripId,
  }) => _run(() => _local.scheduleArrival(fireAt: fireAt, tripId: tripId));

  @override
  Future<Either<Failure, void>> cancelMorning() => _run(_local.cancelMorning);

  @override
  Future<Either<Failure, void>> cancelEvening() => _run(_local.cancelEvening);

  @override
  Future<Either<Failure, void>> cancelArrival(String tripId) =>
      _run(() => _local.cancelArrival(tripId));

  /// The plugin doesn't have a typed exception hierarchy like Supabase's
  /// (doc 04) — any platform-channel failure is genuinely unexpected here,
  /// so it maps straight to [UnknownFailure] per doc 03's "log and degrade"
  /// guidance rather than a specific subtype.
  Future<Either<Failure, T>> _run<T>(Future<T> Function() body) async {
    try {
      return Right(await body());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: '$e'));
    }
  }
}
