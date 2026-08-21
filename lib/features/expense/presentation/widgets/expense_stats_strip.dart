import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/expense_category.dart';
import 'expense_category_style.dart';
import 'expense_money_format.dart';

/// Total spent / biggest category / per-day average tiles under the
/// selected memory (Figma "expenses" — "Total spent" / "Biggest category" /
/// "Per day").
class ExpenseStatsStrip extends StatelessWidget {
  const ExpenseStatsStrip({
    required this.totalAmount,
    required this.biggestCategory,
    required this.perDay,
    required this.durationDays,
    super.key,
  });

  final double totalAmount;
  final ExpenseCategory? biggestCategory;
  final double? perDay;
  final int? durationDays;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.savings_outlined,
            iconColor: AppColors.primary,
            iconTint: AppColors.primaryTint,
            label: 'Total spent',
            value: formatEuro(totalAmount),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(
            icon: biggestCategory == null
                ? Icons.category_outlined
                : expenseCategoryIcon(biggestCategory!),
            iconColor: biggestCategory == null
                ? AppColors.textMuted
                : expenseCategoryColor(biggestCategory!),
            iconTint: biggestCategory == null
                ? AppColors.surfaceBorder
                : expenseCategoryTint(biggestCategory!),
            label: 'Biggest category',
            value: biggestCategory?.displayName ?? '—',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(
            icon: Icons.calendar_today_outlined,
            iconColor: AppColors.accentPurple,
            iconTint: AppColors.accentPurpleTint,
            label: durationDays == null
                ? 'Per day'
                : 'Per day · $durationDays d',
            value: perDay == null ? '—' : formatEuro(perDay!),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.iconTint,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconTint;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.surfaceBorder),
        borderRadius: AppRadius.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconTint,
              borderRadius: AppRadius.badgeRadius,
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.caption.copyWith(letterSpacing: 0),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            value,
            style: AppTypography.bodyInput.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
