import 'package:equatable/equatable.dart';

import '../../domain/entities/expense_category.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/expense_summary_entity.dart';
import 'expense_sort_mode.dart';

/// How many of the selected memory's expenses are shown before "Load more".
const kExpenseListPageSize = 12;

/// How many rows of the "Memories" list are shown before "Load 3 more"
/// (`docs/design/README.md` § 8 — `shown` starts at 3, +3 per tap).
const kExpenseSummaryPageSize = 3;

class ExpenseListState extends Equatable {
  const ExpenseListState({
    required this.summaries,
    this.searchQuery = '',
    this.sortMode = ExpenseSortMode.latestFirst,
    this.visibleSummaryCount = kExpenseSummaryPageSize,
    this.selectedTripId,
    this.selectedTripExpenses,
    this.visibleExpenseCount = kExpenseListPageSize,
  });

  final List<ExpenseSummaryEntity> summaries;
  final String searchQuery;
  final ExpenseSortMode sortMode;
  final int visibleSummaryCount;
  final String? selectedTripId;

  /// Full expense list for [selectedTripId], loaded lazily on row tap. Null
  /// while nothing is selected yet or the detail fetch is in flight.
  final List<ExpenseEntity>? selectedTripExpenses;
  final int visibleExpenseCount;

  bool get isEmpty => summaries.isEmpty;

  /// Search-filtered and sorted, but not yet paged down to [visibleSummaryCount].
  List<ExpenseSummaryEntity> get matchingSummaries {
    final query = searchQuery.trim().toLowerCase();
    final filtered = query.isEmpty
        ? summaries
        : summaries
              .where((s) => s.tripName.toLowerCase().contains(query))
              .toList();
    switch (sortMode) {
      case ExpenseSortMode.latestFirst:
        return filtered;
      case ExpenseSortMode.biggestSpender:
        return [...filtered]
          ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    }
  }

  List<ExpenseSummaryEntity> get visibleSummaries =>
      matchingSummaries.take(visibleSummaryCount).toList();

  bool get hasMoreSummaries => visibleSummaryCount < matchingSummaries.length;

  /// Highest total across every memory (not just the visible/filtered ones)
  /// — the spend bar's proportion denominator. 0 when nothing has any
  /// expenses yet.
  double get maxTotalAmount => summaries.isEmpty
      ? 0
      : summaries.map((s) => s.totalAmount).reduce((a, b) => a > b ? a : b);

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

  /// [categoryTotals], descending — matches the "By category" bar order.
  List<MapEntry<ExpenseCategory, double>> get categoryTotalsSorted =>
      categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

  List<ExpenseEntity> get visibleSelectedExpenses =>
      (selectedTripExpenses ?? const []).take(visibleExpenseCount).toList();

  bool get hasMoreSelectedExpenses =>
      visibleExpenseCount < (selectedTripExpenses?.length ?? 0);

  /// 1-based day number of [date] within the selected memory, for the "DAY
  /// N · CATEGORY" row subtitle — null when the memory has no start date.
  int? dayNumberFor(DateTime date) {
    final start = selectedSummary?.startDate;
    if (start == null) return null;
    return date.difference(start).inDays + 1;
  }

  ExpenseListState copyWith({
    List<ExpenseSummaryEntity>? summaries,
    String? searchQuery,
    ExpenseSortMode? sortMode,
    int? visibleSummaryCount,
    String? selectedTripId,
    bool clearSelectedTripId = false,
    List<ExpenseEntity>? selectedTripExpenses,
    bool clearSelectedTripExpenses = false,
    int? visibleExpenseCount,
  }) => ExpenseListState(
    summaries: summaries ?? this.summaries,
    searchQuery: searchQuery ?? this.searchQuery,
    sortMode: sortMode ?? this.sortMode,
    visibleSummaryCount: visibleSummaryCount ?? this.visibleSummaryCount,
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
    visibleSummaryCount,
    sortMode,
    selectedTripId,
    selectedTripExpenses,
    visibleExpenseCount,
  ];
}
