import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/expense_category.dart';
import 'expense_category_style.dart';

/// Single-select category chips (Figma "add expenses" — 6 chips, 2 rows of
/// 3). Same selected/unselected chip language as `VibeChipGroup`, but each
/// category also gets its own accent color and icon.
class ExpenseCategoryChipGroup extends StatelessWidget {
  const ExpenseCategoryChipGroup({
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final ExpenseCategory selected;
  final ValueChanged<ExpenseCategory> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final category in ExpenseCategory.values)
          _CategoryChip(
            category: category,
            isSelected: category == selected,
            onTap: () => onSelect(category),
          ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final ExpenseCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = expenseCategoryColor(category);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.pillRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? expenseCategoryTint(category) : AppColors.surface,
          border: Border.all(
            color: isSelected ? accent : AppColors.surfaceBorder,
          ),
          borderRadius: AppRadius.pillRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(expenseCategoryIcon(category), size: 14, color: accent),
            const SizedBox(width: AppSpacing.xs),
            Text(
              category.displayName,
              style: AppTypography.chipLabel.copyWith(
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
