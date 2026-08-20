import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// "X of Y packed" + percentage, with the fill bar underneath.
class ChecklistProgressBar extends StatelessWidget {
  const ChecklistProgressBar({
    required this.checkedCount,
    required this.totalCount,
    required this.progressPercent,
    super.key,
  });

  final int checkedCount;
  final int totalCount;
  final int progressPercent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$checkedCount of $totalCount packed',
              style: AppTypography.chipLabel.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            Text(
              '$progressPercent%',
              style: AppTypography.chipLabel.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: totalCount == 0 ? 0 : checkedCount / totalCount,
            minHeight: 6,
            backgroundColor: AppColors.surfaceBorder,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ],
    );
  }
}
