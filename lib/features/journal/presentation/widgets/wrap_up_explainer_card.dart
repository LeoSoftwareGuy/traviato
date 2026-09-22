import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/journal_state.dart';

/// The locked wrap-up CTA's explainer card
/// (docs/design/M6_MONETIZATION_SPEC.md §6, #140) — content gate only, never
/// a paywall. Pro status has no effect on any of this; the closing line says
/// so verbatim.
class WrapUpExplainerCard extends StatelessWidget {
  const WrapUpExplainerCard({required this.state, super.key});

  final JournalState state;

  @override
  Widget build(BuildContext context) {
    final askLine = state.wrapUpAskLine;
    if (askLine == null) return const SizedBox.shrink();

    return Container(
      key: const Key('wrap-up-explainer-card'),
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.surfaceBorder),
        borderRadius: AppRadius.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your film needs a little more to work with. $askLine',
            style: AppTypography.bodyInput.copyWith(
              fontSize: 13,
              height: 1.55,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ChecklistRow(
            label: 'Five photos in this memory',
            have: state.wrapUpPhotosHave,
            need: JournalState.wrapUpMinPhotos,
            met: state.wrapUpPhotosMet,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ChecklistRow(
            label: 'At least one note written',
            have: state.wrapUpNotesHave,
            need: JournalState.wrapUpMinNotes,
            met: state.wrapUpNotesMet,
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.surfaceBorder),
          const SizedBox(height: AppSpacing.md),
          Text(
            "Nothing to buy — this one's the same on every plan.",
            style: AppTypography.caption.copyWith(
              fontSize: 10.5,
              height: 1.5,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.label,
    required this.have,
    required this.need,
    required this.met,
  });

  final String label;
  final int have;
  final int need;
  final bool met;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Ring(met: met),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyEmphasis.copyWith(
              fontSize: 12.5,
              color: met ? AppColors.textSecondary : AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          '$have / $need',
          style: AppTypography.mono.copyWith(
            fontSize: 10.5,
            color: met ? AppColors.primary : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.met});

  final bool met;

  @override
  Widget build(BuildContext context) {
    if (met) {
      return Container(
        width: 17,
        height: 17,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 12, color: AppColors.background),
      );
    }
    return Container(
      width: 17,
      height: 17,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
    );
  }
}
