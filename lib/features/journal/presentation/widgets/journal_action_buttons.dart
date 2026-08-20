import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// "View wrap-up" (visible but disabled until the wrap-up issues land) and
/// "To Do" (opens the day's quests).
class JournalActionButtons extends StatelessWidget {
  const JournalActionButtons({required this.onToDoTap, super.key});

  final VoidCallback onToDoTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.accentCoralTint,
            border: Border.all(
              color: AppColors.accentCoral.withValues(alpha: 0.3),
            ),
            borderRadius: AppRadius.badgeRadius,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.movie_creation_outlined,
                size: 16,
                color: AppColors.accentCoral,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'View wrap-up',
                style: AppTypography.chipLabel.copyWith(
                  color: AppColors.accentCoral,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          key: const Key('journal-to-do-action'),
          onPressed: onToDoTap,
          icon: const Icon(Icons.calendar_today_outlined, size: 16),
          label: const Text('To Do'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.surfaceBorder),
          ),
        ),
      ],
    );
  }
}
