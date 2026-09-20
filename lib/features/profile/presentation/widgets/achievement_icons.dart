import 'package:flutter/material.dart';

/// Per-badge glyph keyed on `achievement_templates.code` (docs/data-model.md
/// has no icon column — this is presentation-only, so a new code just needs
/// an entry here, no migration). Pick replacements from fonts.google.com/icons
/// (style: "Material Icons") and reference them as `Icons.snake_case_name`.
const Map<String, IconData> achievementIcons = {
  'first_adventure': Icons.rocket_launch_outlined,
  'globetrotter': Icons.public,
  'century': Icons.calendar_month_outlined,
  'star_collector': Icons.star_outline,
  'shutterbug': Icons.camera_alt_outlined,
  'storyteller': Icons.auto_stories_outlined,
  'jetsetter': Icons.flight_takeoff_outlined,
  'legend': Icons.workspace_premium_outlined,
};

const IconData _defaultAchievementIcon = Icons.emoji_events_outlined;

IconData achievementIconFor(String code) =>
    achievementIcons[code] ?? _defaultAchievementIcon;
