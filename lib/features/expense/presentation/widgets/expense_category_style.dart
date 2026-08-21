import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/expense_category.dart';

/// Icon + accent color per category (Figma "expenses" / "add expenses" —
/// the "By category" bars and chips reuse only 3 accents across the 6
/// categories: coral for food/shopping, orange for transport/activities,
/// purple for accommodation, muted gray for other). Kept out of the domain
/// entity since `IconData`/`Color` are Flutter types (docs/05-domain-layer.md).
IconData expenseCategoryIcon(ExpenseCategory category) {
  switch (category) {
    case ExpenseCategory.foodDrinks:
      return Icons.restaurant_outlined;
    case ExpenseCategory.transport:
      return Icons.directions_car_outlined;
    case ExpenseCategory.accommodation:
      return Icons.hotel_outlined;
    case ExpenseCategory.activities:
      return Icons.local_activity_outlined;
    case ExpenseCategory.shopping:
      return Icons.shopping_bag_outlined;
    case ExpenseCategory.other:
      return Icons.more_horiz;
  }
}

Color expenseCategoryColor(ExpenseCategory category) {
  switch (category) {
    case ExpenseCategory.foodDrinks:
    case ExpenseCategory.shopping:
      return AppColors.accentCoral;
    case ExpenseCategory.transport:
    case ExpenseCategory.activities:
      return AppColors.primary;
    case ExpenseCategory.accommodation:
      return AppColors.accentPurple;
    case ExpenseCategory.other:
      return AppColors.textMuted;
  }
}

Color expenseCategoryTint(ExpenseCategory category) {
  switch (category) {
    case ExpenseCategory.foodDrinks:
    case ExpenseCategory.shopping:
      return AppColors.accentCoralTint;
    case ExpenseCategory.transport:
    case ExpenseCategory.activities:
      return AppColors.primaryTint;
    case ExpenseCategory.accommodation:
      return AppColors.accentPurpleTint;
    case ExpenseCategory.other:
      return AppColors.surfaceBorder;
  }
}
