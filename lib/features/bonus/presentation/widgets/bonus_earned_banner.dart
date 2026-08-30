import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// The calm earned state once today's dailies are all done — no refill,
/// just a warm acknowledgement (functionality.md §12: "Both done · ✦N
/// today. New ones tomorrow.").
class BonusEarnedBanner extends StatelessWidget {
  const BonusEarnedBanner({required this.starsEarnedToday, super.key});

  final int starsEarnedToday;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.tint(AppColors.primary, .18),
            AppColors.tint(AppColors.accentCoral, .12),
          ],
        ),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.tint(AppColors.primary, .3)),
      ),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                AppGradients.primaryCta.createShader(bounds),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Both done · ✦$starsEarnedToday today',
                  style: AppTypography.bodyEmphasis,
                ),
                const SizedBox(height: 2),
                Text(
                  'New ones tomorrow.',
                  style: AppTypography.chipLabel.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
