import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/expense_entity.dart';
import 'expense_category_style.dart';
import 'expense_money_format.dart';

final _dateFormat = DateFormat('MMM d');

/// One row of the selected memory's itemized expense list (Figma
/// "expenses" — bottom "Expenses" section).
class ExpenseItemTile extends StatelessWidget {
  const ExpenseItemTile({required this.expense, super.key});

  final ExpenseEntity expense;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: expenseCategoryTint(expense.category),
              borderRadius: AppRadius.badgeRadius,
            ),
            child: Icon(
              expenseCategoryIcon(expense.category),
              size: 16,
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
                  style: AppTypography.bodyInput,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _dateFormat.format(expense.spentOn),
                  style: AppTypography.caption.copyWith(letterSpacing: 0),
                ),
              ],
            ),
          ),
          Text(
            formatEuro(expense.amount),
            style: AppTypography.bodyInput.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
