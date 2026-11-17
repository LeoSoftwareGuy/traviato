import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/journal_note_entity.dart';

abstract interface class JournalNoteRepository {
  /// The day's notes, oldest first.
  Future<Either<Failure, List<JournalNoteEntity>>> getNotesForDay({
    required String tripId,
    required DateTime dayDate,
  });

  /// Every note across the trip, oldest first.
  Future<Either<Failure, List<JournalNoteEntity>>> getNotesForTrip(
    String tripId,
  );

  /// A new note, timed [takenAt] (when Done was tapped). Earns ✦1, at most
  /// 3 a day.
  Future<Either<Failure, JournalNoteEntity>> createNote({
    required String tripId,
    required DateTime dayDate,
    required DateTime takenAt,
    required String content,
    bool dictated = false,
    String? photoId,
  });

  /// New text for an existing note. Its time stays; no stars change.
  Future<Either<Failure, JournalNoteEntity>> updateNote({
    required String noteId,
    required String content,
    required bool dictated,
  });

  /// Deletes a note. Its star stays (#397).
  Future<Either<Failure, Unit>> deleteNote(String noteId);
}
