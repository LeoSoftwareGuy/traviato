import '../../domain/entities/profile_stats_entity.dart';

/// Maps a `profile_stats_view` row.
class ProfileStatsModel extends ProfileStatsEntity {
  const ProfileStatsModel({
    required super.memories,
    required super.places,
    required super.days,
    required super.stars,
  });

  factory ProfileStatsModel.fromJson(Map<String, dynamic> json) =>
      ProfileStatsModel(
        memories: (json['memories_count'] as num).toInt(),
        places: (json['places_count'] as num).toInt(),
        days: (json['days_logged'] as num).toInt(),
        stars: (json['stars_total'] as num).toInt(),
      );
}
