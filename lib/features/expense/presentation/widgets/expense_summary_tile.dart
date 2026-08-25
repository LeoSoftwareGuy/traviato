import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/expense_summary_entity.dart';
import 'expense_money_format.dart';

/// One "Memories" row: selection circle, name/place, total, duration ·
/// items, and a spend bar proportional to [maxTotal] (`docs/design/README.md`
/// § 8). Tapping selects the memory's detail drill-down below the list.
class ExpenseSummaryTile extends StatelessWidget {
  const ExpenseSummaryTile({
    required this.summary,
    required this.maxTotal,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final ExpenseSummaryEntity summary;
  final double maxTotal;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final barColor = isSelected ? AppColors.primary : AppColors.accentPurple;
    final proportion = maxTotal <= 0
        ? 0.0
        : (summary.totalAmount / maxTotal).clamp(0.0, 1.0);

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.cardRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.base,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.tint(AppColors.primary, .08)
              : AppColors.surface,
          border: Border.all(
            color: isSelected
                ? AppColors.tint(AppColors.primary, .55)
                : AppColors.surfaceBorder,
          ),
          borderRadius: AppRadius.cardRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SelectionCircle(isSelected: isSelected),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.tripName,
                        style: AppTypography.bodyEmphasis.copyWith(
                          fontSize: 13.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (summary.place != null)
                        Text(
                          summary.place!,
                          style: AppTypography.chipLabel.copyWith(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatEuro(summary.totalAmount),
                      style: AppTypography.bigNumber.copyWith(fontSize: 18),
                    ),
                    Text(
                      summary.durationDays == null
                          ? '${summary.itemCount} items'
                          : '${summary.durationDays}d · '
                                '${summary.itemCount} items',
                      style: AppTypography.mono,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: AppRadius.pillRadius,
              child: LinearProgressIndicator(
                value: proportion,
                minHeight: 5,
                backgroundColor: AppColors.surfaceBorder,
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionCircle extends StatelessWidget {
  const _SelectionCircle({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.tint(AppColors.primary, .28)
            : Colors.transparent,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
          width: 1.5,
        ),
        shape: BoxShape.circle,
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 14, color: AppColors.textOnPhoto)
          : null,
    );
  }
}
