import '../../domain/entities/expense_category.dart';
import '../models/expense_model.dart';

abstract interface class ExpenseRemoteDataSource {
  /// `trip_id -> item_count`, one entry per trip, from `expense_summary_view`.
  /// Merged with `trip_card_view` (via `TripRepository`) by the repository to
  /// build `ExpenseSummaryEntity` rows.
  Future<Map<String, int>> getExpenseItemCounts();

  Future<List<ExpenseModel>> getExpensesForTrip(String tripId);

  Future<ExpenseModel> addExpense({
    required String id,
    required String tripId,
    required String title,
    required double amount,
    required ExpenseCategory category,
    required DateTime spentOn,
  });
}
