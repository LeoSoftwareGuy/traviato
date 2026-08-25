import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// A gradient fill bar next to its "X of Y packed" label, animating to its
/// new width on change. `docs/design/README.md` § 6.
class ChecklistProgressBar extends StatelessWidget {
  const ChecklistProgressBar({
    required this.checkedCount,
    required this.totalCount,
    super.key,
  });

  final int checkedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final fraction = totalCount == 0 ? 0.0 : checkedCount / totalCount;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: AppRadius.pillRadius,
            child: Container(
              height: 7,
              color: AppColors.surfaceBorder,
              alignment: Alignment.centerLeft,
              child: LayoutBuilder(
                builder: (context, constraints) => AnimatedContainer(
                  duration: AppMotion.progressDuration,
                  curve: AppMotion.progressCurve,
                  width: constraints.maxWidth * fraction,
                  height: 7,
                  decoration: const BoxDecoration(
                    gradient: AppGradients.primaryCta,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$checkedCount of $totalCount packed',
          style: AppTypography.chipLabel.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
