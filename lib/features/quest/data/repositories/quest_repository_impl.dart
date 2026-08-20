import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/quest_entity.dart';
import '../../domain/repositories/quest_repository.dart';
import '../datasources/quest_remote_data_source.dart';

class QuestRepositoryImpl implements QuestRepository {
  QuestRepositoryImpl({required QuestRemoteDataSource remote})
    : _remote = remote;

  final QuestRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<QuestEntity>>> getQuestsForTrip(
    String tripId,
  ) async {
    try {
      return Right(await _remote.getQuestsForTrip(tripId));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, QuestEntity>> addQuest({
    required String tripId,
    required DateTime dayDate,
    required String title,
    Duration? time,
    String? placeText,
    required int position,
  }) async {
    try {
      return Right(
        await _remote.addQuest(
          id: const Uuid().v4(),
          tripId: tripId,
          dayDate: dayDate,
          title: title,
          time: time,
          placeText: placeText,
          position: position,
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
  Future<Either<Failure, QuestEntity>> updateQuest({
    required String id,
    required String title,
    Duration? time,
    String? placeText,
  }) async {
    try {
      return Right(
        await _remote.updateQuest(
          id: id,
          title: title,
          time: time,
          placeText: placeText,
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
  Future<Either<Failure, void>> deleteQuest(String id) async {
    try {
      await _remote.deleteQuest(id);
      return const Right(null);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, QuestEntity>> toggleCompleted({
    required String id,
    required bool completed,
  }) async {
    try {
      return Right(await _remote.toggleCompleted(id: id, completed: completed));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }
}
