import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class _Step {
  const _Step({
    required this.icon,
    required this.tint,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.number,
  });

  final IconData icon;
  final Color tint;
  final Color iconColor;
  final String title;
  final String description;
  final String number;
}

const _steps = [
  _Step(
    icon: Icons.camera_alt_outlined,
    tint: AppColors.primaryTint,
    iconColor: AppColors.primary,
    title: 'Capture the moment',
    description:
        'Photos, notes and highlights - drop them in as you go. Works for '
        'a family trip, wedding weekend, a birthday party or just a really '
        'good Tuesday.',
    number: '1',
  ),
  _Step(
    icon: Icons.map_outlined,
    tint: AppColors.accentCoralTint,
    iconColor: AppColors.accentCoral,
    title: 'Plan your trips',
    description:
        'Plan and organize your short or long trips with ease. Keep every '
        'day structured with helpful prompts and checklists - no folders '
        'needed.',
    number: '2',
  ),
  _Step(
    icon: Icons.movie_creation_outlined,
    tint: AppColors.accentPurpleTint,
    iconColor: AppColors.accentPurple,
    title: 'Relive it all',
    description:
        'At the end, watch your entire memory line replay on a beautiful '
        'timeline. Every photo, note and moment in order.',
    number: '3',
  ),
];

class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HOW IT WORKS',
          style: AppTypography.caption.copyWith(letterSpacing: 1.98),
        ),
        const SizedBox(height: AppSpacing.base),
        for (final step in _steps) ...[
          _HowItWorksCard(step: step),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard({required this.step});

  final _Step step;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: step.tint,
              borderRadius: AppRadius.badgeRadius,
            ),
            child: Icon(step.icon, color: step.iconColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.title, style: AppTypography.bodyInput),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  step.description,
                  style: AppTypography.chipLabel.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            step.number,
            style: AppTypography.displaySerif.copyWith(
              color: AppColors.surfaceBorder,
            ),
          ),
        ],
      ),
    );
  }
}
