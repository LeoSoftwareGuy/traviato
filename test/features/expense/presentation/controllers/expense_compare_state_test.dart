import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/expense/domain/entities/expense_category.dart';
import 'package:traviato/features/expense/presentation/controllers/expense_compare_state.dart';

import '../../fakes/fake_expense_repository.dart';

void main() {
  final iceland = buildExpenseSummaryEntity(tripId: 't1', tripName: 'Iceland');
  final santorini = buildExpenseSummaryEntity(
    tripId: 't2',
    tripName: 'Santorini',
  );

  group('hintLine', () {
    test('nothing picked', () {
      final state = ExpenseCompareState(summaries: [iceland, santorini]);
      expect(
        state.hintLine,
        'Pick two memories to put their spending side by side.',
      );
    });

    test('one picked', () {
      final state = ExpenseCompareState(
        summaries: [iceland, santorini],
        tripAId: 't1',
      );
      expect(state.hintLine, 'Now pick a second one.');
    });

    test('both picked', () {
      final state = ExpenseCompareState(
        summaries: [iceland, santorini],
        tripAId: 't1',
        tripBId: 't2',
      );
      expect(
        state.hintLine,
        'Iceland vs Santorini — tap either to swap it out.',
      );
    });
  });

  group('pairReady / isLoadingPair', () {
    test('false until both picks have their expenses loaded', () {
      const empty = ExpenseCompareState(summaries: []);
      expect(empty.pairReady, isFalse);

      final onePicked = empty.copyWith(tripAId: 't1');
      expect(onePicked.pairReady, isFalse);

      final bothPickedLoading = onePicked.copyWith(tripBId: 't2');
      expect(bothPickedLoading.pairReady, isTrue);
      expect(bothPickedLoading.isLoadingPair, isTrue);

      final bothLoaded = bothPickedLoading.copyWith(
        expensesA: const [],
        expensesB: const [],
      );
      expect(bothLoaded.isLoadingPair, isFalse);
    });
  });

  group('categoryTotals / categoriesPresent', () {
    test('only categories present on either side, in declaration order', () {
      final state = ExpenseCompareState(
        summaries: [iceland, santorini],
        tripAId: 't1',
        tripBId: 't2',
        expensesA: [
          buildExpenseEntity(category: ExpenseCategory.transport, amount: 50),
        ],
        expensesB: [
          buildExpenseEntity(category: ExpenseCategory.shopping, amount: 20),
        ],
      );

      expect(state.categoryTotalsA[ExpenseCategory.transport], 50);
      expect(state.categoryTotalsB[ExpenseCategory.shopping], 20);
      expect(
        state.categoriesPresent,
        [ExpenseCategory.transport, ExpenseCategory.shopping],
      );
    });
  });
}
