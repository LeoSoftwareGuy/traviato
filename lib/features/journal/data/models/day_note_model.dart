import '../../domain/entities/day_note_entity.dart';

class DayNoteModel extends DayNoteEntity {
  const DayNoteModel({
    required super.id,
    required super.tripId,
    required super.dayDate,
    required super.content,
    required super.createdAt,
    required super.updatedAt,
  });

  factory DayNoteModel.fromJson(Map<String, dynamic> json) => DayNoteModel(
    id: json['id'] as String,
    tripId: json['trip_id'] as String,
    dayDate: DateTime.parse(json['day_date'] as String),
    content: json['content'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}
