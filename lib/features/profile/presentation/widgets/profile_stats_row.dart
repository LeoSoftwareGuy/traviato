import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../home/domain/entities/profile_stats_entity.dart';

/// Memories · Countries · Days · Stars (`docs/design/README.md` § 11) —
/// distinct from Home's 3-stat bar (Memories · Places · Days), same
/// `ProfileStatsEntity` source.
class ProfileStatsRow extends StatelessWidget {
  const ProfileStatsRow({required this.stats, super.key});

  final ProfileStatsEntity stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(value: stats.memories, label: 'MEMORIES'),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(value: stats.countries, label: 'COUNTRIES'),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(value: stats.days, label: 'DAYS'),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(
            value: stats.stars,
            label: 'STARS',
            valueColor: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label, this.valueColor});

  final int value;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.surfaceBorder),
        borderRadius: AppRadius.cardRadius,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: AppTypography.bigNumber.copyWith(
              fontSize: 21,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.mono.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
