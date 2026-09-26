import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/journal_state.dart';
import 'wrap_up_explainer_card.dart';
import '../../../../core/widgets/app_snackbar.dart';

/// "To Do" (opens the day's quests) and "View wrap-up" (the gradient CTA,
/// docs/design/README.md § 8 — re-added now that M4-2 ships a real Wrap-up
/// screen; a #26 commit had previously removed it as a designer
/// miscommunication, before the wrap-up feature existed to link to).
///
/// The wrap-up CTA is gated by [wrapUpAvailability]: hidden while the trip
/// hasn't ended (#103), replaced by the inert locked variant + explainer
/// card once it's ended but under the content minimum
/// (docs/design/M6_MONETIZATION_SPEC.md §6, #140), and the active gradient
/// CTA once both conditions are met.
class JournalActionButtons extends StatelessWidget {
  const JournalActionButtons({
    required this.onToDoTap,
    required this.onViewWrapUpTap,
    required this.state,
    super.key,
  });

  final VoidCallback onToDoTap;
  final VoidCallback onViewWrapUpTap;
  final JournalState state;

  @override
  Widget build(BuildContext context) {
    final availability = state.wrapUpAvailability;
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
        if (availability == WrapUpAvailability.unlocked) ...[
          const SizedBox(height: AppSpacing.sm),
          _WrapUpCta(onTap: onViewWrapUpTap),
        ] else if (availability == WrapUpAvailability.locked) ...[
          const SizedBox(height: AppSpacing.sm),
          _WrapUpCtaLocked(askLine: state.wrapUpAskLine),
          const SizedBox(height: 11),
          WrapUpExplainerCard(state: state),
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
  const _WrapUpCtaLocked({required this.askLine});

  /// Shown as a tap-feedback toast (spec §6: "surfaces the requirement
  /// toast") — the explainer card beneath is already always visible, so
  /// there's nothing new to reveal; this is just acknowledgement.
  final String? askLine;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('journal-view-wrap-up-locked'),
        borderRadius: AppRadius.badgeRadius,
        onTap: askLine == null ? null : () => _showToast(context, askLine!),
        child: Container(
          width: double.infinity,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surfaceDisabled,
            border: Border.all(color: AppColors.surfaceBorder),
            borderRadius: AppRadius.badgeRadius,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 11,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                'View wrap-up',
                style: AppTypography.buttonLabel.copyWith(
                  fontSize: 12.5,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showToast(BuildContext context, String askLine) {
    showAppSnackbar(context, askLine);
  }
}
