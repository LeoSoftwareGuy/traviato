import '../models/day_note_model.dart';

abstract interface class DayNoteRemoteDataSource {
  Future<DayNoteModel?> getNote({
    required String tripId,
    required DateTime dayDate,
  });

  Future<List<DayNoteModel>> getNotesForTrip(String tripId);

  Future<DayNoteModel> upsertNote({
    required String id,
    required String tripId,
    required DateTime dayDate,
    required String content,
  });

  /// Deletes the note and takes back its ✦1 (`delete_day_note`, #276).
  Future<void> deleteNote(String id);
}
