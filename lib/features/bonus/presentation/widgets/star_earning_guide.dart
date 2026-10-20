import 'package:flutter/material.dart';

import '../../../../core/constants/points_config.dart';
import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/star_ledger_group_entity.dart';
import 'star_breakdown_rows.dart';
import 'star_source_style.dart';

/// "How stars collect" (#219 Phase 5b): at 0 stars the summary becomes a
/// guide to what each thing earns, so the page is never empty.
class StarEarningGuide extends StatelessWidget {
  const StarEarningGuide({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = [
      (StarSource.photo, l10n.stars_guidePhoto, '✦${PointsConfig.photo}'),
      (StarSource.note, l10n.stars_guideNote, '✦${PointsConfig.note}'),
      (StarSource.quest, l10n.stars_guideQuest, '✦${PointsConfig.quest}'),
      (
        StarSource.bonusTask,
        l10n.stars_guideBonus,
        '✦${PointsConfig.bonusTaskMin}–${PointsConfig.bonusTaskMax}',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.stars_howCollect.toUpperCase(), style: AppTypography.mono),
        const SizedBox(height: 8),
        Text(
          l10n.stars_guideIntro,
          style: AppTypography.serif(
            fontSize: 15,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        const StarSegmentBar(segments: []),
        const SizedBox(height: 14),
        for (var i = 0; i < rows.length; i++)
          StarTypeRow(
            color: starSourceColor(rows[i].$1),
            label: rows[i].$2,
            outlined: true,
            muted: true,
            showDivider: i > 0,
            trailing: Text(
              rows[i].$3,
              style: AppTypography.bodyEmphasis.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}
