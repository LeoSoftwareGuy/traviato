import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/rise_in.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/entities/expense_summary_entity.dart';
import '../controllers/expense_compare_state.dart';
import 'expense_category_style.dart';
import 'expense_money_format.dart';

const _columnWidth = 80.0;
const _washColor = Color(0xFF1D2248);

/// "FINANCIAL COMPARISON" table — category rows, then Total and Per day
/// rows. `docs/design/README.md` § 9.
class ExpenseCompareTable extends StatelessWidget {
  const ExpenseCompareTable({
    required this.state,
    required this.a,
    required this.b,
    super.key,
  });

  final ExpenseCompareState state;
  final ExpenseSummaryEntity a;
  final ExpenseSummaryEntity b;

  @override
  Widget build(BuildContext context) {
    final totalsA = state.categoryTotalsA;
    final totalsB = state.categoryTotalsB;

    return RiseIn(
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.surfaceBorder),
          borderRadius: AppRadius.mediaRadius,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Text('FINANCIAL COMPARISON', style: AppTypography.mono),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
              ),
              child: _HeaderRow(a: a, b: b),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final category in state.categoriesPresent)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base,
                  vertical: AppSpacing.xs,
                ),
                child: _CategoryRow(
                  category: category,
                  amountA: totalsA[category] ?? 0,
                  amountB: totalsB[category] ?? 0,
                ),
              ),
            const SizedBox(height: AppSpacing.xs),
            _TotalsRow(
              label: 'Total',
              valueA: formatEuro(a.totalAmount),
              valueB: formatEuro(b.totalAmount),
              valueStyle: AppTypography.bigNumber.copyWith(fontSize: 17),
              labelStyle: AppTypography.bodyEmphasis.copyWith(fontSize: 12.5),
            ),
            _TotalsRow(
              label: 'Per day',
              valueA: a.perDay == null ? '—' : formatEuro(a.perDay!),
              valueB: b.perDay == null ? '—' : formatEuro(b.perDay!),
              valueStyle: AppTypography.bigNumber.copyWith(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
              labelStyle: AppTypography.chipLabel.copyWith(
                fontSize: 11.5,
                color: AppColors.textMuted,
              ),
              accented: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.a, required this.b});

  final ExpenseSummaryEntity a;
  final ExpenseSummaryEntity b;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.chipLabel.copyWith(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      height: 1.25,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text('CATEGORY', style: AppTypography.mono),
        ),
        SizedBox(
          width: _columnWidth,
          child: Text(
            a.tripName,
            textAlign: TextAlign.right,
            style: style.copyWith(color: AppColors.primary),
          ),
        ),
        SizedBox(
          width: _columnWidth,
          child: Text(
            b.tripName,
            textAlign: TextAlign.right,
            style: style.copyWith(color: AppColors.accentPurpleLight),
          ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.amountA,
    required this.amountB,
  });

  final ExpenseCategory category;
  final double amountA;
  final double amountB;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          expenseCategoryIcon(category),
          size: 15,
          color: expenseCategoryColor(category),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            category.displayName,
            style: AppTypography.chipLabel,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(
          width: _columnWidth,
          child: _AmountText(amount: amountA, other: amountB),
        ),
        SizedBox(
          width: _columnWidth,
          child: _AmountText(amount: amountB, other: amountA),
        ),
      ],
    );
  }
}

class _AmountText extends StatelessWidget {
  const _AmountText({required this.amount, required this.other});

  final double amount;
  final double other;

  @override
  Widget build(BuildContext context) {
    if (amount <= 0) {
      return Text(
        '—',
        textAlign: TextAlign.right,
        style: AppTypography.headlineSerif.copyWith(
          fontSize: 15,
          color: AppColors.textTertiary,
        ),
      );
    }
    final isSmaller = other > amount;
    return Text(
      formatEuro(amount),
      textAlign: TextAlign.right,
      style: AppTypography.headlineSerif.copyWith(
        fontSize: 15,
        color: isSmaller ? AppColors.textTertiary : AppColors.textPrimary,
      ),
    );
  }
}

class _TotalsRow extends StatelessWidget {
  const _TotalsRow({
    required this.label,
    required this.valueA,
    required this.valueB,
    required this.valueStyle,
    required this.labelStyle,
    this.accented = true,
  });

  final String label;
  final String valueA;
  final String valueB;
  final TextStyle valueStyle;
  final TextStyle labelStyle;
  final bool accented;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.tint(_washColor, .5),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: labelStyle)),
          SizedBox(
            width: _columnWidth,
            child: Text(
              valueA,
              textAlign: TextAlign.right,
              style: accented
                  ? valueStyle.copyWith(color: AppColors.primary)
                  : valueStyle,
            ),
          ),
          SizedBox(
            width: _columnWidth,
            child: Text(
              valueB,
              textAlign: TextAlign.right,
              style: accented
                  ? valueStyle.copyWith(color: AppColors.accentPurpleLight)
                  : valueStyle,
            ),
          ),
        ],
      ),
    );
  }
}
