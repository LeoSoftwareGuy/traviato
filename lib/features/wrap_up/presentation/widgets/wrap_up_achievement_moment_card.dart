import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/wrap_up_achievement_moment.dart';

/// The badge-unlocked card. The caller only renders this when
/// [WrapUpEntity.achievementMoment] is non-null (docs/design/README.md § 12).
class WrapUpAchievementMomentCard extends StatelessWidget {
  const WrapUpAchievementMomentCard({required this.moment, super.key});

  final WrapUpAchievementMoment moment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: AppRadius.mediaRadius,
        border: Border.all(color: AppColors.tint(AppColors.primary, .35)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.tint(AppColors.primary, .16),
            AppColors.tint(AppColors.accentPurple, .14),
          ],
        ),
      ),
      child: Column(
        children: [
          Text('✦', style: AppTypography.bigNumber.copyWith(fontSize: 28)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${moment.title} unlocked',
            textAlign: TextAlign.center,
            style: AppTypography.displaySerif,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            moment.description,
            textAlign: TextAlign.center,
            style: AppTypography.chipLabel,
          ),
        ],
      ),
    );
  }
}
