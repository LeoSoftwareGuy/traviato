import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'expense_money_format.dart';

/// Total spent / per-day average tiles under the selected memory
/// (`docs/design/README.md` § 8 — "Biggest category" is its own full-width
/// card, see [ExpenseBiggestCategoryCard]).
class ExpenseStatsStrip extends StatelessWidget {
  const ExpenseStatsStrip({
    required this.totalAmount,
    required this.perDay,
    required this.durationDays,
    super.key,
  });

  final double totalAmount;
  final double? perDay;
  final int? durationDays;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: _StatCard(
            label: 'TOTAL SPENT',
            value: formatEuro(totalAmount),
            emphasized: true,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 4,
          child: _StatCard(
            label: durationDays == null
                ? 'PER DAY AVG'
                : 'PER DAY AVG · $durationDays D',
            value: perDay == null ? '—' : formatEuro(perDay!),
            emphasized: false,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.emphasized,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: emphasized ? AppColors.primaryTint : AppColors.surface,
        border: Border.all(
          color: emphasized
              ? AppColors.tint(AppColors.primary, .32)
              : AppColors.surfaceBorder,
        ),
        borderRadius: AppRadius.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.mono,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.bigNumber.copyWith(
              fontSize: emphasized ? 29 : 22,
              color: emphasized ? AppColors.primary : AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
