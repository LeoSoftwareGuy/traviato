import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/expense_category.dart';
import 'expense_category_style.dart';
import 'expense_money_format.dart';

/// "By category" section: one bar row per category, proportional to
/// [totalAmount] (Figma "expenses").
class ExpenseCategoryBreakdown extends StatelessWidget {
  const ExpenseCategoryBreakdown({
    required this.totals,
    required this.totalAmount,
    super.key,
  });

  final Map<ExpenseCategory, double> totals;
  final double totalAmount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final category in ExpenseCategory.values) ...[
          _CategoryRow(
            category: category,
            amount: totals[category] ?? 0,
            totalAmount: totalAmount,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.amount,
    required this.totalAmount,
  });

  final ExpenseCategory category;
  final double amount;
  final double totalAmount;

  @override
  Widget build(BuildContext context) {
    final proportion = totalAmount <= 0
        ? 0.0
        : (amount / totalAmount).clamp(0.0, 1.0);
    final percent = (proportion * 100).round();

    return Row(
      children: [
        Icon(
          expenseCategoryIcon(category),
          size: 16,
          color: expenseCategoryColor(category),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 96,
          child: Text(
            category.displayName,
            style: AppTypography.chipLabel,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: AppRadius.pillRadius,
            child: LinearProgressIndicator(
              value: proportion,
              minHeight: 6,
              backgroundColor: AppColors.surfaceBorder,
              valueColor: AlwaysStoppedAnimation(
                expenseCategoryColor(category),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 64,
          child: Text(
            '${formatEuro(amount)} · $percent%',
            textAlign: TextAlign.right,
            style: AppTypography.caption.copyWith(letterSpacing: 0),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
