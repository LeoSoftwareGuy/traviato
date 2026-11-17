import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/journal_note_entity.dart';
import '../../domain/repositories/journal_note_repository.dart';
import '../datasources/journal_note_remote_data_source.dart';

class JournalNoteRepositoryImpl implements JournalNoteRepository {
  JournalNoteRepositoryImpl({required JournalNoteRemoteDataSource remote})
    : _remote = remote;

  final JournalNoteRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<JournalNoteEntity>>> getNotesForDay({
    required String tripId,
    required DateTime dayDate,
  }) => _guard(() => _remote.getNotesForDay(tripId: tripId, dayDate: dayDate));

  @override
  Future<Either<Failure, List<JournalNoteEntity>>> getNotesForTrip(
    String tripId,
  ) => _guard(() => _remote.getNotesForTrip(tripId));

  @override
  Future<Either<Failure, JournalNoteEntity>> createNote({
    required String tripId,
    required DateTime dayDate,
    required DateTime takenAt,
    required String content,
    bool dictated = false,
    String? photoId,
  }) => _guard(
    () => _remote.createNote(
      id: const Uuid().v4(),
      tripId: tripId,
      dayDate: dayDate,
      takenAt: takenAt,
      content: content,
      dictated: dictated,
      photoId: photoId,
    ),
  );

  @override
  Future<Either<Failure, JournalNoteEntity>> updateNote({
    required String noteId,
    required String content,
    required bool dictated,
  }) => _guard(
    () => _remote.updateNote(id: noteId, content: content, dictated: dictated),
  );

  @override
  Future<Either<Failure, Unit>> deleteNote(String noteId) => _guard(() async {
    await _remote.deleteNote(noteId);
    return unit;
  });

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }
}
