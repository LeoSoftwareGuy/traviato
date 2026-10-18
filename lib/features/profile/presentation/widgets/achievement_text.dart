import '../../../../core/l10n/context_l10n.dart';
import '../../domain/entities/achievement_entity.dart';

// Generated from the seeded `achievement_templates` (#243). An unknown code
// falls back to the DB text.

/// An achievement's title in the UI language.
String achievementTitle(AppLocalizations l10n, AchievementEntity a) =>
    switch (a.code) {
      'first_adventure' => l10n.content_achievement_first_adventure_title,
      'globetrotter' => l10n.content_achievement_globetrotter_title,
      'century' => l10n.content_achievement_century_title,
      'star_collector' => l10n.content_achievement_star_collector_title,
      'shutterbug' => l10n.content_achievement_shutterbug_title,
      'storyteller' => l10n.content_achievement_storyteller_title,
      'jetsetter' => l10n.content_achievement_jetsetter_title,
      'legend' => l10n.content_achievement_legend_title,
      _ => a.title,
    };

/// An achievement's description in the UI language.
String achievementDescription(AppLocalizations l10n, AchievementEntity a) =>
    switch (a.code) {
      'first_adventure' => l10n.content_achievement_first_adventure_description,
      'globetrotter' => l10n.content_achievement_globetrotter_description,
      'century' => l10n.content_achievement_century_description,
      'star_collector' => l10n.content_achievement_star_collector_description,
      'shutterbug' => l10n.content_achievement_shutterbug_description,
      'storyteller' => l10n.content_achievement_storyteller_description,
      'jetsetter' => l10n.content_achievement_jetsetter_description,
      'legend' => l10n.content_achievement_legend_description,
      _ => a.description,
    };
