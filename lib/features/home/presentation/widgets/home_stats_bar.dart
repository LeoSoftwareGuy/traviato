import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/profile_stats_provider.dart';

/// Memories / Places / Days totals row (stubbed via [ProfileStats] until the
/// `profile_stats_view` migration lands).
class HomeStatsBar extends StatelessWidget {
  const HomeStatsBar({required this.stats, super.key});

  final ProfileStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.surfaceBorder),
        borderRadius: AppRadius.cardRadius,
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.auto_stories_outlined,
              tint: AppColors.primaryTint,
              iconColor: AppColors.primary,
              value: stats.memories,
              label: 'Memories',
              showDivider: true,
            ),
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.place_outlined,
              tint: AppColors.accentCoralTint,
              iconColor: AppColors.accentCoral,
              value: stats.places,
              label: 'Places',
              showDivider: true,
            ),
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.calendar_month_outlined,
              tint: AppColors.accentPurpleTint,
              iconColor: AppColors.accentPurple,
              value: stats.days,
              label: 'Days',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.tint,
    required this.iconColor,
    required this.value,
    required this.label,
    this.showDivider = false,
  });

  final IconData icon;
  final Color tint;
  final Color iconColor;
  final int value;
  final String label;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(right: BorderSide(color: AppColors.surfaceBorder))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: AppRadius.badgeRadius,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$value',
                style: AppTypography.headlineSerif.copyWith(fontSize: 18),
              ),
              Text(
                label,
                style: AppTypography.caption.copyWith(letterSpacing: 0),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
