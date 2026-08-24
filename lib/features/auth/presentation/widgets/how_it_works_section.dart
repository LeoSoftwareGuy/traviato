import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class _Step {
  const _Step({required this.title, required this.description});

  final String title;
  final String description;
}

const _steps = [
  _Step(
    title: 'Capture the moment',
    description:
        'Photos, notes, and highlights — drop them in as you go. Works for '
        'a wedding weekend, a birthday trip, or just a really good Tuesday.',
  ),
  _Step(
    title: 'Stay organized, effortlessly',
    description:
        'For multi-day events, we\'ll keep each day tidy with prompts and '
        'structure. For single moments, jump right in — no folders needed.',
  ),
  _Step(
    title: 'Relive it all',
    description:
        'At the end, watch your entire memory line replay on a beautiful '
        'timeline — every photo, every note, every moment, in order.',
  ),
];

/// `docs/design/README.md` § 1 "How it works" — card 3 warm-highlighted.
class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How it works',
          style: AppTypography.screenTitle.copyWith(fontSize: 22),
        ),
        const SizedBox(height: AppSpacing.base),
        for (var i = 0; i < _steps.length; i++) ...[
          _HowItWorksCard(
            number: i + 1,
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
  const _HowItWorksCard({
    required this.number,
    required this.step,
    required this.highlighted,
  });

  final int number;
  final _Step step;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: AppRadius.badgeRadius,
            ),
            child: Text(
              '$number',
              style: AppTypography.buttonLabel.copyWith(
                fontSize: 12,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
          ),
        ],
      ),
    );
  }
}
