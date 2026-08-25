import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/dashed_rrect_border.dart';

/// Dashed "Load N more" row — same visual language as `AddQuestRow` /
/// `AddChecklistItemInput`. Used by both the Memories list and the
/// itemized expenses list (`docs/design/README.md` § 8).
class ExpenseLoadMoreRow extends StatelessWidget {
  const ExpenseLoadMoreRow({
    required this.label,
    required this.onTap,
    super.key,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.cardRadius,
      child: DashedRRectBorder(
        color: AppColors.tint(AppColors.primary, .7),
        borderRadius: AppRadius.cardRadius,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.chipLabel.copyWith(color: AppColors.textMuted),
          ),
        ),
      ),
    );
  }
}
