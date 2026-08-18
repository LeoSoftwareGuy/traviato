import '../../domain/entities/trip_entity.dart';

/// Maps a raw `trips` row (e.g. the row returned by an insert).
class TripModel extends TripEntity {
  const TripModel({
    required super.id,
    required super.userId,
    required super.name,
    super.destination,
    super.countryCode,
    super.startDate,
    super.endDate,
    super.vibes,
    super.coverImagePath,
    required super.createdAt,
    required super.updatedAt,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) => TripModel(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    name: json['name'] as String,
    destination: json['destination'] as String?,
    countryCode: json['country_code'] as String?,
    startDate: _parseDate(json['start_date']),
    endDate: _parseDate(json['end_date']),
    vibes: (json['vibes'] as List<dynamic>? ?? const []).cast<String>(),
    coverImagePath: json['cover_image_path'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  static DateTime? _parseDate(Object? value) =>
      value == null ? null : DateTime.parse(value as String);
}
