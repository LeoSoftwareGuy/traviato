import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/bonus_tray_state.dart';
import 'bonus_template_text.dart';

/// A past-days completion row for the COMPLETED history section —
/// "COMPLETED · DAY N" per issue #64 AC.
class BonusCompletedRow extends StatelessWidget {
  const BonusCompletedRow({
    required this.task,
    required this.dayIndex,
    super.key,
  });

  final BonusTrayTask task;
  final int dayIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppColors.textTertiary,
            size: 16,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              bonusTemplateTitle(context.l10n, task.template),
              style: AppTypography.chipLabel.copyWith(
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.tint(AppColors.textTertiary, .12),
              borderRadius: AppRadius.badgeRadius,
            ),
            child: Text(
              (dayIndex > 0
                      ? context.l10n.bonus_completedDay(dayIndex)
                      : context.l10n.bonus_completed)
                  .toUpperCase(),
              style: AppTypography.mono,
            ),
          ),
        ],
      ),
    );
  }
}
