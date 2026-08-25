import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// "X of Y packed" + a gradient fill bar that animates to its new width on
/// change. `docs/design/README.md` § 6.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$checkedCount of $totalCount packed',
            style: AppTypography.chipLabel.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: AppRadius.pillRadius,
          child: Container(
            height: 7,
            color: AppColors.surfaceBorder,
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: fraction),
              duration: AppMotion.progressDuration,
              curve: AppMotion.progressCurve,
              builder: (context, value, child) =>
                  FractionallySizedBox(widthFactor: value, child: child),
              child: const DecoratedBox(
                decoration: BoxDecoration(gradient: AppGradients.primaryCta),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
