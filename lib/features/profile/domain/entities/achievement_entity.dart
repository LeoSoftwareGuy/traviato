import 'package:equatable/equatable.dart';

/// Matches `achievement_templates.metric`'s check constraint
/// (docs/data-model.md).
enum AchievementMetric {
  trips,
  countries,
  daysLogged,
  stars,
  photos,
  notes;

  static AchievementMetric fromDb(String value) => switch (value) {
    'trips' => AchievementMetric.trips,
    'countries' => AchievementMetric.countries,
    'days_logged' => AchievementMetric.daysLogged,
    'stars' => AchievementMetric.stars,
    'photos' => AchievementMetric.photos,
    'notes' => AchievementMetric.notes,
    _ => throw ArgumentError('Unknown achievement metric: $value'),
  };

  /// The locked card's mono progress line unit, e.g. "9 OF 14 DAYS"
  /// (docs/design/README.md § 11).
  String get unitLabel => switch (this) {
    AchievementMetric.trips => 'MEMORIES',
    AchievementMetric.countries => 'COUNTRIES',
    AchievementMetric.daysLogged => 'DAYS',
    AchievementMetric.stars => 'STARS',
    AchievementMetric.photos => 'PHOTOS',
    AchievementMetric.notes => 'NOTES',
  };
}

/// An `achievement_templates` row joined with the caller's own
/// `user_achievements` (earned or not) and a current metric value derived
/// from `profile_stats_view` — combined client-side in
/// `ProfileRepository.getAchievements()` rather than a per-metric SQL join.
class AchievementEntity extends Equatable {
  const AchievementEntity({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.metric,
    required this.target,
    required this.position,
    required this.currentValue,
    this.earnedAt,
  });

  final int id;
  final String code;
  final String title;
  final String description;
  final AchievementMetric metric;
  final int target;
  final int position;
  final int currentValue;
  final DateTime? earnedAt;

  bool get isEarned => earnedAt != null;

  /// Clamped to 0–1 for the locked card's progress bar — [currentValue] can
  /// exceed [target] for a heavily-used metric (e.g. stars) right up until
  /// `check_achievements()`'s next run actually marks it earned.
  double get progress {
    if (target <= 0) return 0;
    final fraction = currentValue / target;
    return fraction.clamp(0, 1).toDouble();
  }

  /// The locked card's mono progress line, e.g. "9 OF 14 DAYS".
  String get progressLabel {
    final shown = currentValue > target ? target : currentValue;
    return '$shown OF $target ${metric.unitLabel}';
  }

  @override
  List<Object?> get props => [
    id,
    code,
    title,
    description,
    metric,
    target,
    position,
    currentValue,
    earnedAt,
  ];
}
