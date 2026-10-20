import 'package:flutter/material.dart';

import '../../../../core/constants/points_config.dart';
import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../trip/domain/entities/trip_card_entity.dart';
import '../../domain/entities/star_ledger_group_entity.dart';
import '../../domain/entities/star_summary.dart';
import 'star_breakdown_rows.dart';
import 'star_memory_row.dart';
import 'star_source_style.dart';

/// "Your stars" (#219 Phase 5a): the total, a bar and rows by type, then
/// the top three memories.
class StarSummaryBlock extends StatelessWidget {
  const StarSummaryBlock({
    required this.summary,
    required this.onMemoryTap,
    required this.onAllMemoriesTap,
    super.key,
  });

  static const visibleMemories = 3;

  final StarSummary summary;
  final ValueChanged<TripCardEntity> onMemoryTap;
  final VoidCallback onAllMemoriesTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final serif = AppTypography.serifIsLiterata;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.stars_yourStars.toUpperCase(), style: AppTypography.mono),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Text(
              '${summary.totalStars}',
              style: AppTypography.serif(
                fontSize: 54,
                height: 1,
                color: AppColors.primary,
              ),
            ),
            if (summary.memoryCount > 0)
              Padding(
                // Sits the smaller line on the big number's baseline.
                padding: EdgeInsets.only(bottom: serif ? 8 : 6),
                child: Text(
                  l10n.stars_acrossMemories(summary.memoryCount),
                  style: AppTypography.serif(
                    fontSize: 15,
                    height: 1.2,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        StarSegmentBar(
          segments: [
            for (final s in summary.bySource)
              (s.points, starSourceColor(s.source)),
          ],
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < summary.bySource.length; i++)
          _SourceRow(total: summary.bySource[i], showDivider: i > 0),
        if (summary.byMemory.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  l10n.stars_byMemory.toUpperCase(),
                  style: AppTypography.mono,
                ),
              ),
              if (summary.byMemory.length > visibleMemories)
                InkWell(
                  onTap: onAllMemoriesTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      l10n.stars_allMemories,
                      style: AppTypography.bodyEmphasis.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          for (final m in summary.byMemory.take(visibleMemories)) ...[
            StarMemoryRow(
              total: m,
              onTap: m.trip == null ? null : () => onMemoryTap(m.trip!),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.total, required this.showDivider});

  final StarSourceTotal total;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rate = switch (total.source) {
      StarSource.photo => PointsConfig.photo,
      StarSource.note => PointsConfig.note,
      StarSource.quest => PointsConfig.quest,
      // Bonus tasks vary in reward, so no single rate.
      StarSource.bonusTask => null,
    };
    return StarTypeRow(
      color: starSourceColor(total.source),
      label: starSourceLabel(l10n, total.source),
      detail: rate == null
          ? l10n.stars_bonusCount(total.count)
          : '${total.count} × ✦$rate',
      showDivider: showDivider,
      trailing: SizedBox(
        width: 44,
        child: Text(
          '${total.points}',
          textAlign: TextAlign.right,
          style: AppTypography.serif(
            fontSize: 16,
            height: 1.2,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
