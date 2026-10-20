/// Star values per source — the client-side copy of what the
/// `award_points` RPC awards (docs/data-model.md: note 1 · photo 2 ·
/// quest 1 · bonus per template). The server stays the source of truth;
/// `test/core/constants/points_config_test.dart` fails if the two drift.
library;

abstract final class PointsConfig {
  static const photo = 2;
  static const note = 1;
  static const quest = 1;

  /// The reward range of a regular daily-tray bonus task (seeded templates
  /// carry their own value; stretch, milestone and streak-saver tasks sit
  /// outside the everyday range).
  static const bonusTaskMin = 1;
  static const bonusTaskMax = 3;
}
