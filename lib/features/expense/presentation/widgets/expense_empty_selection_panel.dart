import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/dashed_rrect_border.dart';

/// "Pick a memory above" prompt shown while no memory is selected
/// (`docs/design/README.md` § 8, "Empty state (nothing selected)").
class ExpenseEmptySelectionPanel extends StatelessWidget {
  const ExpenseEmptySelectionPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return DashedRRectBorder(
      color: AppColors.surfaceBorder,
      borderRadius: AppRadius.mediaRadius,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xxl,
          horizontal: AppSpacing.xl,
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            Text(
              '✦',
              style: AppTypography.bigNumber.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            Text('Pick a memory above', style: AppTypography.headlineSerif),
            const SizedBox(height: AppSpacing.xs),
            Text(
              "You'll see the total, where it went, and every expense as "
              'you logged it.',
              textAlign: TextAlign.center,
              style: AppTypography.chipLabel.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
