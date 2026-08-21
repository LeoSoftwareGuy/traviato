import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/expense/domain/entities/expense_category.dart';
import 'package:traviato/features/expense/presentation/controllers/expense_list_state.dart';
import 'package:traviato/features/expense/presentation/controllers/expense_sort_mode.dart';

import '../../fakes/fake_expense_repository.dart';

void main() {
  final iceland = buildExpenseSummaryEntity(
    tripId: 't1',
    tripName: 'Iceland ring road',
    totalAmount: 2280,
  );
  final santorini = buildExpenseSummaryEntity(
    tripId: 't2',
    tripName: 'Santorini blues',
    totalAmount: 1341,
  );
  final noExpenses = buildExpenseSummaryEntity(
    tripId: 't3',
    tripName: 'Alps ski week',
    totalAmount: 0,
    itemCount: 0,
  );

  group('visibleSummaries', () {
    test('sorts by biggest spender by default', () {
      final state = ExpenseListState(summaries: [santorini, iceland]);
      expect(
        state.visibleSummaries.map((s) => s.tripId),
        ['t1', 't2'], // Iceland (2280) before Santorini (1341)
      );
    });

    test('sorts alphabetically by name', () {
      final state = ExpenseListState(
        summaries: [iceland, santorini],
        sortMode: ExpenseSortMode.name,
      );
      expect(
        state.visibleSummaries.map((s) => s.tripId),
        ['t1', 't2'], // "Iceland" before "Santorini"
      );
    });

    test('filters by a case-insensitive search query', () {
      final state = ExpenseListState(
        summaries: [iceland, santorini],
        searchQuery: 'SANTO',
      );
      expect(state.visibleSummaries.map((s) => s.tripId), ['t2']);
    });

    test('an empty search query keeps every summary', () {
      final state = ExpenseListState(
        summaries: [iceland, santorini],
        searchQuery: '  ',
      );
      expect(state.visibleSummaries, hasLength(2));
    });
  });

  group('maxVisibleTotal', () {
    test('is the highest total among the visible rows', () {
      final state = ExpenseListState(summaries: [iceland, santorini]);
      expect(state.maxVisibleTotal, 2280);
    });

    test('is 0 when there are no visible summaries', () {
      const state = ExpenseListState(summaries: []);
      expect(state.maxVisibleTotal, 0);
    });

    test('respects the active search filter', () {
      final state = ExpenseListState(
        summaries: [iceland, santorini],
        searchQuery: 'santorini',
      );
      expect(state.maxVisibleTotal, 1341);
    });
  });

  group('spend bar proportion (via maxVisibleTotal)', () {
    test('a memory with the highest total reads as 100%', () {
      final state = ExpenseListState(summaries: [iceland, santorini]);
      final proportion = iceland.totalAmount / state.maxVisibleTotal;
      expect(proportion, 1.0);
    });

    test('a smaller total reads as its fraction of the max', () {
      final state = ExpenseListState(summaries: [iceland, santorini]);
      final proportion = santorini.totalAmount / state.maxVisibleTotal;
      expect(proportion, closeTo(1341 / 2280, 0.0001));
    });

    test('a memory with 0 expenses reads as 0%, not NaN', () {
      final state = ExpenseListState(summaries: [iceland, noExpenses]);
      final proportion = noExpenses.totalAmount / state.maxVisibleTotal;
      expect(proportion, 0.0);
    });
  });

  group('categoryTotals / biggestCategory', () {
    test('sums each category from the selected trip\'s expenses', () {
      final state = ExpenseListState(
        summaries: [iceland],
        selectedTripId: 't1',
        selectedTripExpenses: [
          buildExpenseEntity(category: ExpenseCategory.foodDrinks, amount: 50),
          buildExpenseEntity(category: ExpenseCategory.foodDrinks, amount: 30),
          buildExpenseEntity(category: ExpenseCategory.transport, amount: 200),
        ],
      );

      expect(state.categoryTotals[ExpenseCategory.foodDrinks], 80);
      expect(state.categoryTotals[ExpenseCategory.transport], 200);
      expect(state.categoryTotals[ExpenseCategory.accommodation], 0);
      expect(state.biggestCategory, ExpenseCategory.transport);
    });

    test('biggestCategory is null with no selected expenses', () {
      final state = ExpenseListState(
        summaries: [iceland],
        selectedTripId: 't1',
        selectedTripExpenses: const [],
      );
      expect(state.biggestCategory, isNull);
    });
  });

  group('pagination', () {
    test('hasMoreSelectedExpenses reflects the visible window', () {
      final expenses = List.generate(
        20,
        (i) => buildExpenseEntity(id: 'e$i'),
      );
      final state = ExpenseListState(
        summaries: [iceland],
        selectedTripId: 't1',
        selectedTripExpenses: expenses,
      );
      expect(state.visibleSelectedExpenses, hasLength(kExpenseListPageSize));
      expect(state.hasMoreSelectedExpenses, isTrue);

      final loaded = state.copyWith(
        visibleExpenseCount: kExpenseListPageSize + 20,
      );
      expect(loaded.visibleSelectedExpenses, hasLength(20));
      expect(loaded.hasMoreSelectedExpenses, isFalse);
    });
  });
}
