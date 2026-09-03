import 'package:equatable/equatable.dart';

/// Home stats-bar totals (Memories / Places / Days) and the stars badge —
/// backed by the `profile_stats_view` migration (#27).
class ProfileStatsEntity extends Equatable {
  const ProfileStatsEntity({
    required this.memories,
    required this.places,
    required this.countries,
    required this.days,
    required this.stars,
    required this.photos,
    required this.notes,
  });

  const ProfileStatsEntity.zero()
    : this(
        memories: 0,
        places: 0,
        countries: 0,
        days: 0,
        stars: 0,
        photos: 0,
        notes: 0,
      );

  final int memories;
  final int places;
  final int countries;
  final int days;
  final int stars;
  // Not shown on Home's stats bar or Profile's stats row — carried only to
  // compute the shutterbug/storyteller achievement progress bars (#96),
  // which need a photos/notes current-value the view didn't expose before.
  final int photos;
  final int notes;

  @override
  List<Object?> get props => [
    memories,
    places,
    countries,
    days,
    stars,
    photos,
    notes,
  ];
}
