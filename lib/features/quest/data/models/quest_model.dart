import '../../domain/entities/quest_entity.dart';

/// Maps a `quests` row. Hand-written (rather than `@JsonSerializable`)
/// because `time` needs custom parsing — Postgres returns it as `"HH:MM:SS"`.
class QuestModel extends QuestEntity {
  const QuestModel({
    required super.id,
    required super.tripId,
    required super.dayDate,
    super.time,
    required super.title,
    super.placeText,
    required super.position,
    super.completedAt,
    required super.createdAt,
  });

  factory QuestModel.fromJson(Map<String, dynamic> json) => QuestModel(
    id: json['id'] as String,
    tripId: json['trip_id'] as String,
    dayDate: DateTime.parse(json['day_date'] as String),
    time: parseTimeOfDayString(json['time'] as String?),
    title: json['title'] as String,
    placeText: json['place_text'] as String?,
    position: (json['position'] as num).toInt(),
    completedAt: json['completed_at'] == null
        ? null
        : DateTime.parse(json['completed_at'] as String),
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

/// Parses a Postgres `time` string (`"HH:MM:SS"`) into an offset from
/// midnight. Shared with the datasource's outgoing formatting.
Duration? parseTimeOfDayString(String? value) {
  if (value == null) return null;
  final parts = value.split(':');
  return Duration(
    hours: int.parse(parts[0]),
    minutes: int.parse(parts[1]),
    seconds: parts.length > 2 ? int.parse(parts[2]) : 0,
  );
}

String? formatTimeOfDayString(Duration? time) {
  if (time == null) return null;
  final hours = time.inHours.toString().padLeft(2, '0');
  final minutes = (time.inMinutes % 60).toString().padLeft(2, '0');
  return '$hours:$minutes:00';
}
