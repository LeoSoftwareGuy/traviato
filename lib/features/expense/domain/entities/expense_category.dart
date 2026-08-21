/// The 6 fixed expense categories (docs/data-model.md,
/// `expenses_category_check`). Order matches the Figma category-chip order
/// ("add expenses").
enum ExpenseCategory {
  foodDrinks('food_drinks', 'Food & Drinks'),
  transport('transport', 'Transport'),
  accommodation('accommodation', 'Accommodation'),
  activities('activities', 'Activities'),
  shopping('shopping', 'Shopping'),
  other('other', 'Other');

  const ExpenseCategory(this.dbValue, this.displayName);

  final String dbValue;
  final String displayName;

  static ExpenseCategory fromDbValue(String value) =>
      values.firstWhere((c) => c.dbValue == value);
}
