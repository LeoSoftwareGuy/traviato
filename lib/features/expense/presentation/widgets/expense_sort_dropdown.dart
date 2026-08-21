import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/expense_sort_mode.dart';

/// Sort selector button (Figma "Biggest spender" pill + chevron).
class ExpenseSortDropdown extends StatelessWidget {
  const ExpenseSortDropdown({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final ExpenseSortMode value;
  final ValueChanged<ExpenseSortMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ExpenseSortMode>(
      initialValue: value,
      onSelected: onChanged,
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
      itemBuilder: (context) => [
        for (final mode in ExpenseSortMode.values)
          PopupMenuItem(
            value: mode,
            child: Text(
              mode.label,
              style: AppTypography.bodyInput.copyWith(
                color: mode == value
                    ? AppColors.primary
                    : AppColors.textPrimary,
              ),
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.surfaceBorder),
          borderRadius: AppRadius.cardRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.swap_vert_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(value.label, style: AppTypography.chipLabel),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
