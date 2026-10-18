import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/shrink_to_floor_text.dart';
import '../../domain/entities/profile_stats_entity.dart';

/// Memories / Places / Days totals — three plain cards, no icons.
/// `docs/design/README.md` § 3. Backed by `profile_stats_view` (#27, #77).
class HomeStatsBar extends StatelessWidget {
  const HomeStatsBar({required this.stats, super.key});

  final ProfileStatsEntity stats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: stats.memories,
            label: l10n.home_statMemories(stats.memories).toUpperCase(),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
            value: stats.places,
            label: l10n.home_statPlaces(stats.places).toUpperCase(),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
            value: stats.days,
            label: l10n.home_statDays(stats.days).toUpperCase(),
          ),
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
        // Matches the Plan/Expenses button fill on the hero card (#111).
        color: AppColors.surfaceDisabled,
        border: Border.all(color: AppColors.surfaceBorder),
        borderRadius: AppRadius.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$value', style: AppTypography.bigNumber.copyWith(fontSize: 23)),
          const SizedBox(height: AppSpacing.xs),
          // Spec 4t "Stat labels": tighter tracking, then down to 7.5px —
          // never an abbreviation.
          ShrinkToFloorText(
            label,
            minFontSize: 7.5,
            minLetterSpacing: 9.5 * .02,
            style: AppTypography.mono.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
