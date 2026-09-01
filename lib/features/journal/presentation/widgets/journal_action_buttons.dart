import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// "To Do" (opens the day's quests) and "View wrap-up" (the gradient CTA,
/// docs/design/README.md § 8 — re-added now that M4-2 ships a real Wrap-up
/// screen; a #26 commit had previously removed it as a designer
/// miscommunication, before the wrap-up feature existed to link to).
class JournalActionButtons extends StatelessWidget {
  const JournalActionButtons({
    required this.onToDoTap,
    required this.onViewWrapUpTap,
    super.key,
  });

  final VoidCallback onToDoTap;
  final VoidCallback onViewWrapUpTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: AppRadius.badgeRadius,
          child: Material(
            color: Colors.transparent,
            child: Ink(
              decoration: const BoxDecoration(
                gradient: AppGradients.primaryCta,
              ),
              child: InkWell(
                key: const Key('journal-view-wrap-up-action'),
                onTap: onViewWrapUpTap,
                child: Container(
                  width: double.infinity,
                  height: 48,
                  alignment: Alignment.center,
                  child: Text(
                    'View wrap-up ▸',
                    style: AppTypography.buttonLabel.copyWith(
                      color: AppColors.background,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
