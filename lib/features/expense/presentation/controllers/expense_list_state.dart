import 'package:equatable/equatable.dart';

import '../../domain/entities/expense_category.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/expense_summary_entity.dart';
import 'expense_sort_mode.dart';

/// How many of the selected memory's expenses are shown before "Load more".
const kExpenseListPageSize = 12;

class ExpenseListState extends Equatable {
  const ExpenseListState({
    required this.summaries,
    this.searchQuery = '',
    this.sortMode = ExpenseSortMode.biggestSpender,
    this.selectedTripId,
    this.selectedTripExpenses,
    this.visibleExpenseCount = kExpenseListPageSize,
  });

  final List<ExpenseSummaryEntity> summaries;
  final String searchQuery;
  final ExpenseSortMode sortMode;
  final String? selectedTripId;

  /// Full expense list for [selectedTripId], loaded lazily on row tap. Null
  /// while nothing is selected yet or the detail fetch is in flight.
  final List<ExpenseEntity>? selectedTripExpenses;
  final int visibleExpenseCount;

  bool get isEmpty => summaries.isEmpty;

  List<ExpenseSummaryEntity> get visibleSummaries {
    final query = searchQuery.trim().toLowerCase();
    final filtered = query.isEmpty
        ? summaries
        : summaries
              .where((s) => s.tripName.toLowerCase().contains(query))
              .toList();
    final sorted = [...filtered];
    switch (sortMode) {
      case ExpenseSortMode.biggestSpender:
        sorted.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
      case ExpenseSortMode.name:
        sorted.sort(
          (a, b) =>
              a.tripName.toLowerCase().compareTo(b.tripName.toLowerCase()),
        );
    }
    return sorted;
  }

  /// Highest total among the visible rows — the spend bar's proportion
  /// denominator. 0 when every visible row has no expenses yet.
  double get maxVisibleTotal => visibleSummaries.isEmpty
      ? 0
      : visibleSummaries
            .map((s) => s.totalAmount)
            .reduce((a, b) => a > b ? a : b);

  ExpenseSummaryEntity? get selectedSummary {
    final id = selectedTripId;
    if (id == null) return null;
    for (final s in summaries) {
      if (s.tripId == id) return s;
    }
    return null;
  }

  bool get isLoadingSelectedTripExpenses =>
      selectedTripId != null && selectedTripExpenses == null;

  /// Per-category totals for the selected memory, in [ExpenseCategory]
  /// declaration order (matches the Figma "By category" row order).
  Map<ExpenseCategory, double> get categoryTotals {
    final expenses = selectedTripExpenses ?? const [];
    return {
      for (final category in ExpenseCategory.values)
        category: expenses
            .where((e) => e.category == category)
            .fold(0.0, (sum, e) => sum + e.amount),
    };
  }

  ExpenseCategory? get biggestCategory {
    final totals = categoryTotals;
    if ((selectedTripExpenses ?? const []).isEmpty) return null;
    return totals.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  List<ExpenseEntity> get visibleSelectedExpenses =>
      (selectedTripExpenses ?? const []).take(visibleExpenseCount).toList();

  bool get hasMoreSelectedExpenses =>
      visibleExpenseCount < (selectedTripExpenses?.length ?? 0);

  ExpenseListState copyWith({
    List<ExpenseSummaryEntity>? summaries,
    String? searchQuery,
    ExpenseSortMode? sortMode,
    String? selectedTripId,
    bool clearSelectedTripId = false,
    List<ExpenseEntity>? selectedTripExpenses,
    bool clearSelectedTripExpenses = false,
    int? visibleExpenseCount,
  }) => ExpenseListState(
    summaries: summaries ?? this.summaries,
    searchQuery: searchQuery ?? this.searchQuery,
    sortMode: sortMode ?? this.sortMode,
    selectedTripId: clearSelectedTripId
        ? null
        : (selectedTripId ?? this.selectedTripId),
    selectedTripExpenses: clearSelectedTripExpenses
        ? null
        : (selectedTripExpenses ?? this.selectedTripExpenses),
    visibleExpenseCount: visibleExpenseCount ?? this.visibleExpenseCount,
  );

  @override
  List<Object?> get props => [
    summaries,
    searchQuery,
    sortMode,
    selectedTripId,
    selectedTripExpenses,
    visibleExpenseCount,
  ];
}
