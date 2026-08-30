import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/profile_stats_entity.dart';

/// Memories / Places / Days totals — three plain cards, no icons.
/// `docs/design/README.md` § 3. Backed by `profile_stats_view` (#27, #77).
class HomeStatsBar extends StatelessWidget {
  const HomeStatsBar({required this.stats, super.key});

  final ProfileStatsEntity stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(value: stats.memories, label: 'MEMORIES'),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(value: stats.places, label: 'PLACES'),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(value: stats.days, label: 'DAYS'),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.base,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.surfaceBorder),
        borderRadius: AppRadius.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$value', style: AppTypography.bigNumber.copyWith(fontSize: 23)),
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
