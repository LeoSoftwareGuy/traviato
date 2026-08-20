import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/checklist_category.dart';

/// Horizontally scrollable category pills, each showing "checked/total" —
/// same active/inactive treatment as `VibeChipGroup`.
class CategoryTabs extends StatelessWidget {
  const CategoryTabs({
    required this.selected,
    required this.countFor,
    required this.checkedCountFor,
    required this.onSelect,
    super.key,
  });

  final ChecklistCategory selected;
  final int Function(ChecklistCategory category) countFor;
  final int Function(ChecklistCategory category) checkedCountFor;
  final ValueChanged<ChecklistCategory> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 35,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ChecklistCategory.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final category = ChecklistCategory.values[index];
          return _CategoryTab(
            category: category,
            isSelected: category == selected,
            checked: checkedCountFor(category),
            total: countFor(category),
            onTap: () => onSelect(category),
          );
        },
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    required this.category,
    required this.isSelected,
    required this.checked,
    required this.total,
    required this.onTap,
  });

  final ChecklistCategory category;
  final bool isSelected;
  final int checked;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.pillRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
          ),
          borderRadius: AppRadius.pillRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              category.displayName,
              style: AppTypography.chipLabel.copyWith(
                color: isSelected
                    ? AppColors.background
                    : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '$checked/$total',
              style: AppTypography.caption.copyWith(
                color: isSelected
                    ? AppColors.background.withValues(alpha: 0.7)
                    : AppColors.textMuted,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
