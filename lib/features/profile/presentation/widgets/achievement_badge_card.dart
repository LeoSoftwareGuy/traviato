import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/achievement_entity.dart';

/// One achievement tile — filled/earned or dimmed/locked-with-progress
/// (`docs/design/README.md` § 11). No per-badge icon in the data model, so
/// every tile uses the same trophy glyph, tinted by state.
class AchievementBadgeCard extends StatelessWidget {
  const AchievementBadgeCard({required this.achievement, super.key});

  final AchievementEntity achievement;

  @override
  Widget build(BuildContext context) {
    final earned = achievement.isEarned;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: earned
            ? AppColors.surface
            : AppColors.tint(AppColors.surface, .45),
        border: Border.all(
          color: earned
              ? AppColors.tint(AppColors.primary, .28)
              : AppColors.surfaceBorder,
        ),
        borderRadius: AppRadius.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: earned
                  ? AppColors.tint(AppColors.primary, .18)
                  : AppColors.tint(AppColors.textTertiary, .12),
              borderRadius: AppRadius.badgeRadius,
            ),
            child: Icon(
              Icons.emoji_events_outlined,
              size: 20,
              color: earned ? AppColors.primary : AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            achievement.title,
            style: AppTypography.headlineSerif.copyWith(
              fontSize: 15,
              height: 1.2,
              color: earned ? AppColors.textPrimary : AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            achievement.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(letterSpacing: 0),
          ),
          if (!earned) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: AppRadius.pillRadius,
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    Container(height: 4, color: AppColors.surfaceBorder),
                    Container(
                      height: 4,
                      width: constraints.maxWidth * achievement.progress,
                      color: AppColors.accentPurple,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(achievement.progressLabel, style: AppTypography.mono),
          ],
        ],
      ),
    );
  }
}
