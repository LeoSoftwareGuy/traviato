import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/wrap_up_stat_chapter.dart';

/// Chapter three — "By the numbers": a 2-col grid of stat cards, each with a
/// bar that fills in on `barFill` (docs/design/README.md § 12). Bar colors
/// cycle through the accent set the design shows for the sample four cards.
class WrapUpStatChapterSection extends StatelessWidget {
  const WrapUpStatChapterSection({required this.chapter, super.key});

  final WrapUpStatChapter chapter;

  static const _barColors = [
    AppColors.primary,
    AppColors.accentCoral,
    AppColors.accentPurple,
    AppColors.primary,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CHAPTER THREE · BY THE NUMBERS',
          style: AppTypography.mono.copyWith(color: AppColors.primaryLight),
        ),
        const SizedBox(height: AppSpacing.base),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.35,
          ),
          itemCount: chapter.stats.length,
          itemBuilder: (context, index) => _StatCardTile(
            label: chapter.stats[index].label,
            value: chapter.stats[index].value,
            barColor: _barColors[index % _barColors.length],
          ),
        ),
      ],
    );
  }
}

class _StatCardTile extends StatelessWidget {
  const _StatCardTile({
    required this.label,
    required this.value,
    required this.barColor,
  });

  final String label;
  final String value;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value, style: AppTypography.bigNumber),
          Text(
            label.toUpperCase(),
            style: AppTypography.mono,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: AppRadius.pillRadius,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: AppMotion.barFillDuration,
              curve: AppMotion.barFillCurve,
              builder: (context, t, _) => LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    Container(height: 3, color: AppColors.surfaceBorder),
                    Container(
                      height: 3,
                      width: constraints.maxWidth * t,
                      color: barColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
