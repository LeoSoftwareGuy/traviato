import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/expense_category.dart';
import 'expense_category_style.dart';
import 'expense_money_format.dart';

/// "BIGGEST CATEGORY" card under the selected memory's stats row — coral
/// wash, category icon tile, amount, and its share of the total
/// (`docs/design/README.md` § 8).
class ExpenseBiggestCategoryCard extends StatelessWidget {
  const ExpenseBiggestCategoryCard({
    required this.category,
    required this.amount,
    required this.totalAmount,
    super.key,
  });

  final ExpenseCategory category;
  final double amount;
  final double totalAmount;

  @override
  Widget build(BuildContext context) {
    final percent = totalAmount <= 0
        ? 0
        : ((amount / totalAmount) * 100).round();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.accentCoralTint,
        border: Border.all(color: AppColors.tint(AppColors.accentCoral, .3)),
        borderRadius: AppRadius.cardRadius,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: expenseCategoryTint(category),
              borderRadius: AppRadius.badgeRadius,
            ),
            child: Icon(
              expenseCategoryIcon(category),
              size: 16,
              color: expenseCategoryColor(category),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BIGGEST CATEGORY', style: AppTypography.mono),
                Text(
                  '${category.displayName} — ${formatEuro(amount)}',
                  style: AppTypography.headlineSerif.copyWith(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '$percent%',
            style: AppTypography.bodyEmphasis.copyWith(
              color: AppColors.accentCoral,
            ),
          ),
        ],
      ),
    );
  }
}
