import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/dashed_rrect_border.dart';

/// Dashed "+ Add a quest to Day N" footer. `docs/design/README.md` § 5.
class AddQuestRow extends StatelessWidget {
  const AddQuestRow({required this.dayNumber, required this.onTap, super.key});

  final int dayNumber;
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
            '+ Add a quest to Day $dayNumber',
            style: AppTypography.chipLabel.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
