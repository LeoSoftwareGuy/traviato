import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/expense/domain/entities/expense_category.dart';
import 'package:traviato/features/expense/domain/entities/expense_entity.dart';
import 'package:traviato/features/expense/domain/entities/expense_summary_entity.dart';
import 'package:traviato/features/expense/domain/repositories/expense_repository.dart';

/// Test double for [ExpenseRepository]. Returns the configured result
/// (defaulting to an empty list/the passed args) and records calls.
class FakeExpenseRepository implements ExpenseRepository {
  Either<Failure, List<ExpenseSummaryEntity>>? summariesResult;
  Either<Failure, List<ExpenseEntity>>? expensesForTripResult;
  Either<Failure, ExpenseEntity>? addExpenseResult;
  var getSummariesCallCount = 0;
  var getExpensesForTripCallCount = 0;
  String? lastExpensesForTripId;
  Map<String, dynamic>? lastAddExpenseArgs;

  @override
  Future<Either<Failure, List<ExpenseSummaryEntity>>> getSummaries() async {
    getSummariesCallCount++;
    return summariesResult ?? const Right([]);
  }

  @override
  Future<Either<Failure, List<ExpenseEntity>>> getExpensesForTrip(
    String tripId,
  ) async {
    getExpensesForTripCallCount++;
    lastExpensesForTripId = tripId;
    return expensesForTripResult ?? const Right([]);
  }

  @override
  Future<Either<Failure, ExpenseEntity>> addExpense({
    required String tripId,
    required String title,
    required double amount,
    required ExpenseCategory category,
    required DateTime spentOn,
  }) async {
    lastAddExpenseArgs = {
      'tripId': tripId,
      'title': title,
      'amount': amount,
      'category': category,
      'spentOn': spentOn,
    };
    return addExpenseResult ??
        Right(
          buildExpenseEntity(
            tripId: tripId,
            title: title,
            amount: amount,
            category: category,
            spentOn: spentOn,
          ),
        );
  }
}

ExpenseSummaryEntity buildExpenseSummaryEntity({
  String tripId = 't1',
  String tripName = 'Iceland ring road',
  String? place = 'Vik, Iceland',
  DateTime? startDate,
  int? durationDays = 11,
  double totalAmount = 0,
  int itemCount = 0,
}) => ExpenseSummaryEntity(
  tripId: tripId,
  tripName: tripName,
  place: place,
  startDate: startDate,
  durationDays: durationDays,
  totalAmount: totalAmount,
  itemCount: itemCount,
);

ExpenseEntity buildExpenseEntity({
  String id = 'e1',
  String tripId = 't1',
  String title = 'Sunset dinner in Oia',
  double amount = 45.5,
  ExpenseCategory category = ExpenseCategory.foodDrinks,
  DateTime? spentOn,
  DateTime? createdAt,
}) {
  final date = spentOn ?? DateTime(2026, 1, 2);
  return ExpenseEntity(
    id: id,
    tripId: tripId,
    title: title,
    amount: amount,
    category: category,
    spentOn: date,
    createdAt: createdAt ?? date,
  );
}
