import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/bonus_task_assignment_entity.dart';
import '../../domain/entities/bonus_task_template_entity.dart';
import '../../domain/repositories/bonus_task_repository.dart';
import '../datasources/bonus_task_remote_data_source.dart';

class BonusTaskRepositoryImpl implements BonusTaskRepository {
  BonusTaskRepositoryImpl({required BonusTaskRemoteDataSource remote})
    : _remote = remote;

  final BonusTaskRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<BonusTaskTemplateEntity>>> getTemplates() async {
    try {
      return Right(await _remote.getTemplates());
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<BonusTaskAssignmentEntity>>>
  getAssignmentsForTrip(String tripId) async {
    try {
      return Right(await _remote.getAssignmentsForTrip(tripId));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<BonusTaskAssignmentEntity>>> assignForDay({
    required String tripId,
    required DateTime dayDate,
    required List<int> templateIds,
  }) async {
    try {
      final assignments = [
        for (final templateId in templateIds) (const Uuid().v4(), templateId),
      ];
      return Right(
        await _remote.assignForDay(
          tripId: tripId,
          dayDate: dayDate,
          assignments: assignments,
        ),
      );
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, BonusTaskAssignmentEntity>> completeAssignment({
    required String id,
    required String tripId,
    required String photoId,
  }) async {
    try {
      return Right(
        await _remote.completeAssignment(
          id: id,
          tripId: tripId,
          photoId: photoId,
        ),
      );
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }
}
