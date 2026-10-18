import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class _Step {
  const _Step({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;
}

List<_Step> _steps(AppLocalizations l10n) => [
  _Step(
    eyebrow: l10n.guest_stepBeforeEyebrow,
    title: l10n.guest_stepBeforeTitle,
    description: l10n.guest_stepBeforeBody,
  ),
  _Step(
    eyebrow: l10n.guest_stepDuringEyebrow,
    title: l10n.guest_stepDuringTitle,
    description: l10n.guest_stepDuringBody,
  ),
  _Step(
    eyebrow: l10n.guest_stepAfterEyebrow,
    title: l10n.guest_stepAfterTitle,
    description: l10n.guest_stepAfterBody,
  ),
];

/// "How it works" (#193): before / during / after cards, card 3
/// warm-highlighted as in `docs/design/README.md` § 1.
class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = _steps(context.l10n);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.guest_howTitle,
          style: AppTypography.screenTitle.copyWith(fontSize: 22, height: 1.25),
        ),
        const SizedBox(height: AppSpacing.base),
        for (var i = 0; i < steps.length; i++) ...[
          _HowItWorksCard(
            step: steps[i],
            highlighted: i == steps.length - 1,
          ),
          if (i < steps.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard({required this.step, required this.highlighted});

  final _Step step;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.tint(AppColors.primary, .1)
            : AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: highlighted
              ? AppColors.tint(AppColors.primary, .35)
              : AppColors.surfaceBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step.eyebrow.toUpperCase(),
            style: AppTypography.mono.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            step.title,
            style: AppTypography.screenTitle.copyWith(
              fontSize: 17,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            step.description,
            style: AppTypography.chipLabel.copyWith(
              fontSize: 12,
              height: 1.6,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
