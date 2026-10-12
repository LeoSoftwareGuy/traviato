import 'package:flutter/material.dart';

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

const _steps = [
  _Step(
    eyebrow: 'THE BEFORE',
    title: "Plan the fun. We'll handle the details.",
    description:
        'Big weekend? Little adventure? Just a Tuesday worth remembering? '
        'Map out your plans, make your lists, and keep everything in one '
        'happy place.',
  ),
  _Step(
    eyebrow: 'THE DURING',
    title: 'Live it up. Jot it down.',
    description:
        'Snap photos, drop little notes, and take on surprise challenges '
        "along the way. The best memories aren't always the ones you planned.",
  ),
  _Step(
    eyebrow: 'THE AFTER',
    title: 'Good times deserve a replay.',
    description:
        'When the adventure ends, watch your moments come together in a '
        'personal highlight film. Relive the magic and keep the memories.',
  ),
];

/// "How it works" (#193): before / during / after cards, card 3
/// warm-highlighted as in `docs/design/README.md` § 1.
class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Make plans. Make memories. Make them last.',
          style: AppTypography.screenTitle.copyWith(fontSize: 22, height: 1.25),
        ),
        const SizedBox(height: AppSpacing.base),
        for (var i = 0; i < _steps.length; i++) ...[
          _HowItWorksCard(
            step: _steps[i],
            highlighted: i == _steps.length - 1,
          ),
          if (i < _steps.length - 1) const SizedBox(height: AppSpacing.md),
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
            step.eyebrow,
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
