import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/expense_sort_mode.dart';

/// Sort toggle pill — tapping flips between `Latest first` and `Biggest
/// spender` (`docs/design/README.md` § 8: "a sort pill '⇅ Latest first' ⇄
/// '⇅ Biggest spender'. Active sort = primary tint fill/border/text").
class ExpenseSortToggle extends StatelessWidget {
  const ExpenseSortToggle({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final ExpenseSortMode value;
  final ValueChanged<ExpenseSortMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final isActive = value == ExpenseSortMode.biggestSpender;
    final next = isActive
        ? ExpenseSortMode.latestFirst
        : ExpenseSortMode.biggestSpender;

    return InkWell(
      onTap: () => onChanged(next),
      borderRadius: AppRadius.pillRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryTint : AppColors.surface,
          border: Border.all(
            color: isActive
                ? AppColors.tint(AppColors.primary, .55)
                : AppColors.surfaceBorder,
          ),
          borderRadius: AppRadius.pillRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.swap_vert_rounded,
              size: 15,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              value.label,
              style: AppTypography.chipLabel.copyWith(
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
