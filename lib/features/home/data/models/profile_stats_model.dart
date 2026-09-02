import '../../domain/entities/profile_stats_entity.dart';

/// Maps a `profile_stats_view` row.
class ProfileStatsModel extends ProfileStatsEntity {
  const ProfileStatsModel({
    required super.memories,
    required super.places,
    required super.countries,
    required super.days,
    required super.stars,
    required super.photos,
    required super.notes,
  });

  factory ProfileStatsModel.fromJson(Map<String, dynamic> json) =>
      ProfileStatsModel(
        memories: (json['memories_count'] as num).toInt(),
        places: (json['places_count'] as num).toInt(),
        countries: (json['countries_count'] as num).toInt(),
        days: (json['days_logged'] as num).toInt(),
        stars: (json['stars_total'] as num).toInt(),
        photos: (json['photos_count'] as num).toInt(),
        notes: (json['notes_count'] as num).toInt(),
      );
}
