import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Guest landing hero: value proposition + primary CTA. Uses a decorative
/// icon badge in place of the Figma hero photo (see #5 PR notes).
class GuestHeroCard extends StatelessWidget {
  const GuestHeroCard({required this.onStartNow, super.key});

  final VoidCallback onStartNow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mediaRadius,
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: AppRadius.badgeRadius,
            ),
            child: const Icon(Icons.auto_awesome, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.base),
          Text(
            'YOUR MEMORY COMPANION',
            style: AppTypography.caption.copyWith(
              color: AppColors.primary,
              letterSpacing: 2.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Every memory beautifully captured',
            style: AppTypography.displaySerif.copyWith(
              fontSize: 26,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No more messy folders. Trips, events, birthday weekends - '
            'your moments deserve more than a desktop dump.',
            style: AppTypography.chipLabel,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onStartNow,
              child: const Text('Start now'),
            ),
          ),
        ],
      ),
    );
  }
}
