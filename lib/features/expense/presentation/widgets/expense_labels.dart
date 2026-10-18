import '../../../../core/l10n/context_l10n.dart';
import '../../domain/entities/expense_category.dart';
import '../controllers/expense_sort_mode.dart';

/// UI label for an expense category (#220). The domain enum keeps its DB
/// value and English `displayName`; screens show this translation.
String expenseCategoryLabel(AppLocalizations l10n, ExpenseCategory c) =>
    switch (c) {
      ExpenseCategory.foodDrinks => l10n.expense_catFoodDrinks,
      ExpenseCategory.transport => l10n.expense_catTransport,
      ExpenseCategory.accommodation => l10n.expense_catAccommodation,
      ExpenseCategory.activities => l10n.expense_catActivities,
      ExpenseCategory.shopping => l10n.expense_catShopping,
      ExpenseCategory.other => l10n.expense_catOther,
    };

/// UI label for the Memories list sort toggle.
String expenseSortLabel(AppLocalizations l10n, ExpenseSortMode mode) =>
    switch (mode) {
      ExpenseSortMode.latestFirst => l10n.expense_sortLatest,
      ExpenseSortMode.biggestSpender => l10n.expense_sortBiggest,
    };
