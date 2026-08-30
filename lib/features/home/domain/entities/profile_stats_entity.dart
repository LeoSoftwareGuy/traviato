import 'package:equatable/equatable.dart';

/// Home stats-bar totals (Memories / Places / Days) and the stars badge —
/// backed by the `profile_stats_view` migration (#27).
class ProfileStatsEntity extends Equatable {
  const ProfileStatsEntity({
    required this.memories,
    required this.places,
    required this.days,
    required this.stars,
  });

  const ProfileStatsEntity.zero()
    : this(memories: 0, places: 0, days: 0, stars: 0);

  final int memories;
  final int places;
  final int days;
  final int stars;

  @override
  List<Object?> get props => [memories, places, days, stars];
}
