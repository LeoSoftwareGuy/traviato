import '../models/day_note_model.dart';

abstract interface class DayNoteRemoteDataSource {
  Future<DayNoteModel?> getNote({
    required String tripId,
    required DateTime dayDate,
  });

  Future<DayNoteModel> upsertNote({
    required String id,
    required String tripId,
    required DateTime dayDate,
    required String content,
  });
}
