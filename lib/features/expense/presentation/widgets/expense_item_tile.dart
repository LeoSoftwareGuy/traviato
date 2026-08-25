import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/expense_entity.dart';
import 'expense_category_style.dart';
import 'expense_money_format.dart';

/// One row of the selected memory's itemized expense list — zebra striped,
/// "DAY N · CATEGORY" subtitle (`docs/design/README.md` § 8, "ALL EXPENSES").
class ExpenseItemTile extends StatelessWidget {
  const ExpenseItemTile({
    required this.expense,
    required this.dayNumber,
    required this.isEven,
    super.key,
  });

  final ExpenseEntity expense;

  /// 1-based day-of-trip for [expense.spentOn]; null when the memory has no
  /// start date to compute it from.
  final int? dayNumber;
  final bool isEven;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isEven ? AppColors.tint(AppColors.surface, .55) : null,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: expenseCategoryTint(expense.category),
              borderRadius: AppRadius.badgeRadius,
            ),
            child: Icon(
              expenseCategoryIcon(expense.category),
              size: 14,
              color: expenseCategoryColor(expense.category),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: AppTypography.bodyEmphasis,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  dayNumber == null
                      ? expense.category.displayName.toUpperCase()
                      : 'DAY $dayNumber · '
                            '${expense.category.displayName.toUpperCase()}',
                  style: AppTypography.mono,
                ),
              ],
            ),
          ),
          Text(
            formatEuro(expense.amount),
            style: AppTypography.headlineSerif.copyWith(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
