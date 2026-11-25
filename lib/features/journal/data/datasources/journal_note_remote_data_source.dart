import '../models/journal_note_model.dart';

abstract interface class JournalNoteRemoteDataSource {
  /// The day's notes, oldest first.
  Future<List<JournalNoteModel>> getNotesForDay({
    required String tripId,
    required DateTime dayDate,
  });

  /// Every note of the trip, oldest first.
  Future<List<JournalNoteModel>> getNotesForTrip(String tripId);

  /// Inserts a new note and awards its ✦1 (at most 3 a day, server-side).
  Future<JournalNoteModel> createNote({
    required String id,
    required String tripId,
    required DateTime dayDate,
    required DateTime takenAt,
    required String content,
    required bool dictated,
    String? photoId,
  });

  /// New text for a note; its time never changes. No stars either way.
  Future<JournalNoteModel> updateNote({
    required String id,
    required String content,
    required bool dictated,
  });

  /// "Edit time" (#468): when the note happened, on its own day, at the
  /// place's [utcOffsetMinutes]. Returns the note as saved.
  Future<JournalNoteModel> setNoteTime({
    required String id,
    required DateTime takenAt,
    required int utcOffsetMinutes,
  });

  /// Deletes a note. Its star stays (#397).
  Future<void> deleteNote(String id);
}
