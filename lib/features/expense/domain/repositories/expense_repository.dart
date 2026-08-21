import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/expense_category.dart';
import '../entities/expense_entity.dart';
import '../entities/expense_summary_entity.dart';

abstract interface class ExpenseRepository {
  /// One row per memory (trip_card_view + expense_summary_view), for the
  /// "Your spending" list.
  Future<Either<Failure, List<ExpenseSummaryEntity>>> getSummaries();

  /// Every expense of one trip, for the tapped-row detail drill-down and the
  /// memory selector's validation.
  Future<Either<Failure, List<ExpenseEntity>>> getExpensesForTrip(
    String tripId,
  );

  Future<Either<Failure, ExpenseEntity>> addExpense({
    required String tripId,
    required String title,
    required double amount,
    required ExpenseCategory category,
    required DateTime spentOn,
  });
}
