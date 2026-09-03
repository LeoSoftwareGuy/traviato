import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/achievement_entity.dart';
import 'achievement_badge_card.dart';

/// "N/M earned" header + 2-col grid (`docs/design/README.md` § 11), ordered
/// by `achievement_templates.position`.
class AchievementsGrid extends StatelessWidget {
  const AchievementsGrid({required this.achievements, super.key});

  final List<AchievementEntity> achievements;

  @override
  Widget build(BuildContext context) {
    final earnedCount = achievements.where((a) => a.isEarned).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'ACHIEVEMENTS',
              style: AppTypography.mono.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const Spacer(),
            Text(
              '$earnedCount/${achievements.length} earned',
              style: AppTypography.chipLabel.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.base),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.92,
          ),
          itemCount: achievements.length,
          itemBuilder: (context, index) =>
              AchievementBadgeCard(achievement: achievements[index]),
        ),
      ],
    );
  }
}
