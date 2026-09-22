import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/dashed_rrect_border.dart';

/// Replaces the note card + photo strip for a Journal day with zero photos
/// and zero notes (docs/design/M6_MONETIZATION_SPEC.md §7, #140). A nudge,
/// never a scold: no modal, doesn't block navigation, and (per the design's
/// own test matrix) looks identical for free and Pro users — no upsell here.
class EmptyDayNudge extends StatelessWidget {
  const EmptyDayNudge({
    required this.dayNumber,
    required this.onAddPhoto,
    required this.onWriteNote,
    super.key,
  });

  final int dayNumber;
  final VoidCallback onAddPhoto;
  final VoidCallback onWriteNote;

  @override
  Widget build(BuildContext context) {
    return DashedRRectBorder(
      key: const Key('empty-day-nudge'),
      color: AppColors.textSecondary.withValues(alpha: 0.26),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.tint(AppColors.primary, 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '✦',
                style: TextStyle(color: AppColors.primary, fontSize: 15),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Nothing from Day $dayNumber yet',
              style: AppTypography.headlineSerif.copyWith(fontSize: 17),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Even one photo helps your wrap-up. Quiet days still make the '
              'film — this one will just pass through it.',
              style: AppTypography.chipLabel.copyWith(
                fontSize: 12,
                height: 1.6,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('empty-day-nudge-add-photo'),
                    onPressed: onAddPhoto,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.tint(AppColors.primary, 0.14),
                      side: BorderSide(
                        color: AppColors.tint(AppColors.primary, 0.4),
                      ),
                      foregroundColor: AppColors.primary,
                    ),
                    child: const Text('＋ Add a photo'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    key: const Key('empty-day-nudge-write-note'),
                    onPressed: onWriteNote,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.surfaceBorder),
                    ),
                    child: const Text('Write a note'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
