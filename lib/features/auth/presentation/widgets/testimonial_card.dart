import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class TestimonialCard extends StatelessWidget {
  const TestimonialCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mediaRadius,
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: List.generate(
              5,
              (_) => const Padding(
                padding: EdgeInsets.only(right: AppSpacing.xs),
                child: Icon(Icons.star, color: AppColors.primary, size: 14),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '"I used to have a folder called \'Wedding photos FINAL\' on my '
            'desktop - you know the one. Now I just open Trevy, and my '
            'entire wedding weekend plays back in order: rehearsal dinner, '
            'ceremony, after-party. No folders, no chaos."',
            style: AppTypography.chipLabel.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
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
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Maya K.',
                style: AppTypography.chipLabel.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '· 3 memories captured',
                style: AppTypography.caption.copyWith(letterSpacing: 0),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
