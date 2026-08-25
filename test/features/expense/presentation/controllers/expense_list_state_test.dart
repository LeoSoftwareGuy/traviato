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

  group('matchingSummaries / visibleSummaries', () {
    test('latestFirst (default) does not re-sort', () {
      final state = ExpenseListState(summaries: [santorini, iceland]);
      expect(
        state.matchingSummaries.map((s) => s.tripId),
        ['t2', 't1'], // passthrough order, not by amount
      );
    });

    test('biggestSpender sorts by total descending', () {
      final state = ExpenseListState(
        summaries: [santorini, iceland],
        sortMode: ExpenseSortMode.biggestSpender,
      );
      expect(
        state.matchingSummaries.map((s) => s.tripId),
        ['t1', 't2'], // Iceland (2280) before Santorini (1341)
      );
    });

    test('filters by a case-insensitive search query', () {
      final state = ExpenseListState(
        summaries: [iceland, santorini],
        searchQuery: 'SANTO',
      );
      expect(state.matchingSummaries.map((s) => s.tripId), ['t2']);
    });

    test('an empty search query keeps every summary', () {
      final state = ExpenseListState(
        summaries: [iceland, santorini],
        searchQuery: '  ',
      );
      expect(state.matchingSummaries, hasLength(2));
    });

    test(
      'visibleSummaries pages matchingSummaries down to visibleSummaryCount',
      () {
        final state = ExpenseListState(
          summaries: [iceland, santorini, noExpenses],
          visibleSummaryCount: 2,
        );
        expect(state.visibleSummaries, hasLength(2));
        expect(state.hasMoreSummaries, isTrue);

        final loaded = state.copyWith(visibleSummaryCount: 3);
        expect(loaded.visibleSummaries, hasLength(3));
        expect(loaded.hasMoreSummaries, isFalse);
      },
    );
  });

  group('maxTotalAmount', () {
    test('is the highest total across every memory, filtered or not', () {
      final state = ExpenseListState(
        summaries: [iceland, santorini],
        searchQuery: 'santorini',
      );
      // Iceland's 2280 still wins even though the search filters it out of
      // matchingSummaries — the spend bar compares against the true max.
      expect(state.maxTotalAmount, 2280);
    });

    test('is 0 when there are no summaries', () {
      const state = ExpenseListState(summaries: []);
      expect(state.maxTotalAmount, 0);
    });
  });

  group('spend bar proportion (via maxTotalAmount)', () {
    test('a memory with the highest total reads as 100%', () {
      final state = ExpenseListState(summaries: [iceland, santorini]);
      final proportion = iceland.totalAmount / state.maxTotalAmount;
      expect(proportion, 1.0);
    });

    test('a smaller total reads as its fraction of the max', () {
      final state = ExpenseListState(summaries: [iceland, santorini]);
      final proportion = santorini.totalAmount / state.maxTotalAmount;
      expect(proportion, closeTo(1341 / 2280, 0.0001));
    });

    test('a memory with 0 expenses reads as 0%, not NaN', () {
      final state = ExpenseListState(summaries: [iceland, noExpenses]);
      final proportion = noExpenses.totalAmount / state.maxTotalAmount;
      expect(proportion, 0.0);
    });
  });

  group('categoryTotals / categoryTotalsSorted / biggestCategory', () {
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
      expect(
        state.categoryTotalsSorted.map((e) => e.key),
        [
          ExpenseCategory.transport,
          ExpenseCategory.foodDrinks,
          ExpenseCategory.accommodation,
          ExpenseCategory.activities,
          ExpenseCategory.shopping,
          ExpenseCategory.other,
        ],
      );
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

  group('dayNumberFor', () {
    test('is 1-based from the selected memory\'s start date', () {
      final trip = buildExpenseSummaryEntity(
        tripId: 't1',
        startDate: DateTime(2026, 3, 1),
      );
      final state = ExpenseListState(summaries: [trip], selectedTripId: 't1');
      expect(state.dayNumberFor(DateTime(2026, 3, 1)), 1);
      expect(state.dayNumberFor(DateTime(2026, 3, 3)), 3);
    });

    test('is null when the memory has no start date', () {
      final state = ExpenseListState(
        summaries: [iceland],
        selectedTripId: 't1',
      );
      expect(state.dayNumberFor(DateTime(2026, 3, 1)), isNull);
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
