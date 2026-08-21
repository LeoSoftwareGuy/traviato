/// Sort options for the "Your spending" list. Only two — a third
/// "recent" option would need a last-expense-date column that doesn't exist
/// on `expense_summary_view` (see the #29 plan comment).
enum ExpenseSortMode {
  biggestSpender('Biggest spender'),
  name('Name');

  const ExpenseSortMode(this.label);

  final String label;
}
