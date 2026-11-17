import '../../domain/entities/journal_note_entity.dart';

class JournalNoteModel extends JournalNoteEntity {
  const JournalNoteModel({
    required super.id,
    required super.tripId,
    required super.dayDate,
    required super.takenAt,
    required super.editedAt,
    required super.content,
    super.dictated,
    super.photoId,
    super.legacy,
  });

  factory JournalNoteModel.fromJson(Map<String, dynamic> json) =>
      JournalNoteModel(
        id: json['id'] as String,
        tripId: json['trip_id'] as String,
        dayDate: DateTime.parse(json['day_date'] as String),
        takenAt: DateTime.parse(json['taken_at'] as String),
        editedAt: DateTime.parse(json['edited_at'] as String),
        content: json['content'] as String,
        dictated: json['dictated'] as bool? ?? false,
        photoId: json['photo_id'] as String?,
        legacy: json['legacy'] as bool? ?? false,
      );
}
