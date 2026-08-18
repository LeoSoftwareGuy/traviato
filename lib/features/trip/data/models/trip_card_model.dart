import '../../domain/entities/trip_card_entity.dart';

/// Maps a `trip_card_view` row. Hand-written (rather than
/// `@JsonSerializable`) because every field needs custom parsing — enum
/// status, dates, and a numeric total — so generated `fromJson` would buy
/// nothing.
class TripCardModel extends TripCardEntity {
  const TripCardModel({
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
    required super.status,
    super.durationDays,
    required super.photoCount,
    required super.stars,
    required super.expenseTotal,
  });

  factory TripCardModel.fromJson(Map<String, dynamic> json) => TripCardModel(
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
    status: _parseStatus(json['status'] as String),
    durationDays: (json['duration_days'] as num?)?.toInt(),
    photoCount: (json['photo_count'] as num).toInt(),
    stars: (json['stars'] as num).toInt(),
    expenseTotal: (json['expense_total'] as num).toDouble(),
  );

  static DateTime? _parseDate(Object? value) =>
      value == null ? null : DateTime.parse(value as String);

  static TripStatus _parseStatus(String value) => switch (value) {
    'upcoming' => TripStatus.upcoming,
    'current' => TripStatus.current,
    'finished' => TripStatus.finished,
    _ => TripStatus.undated,
  };
}
