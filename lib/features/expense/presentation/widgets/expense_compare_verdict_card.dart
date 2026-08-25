import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/expense_summary_entity.dart';
import 'expense_compare_verdict.dart';

/// Computed-sentence verdict card under the comparison table.
/// `docs/design/README.md` § 9.
class ExpenseCompareVerdictCard extends StatelessWidget {
  const ExpenseCompareVerdictCard({
    required this.a,
    required this.b,
    super.key,
  });

  final ExpenseSummaryEntity a;
  final ExpenseSummaryEntity b;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        border: Border.all(color: AppColors.tint(AppColors.primary, .32)),
        borderRadius: AppRadius.cardRadius,
      ),
      child: Text(
        buildCompareVerdict(a: a, b: b),
        style: AppTypography.chipLabel.copyWith(
          fontSize: 12,
          height: 1.6,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
