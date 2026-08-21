import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/entities/expense_entity.dart';
import '../controllers/expense_list_controller.dart';
import '../providers/expense_providers.dart';

final addExpenseMutation = Mutation<ExpenseEntity>();

Future<ExpenseEntity> runAddExpense({
  required WidgetRef ref,
  required String tripId,
  required String title,
  required double amount,
  required ExpenseCategory category,
  required DateTime spentOn,
}) {
  return addExpenseMutation.run(ref, (tsx) async {
    final repo = tsx.get(expenseRepositoryProvider);
    final controller = tsx.get(expenseListControllerProvider.notifier);
    final result = await repo.addExpense(
      tripId: tripId,
      title: title,
      amount: amount,
      category: category,
      spentOn: spentOn,
    );
    return result.fold(
      (failure) => throw PresentationFailureException(failure),
      (
        expense,
      ) {
        controller.applyExpenseAdded(expense);
        return expense;
      },
    );
  });
}
