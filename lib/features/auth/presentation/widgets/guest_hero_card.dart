import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'guest_images.dart';

/// Guest landing hero: photo backdrop with a bottom scrim so the value
/// proposition + primary CTA stay readable, matching the Figma hero frame.
class GuestHeroCard extends StatelessWidget {
  const GuestHeroCard({required this.onStartNow, super.key});

  final VoidCallback onStartNow;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.mediaRadius,
      child: SizedBox(
        height: 380,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(GuestImages.hero, fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.backgroundScrim,
                    AppColors.background,
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
                      color: AppColors.textOnPhoto,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'No more messy folders. Trips, events, birthday weekends - '
                    'your moments deserve more than a desktop dump.',
                    style: AppTypography.chipLabel.copyWith(
                      color: AppColors.textOnPhotoMuted,
                    ),
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
            ),
          ],
        ),
      ),
    );
  }
}
