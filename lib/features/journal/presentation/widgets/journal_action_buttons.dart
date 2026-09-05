import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/journal_state.dart';

/// "To Do" (opens the day's quests) and "View wrap-up" (the gradient CTA,
/// docs/design/README.md § 8 — re-added now that M4-2 ships a real Wrap-up
/// screen; a #26 commit had previously removed it as a designer
/// miscommunication, before the wrap-up feature existed to link to).
///
/// The wrap-up CTA is gated by [wrapUpAvailability] (#103): hidden while
/// the trip hasn't ended, disabled with [wrapUpLockedReason] once it's
/// ended but under the content minimum, and the active gradient CTA once
/// both conditions are met.
class JournalActionButtons extends StatelessWidget {
  const JournalActionButtons({
    required this.onToDoTap,
    required this.onViewWrapUpTap,
    required this.wrapUpAvailability,
    this.wrapUpLockedReason,
    super.key,
  });

  final VoidCallback onToDoTap;
  final VoidCallback onViewWrapUpTap;
  final WrapUpAvailability wrapUpAvailability;
  final String? wrapUpLockedReason;

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
        if (wrapUpAvailability == WrapUpAvailability.unlocked) ...[
          const SizedBox(height: AppSpacing.sm),
          _WrapUpCta(onTap: onViewWrapUpTap),
        ] else if (wrapUpAvailability == WrapUpAvailability.locked) ...[
          const SizedBox(height: AppSpacing.sm),
          const _WrapUpCtaLocked(),
          if (wrapUpLockedReason != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              wrapUpLockedReason!,
              textAlign: TextAlign.center,
              style: AppTypography.caption,
            ),
          ],
        ],
      ],
    );
  }
}

class _WrapUpCta extends StatelessWidget {
  const _WrapUpCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.badgeRadius,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: const BoxDecoration(gradient: AppGradients.primaryCta),
          child: InkWell(
            key: const Key('journal-view-wrap-up-action'),
            onTap: onTap,
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
    );
  }
}

class _WrapUpCtaLocked extends StatelessWidget {
  const _WrapUpCtaLocked();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('journal-view-wrap-up-locked'),
      width: double.infinity,
      height: 48,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.surfaceDisabled,
        borderRadius: AppRadius.badgeRadius,
      ),
      child: Text(
        'View wrap-up ▸',
        style: AppTypography.buttonLabel.copyWith(
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}
