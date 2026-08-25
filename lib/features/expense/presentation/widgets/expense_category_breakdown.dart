import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/expense_category.dart';
import 'expense_category_style.dart';
import 'expense_money_format.dart';

/// "By category" section: one bar row per category, sorted descending,
/// proportional to the largest category total (`docs/design/README.md` § 8).
class ExpenseCategoryBreakdown extends StatelessWidget {
  const ExpenseCategoryBreakdown({required this.totals, super.key});

  /// Category → total, descending (see `ExpenseListState.categoryTotalsSorted`).
  final List<MapEntry<ExpenseCategory, double>> totals;

  @override
  Widget build(BuildContext context) {
    final maxTotal = totals.isEmpty
        ? 0.0
        : totals.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in totals) ...[
          _CategoryRow(
            category: entry.key,
            amount: entry.value,
            maxTotal: maxTotal,
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
    required this.maxTotal,
  });

  final ExpenseCategory category;
  final double amount;
  final double maxTotal;

  @override
  Widget build(BuildContext context) {
    final proportion = maxTotal <= 0 ? 0.0 : (amount / maxTotal).clamp(0, 1);
    final percent = maxTotal <= 0 ? 0 : (proportion * 100).round();
    final color = expenseCategoryColor(category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: expenseCategoryTint(category),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(
                expenseCategoryIcon(category),
                size: 12,
                color: color,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                category.displayName,
                style: AppTypography.chipLabel,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text('$percent%', style: AppTypography.mono),
            SizedBox(
              width: 50,
              child: Text(
                formatEuro(amount),
                textAlign: TextAlign.right,
                style: AppTypography.headlineSerif.copyWith(fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Padding(
          padding: const EdgeInsets.only(left: 31),
          child: ClipRRect(
            borderRadius: AppRadius.pillRadius,
            child: LinearProgressIndicator(
              value: proportion.toDouble(),
              minHeight: 5,
              backgroundColor: AppColors.surfaceBorder,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
      ],
    );
  }
}
