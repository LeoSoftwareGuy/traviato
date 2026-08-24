import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// `docs/design/README.md` § 1 — purple-wash testimonial card.
class TestimonialCard extends StatelessWidget {
  const TestimonialCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.tint(AppColors.accentPurple, .1),
        borderRadius: AppRadius.mediaRadius,
        border: Border.all(color: AppColors.tint(AppColors.accentPurple, .32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '"I stopped losing my trips to the camera roll. The wrap-up '
            'made me cry a little."',
            style: AppTypography.pullQuote,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                width: 21,
                height: 21,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.accentCoralTint,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  'MK',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.accentCoral,
                    letterSpacing: 0,
                    fontSize: 8,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Mira K. · 14 memories',
                style: AppTypography.chipLabel.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
