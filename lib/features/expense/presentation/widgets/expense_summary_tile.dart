import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/expense_summary_entity.dart';
import 'expense_money_format.dart';

/// One "Your spending" row: name/place, total, duration · items, and a
/// spend bar proportional to [maxTotal] (Figma "expenses"). Tapping selects
/// the memory's detail drill-down below the list.
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
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
          ),
          borderRadius: AppRadius.cardRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: AppRadius.badgeRadius,
                  ),
                  child: const Icon(
                    Icons.place_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.tripName,
                        style: AppTypography.bodyInput.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (summary.place != null)
                        Text(
                          summary.place!,
                          style: AppTypography.caption.copyWith(
                            letterSpacing: 0,
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
                      style: AppTypography.bodyInput.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      summary.durationDays == null
                          ? '${summary.itemCount} items'
                          : '${summary.durationDays}d · '
                                '${summary.itemCount} items',
                      style: AppTypography.caption.copyWith(letterSpacing: 0),
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
                minHeight: 4,
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
