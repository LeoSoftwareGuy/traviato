import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/day_note_entity.dart';
import '../../domain/repositories/day_note_repository.dart';
import '../datasources/day_note_remote_data_source.dart';

class DayNoteRepositoryImpl implements DayNoteRepository {
  DayNoteRepositoryImpl({required DayNoteRemoteDataSource remote})
    : _remote = remote;

  final DayNoteRemoteDataSource _remote;

  @override
  Future<Either<Failure, DayNoteEntity?>> getNote({
    required String tripId,
    required DateTime dayDate,
  }) async {
    try {
      return Right(await _remote.getNote(tripId: tripId, dayDate: dayDate));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<DayNoteEntity>>> getNotesForTrip(
    String tripId,
  ) async {
    try {
      return Right(await _remote.getNotesForTrip(tripId));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, DayNoteEntity>> upsertNote({
    required String tripId,
    required DateTime dayDate,
    required String content,
  }) async {
    try {
      return Right(
        await _remote.upsertNote(
          id: const Uuid().v4(),
          tripId: tripId,
          dayDate: dayDate,
          content: content,
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
