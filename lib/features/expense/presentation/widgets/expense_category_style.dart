import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/expense_category.dart';

/// Icon + accent color per category (`docs/design/README.md` § 8 — the
/// fixed 6-way mapping: Food & drinks coral, Transport purple, Accommodation
/// primary, Activities success, Shopping blue, Other neutral). Kept out of
/// the domain entity since `IconData`/`Color` are Flutter types
/// (docs/05-domain-layer.md).
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
      return AppColors.accentCoral;
    case ExpenseCategory.transport:
      return AppColors.accentPurple;
    case ExpenseCategory.accommodation:
      return AppColors.primary;
    case ExpenseCategory.activities:
      return AppColors.success;
    case ExpenseCategory.shopping:
      return AppColors.accentBlue;
    case ExpenseCategory.other:
      return AppColors.textSecondary;
  }
}

/// The category's accent at the ~10–18% alpha used for icon-chip fills and
/// card washes throughout the redesign.
Color expenseCategoryTint(ExpenseCategory category) {
  switch (category) {
    case ExpenseCategory.foodDrinks:
      return AppColors.accentCoralTint;
    case ExpenseCategory.transport:
      return AppColors.accentPurpleTint;
    case ExpenseCategory.accommodation:
      return AppColors.primaryTint;
    case ExpenseCategory.activities:
      return AppColors.tint(AppColors.success, .16);
    case ExpenseCategory.shopping:
      return AppColors.tint(AppColors.accentBlue, .16);
    case ExpenseCategory.other:
      return AppColors.tint(AppColors.textSecondary, .14);
  }
}
