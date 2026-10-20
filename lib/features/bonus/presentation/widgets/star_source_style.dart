import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/star_ledger_group_entity.dart';

/// Dot/segment color per star source (#219 Phase 5a).
Color starSourceColor(StarSource source) => switch (source) {
  StarSource.photo => AppColors.primary,
  StarSource.note => AppColors.accentCoral,
  StarSource.quest => AppColors.accentBlue,
  StarSource.bonusTask => AppColors.accentPurple,
};

String starSourceLabel(AppLocalizations l10n, StarSource source) =>
    switch (source) {
      StarSource.photo => l10n.stars_photos,
      StarSource.note => l10n.stars_notes,
      StarSource.quest => l10n.stars_quests,
      StarSource.bonusTask => l10n.stars_bonusTasks,
    };
