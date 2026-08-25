import 'package:equatable/equatable.dart';

import '../../domain/entities/expense_category.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/expense_summary_entity.dart';

/// State for the Compare screen — a pair of memories (`tripAId`/`tripBId`)
/// and their lazily-fetched expense lists. `docs/design/README.md` § 9.
class ExpenseCompareState extends Equatable {
  const ExpenseCompareState({
    required this.summaries,
    this.tripAId,
    this.tripBId,
    this.expensesA,
    this.expensesB,
  });

  final List<ExpenseSummaryEntity> summaries;
  final String? tripAId;
  final String? tripBId;

  /// Null while that pick hasn't loaded its expenses yet (or nothing is
  /// picked for that slot).
  final List<ExpenseEntity>? expensesA;
  final List<ExpenseEntity>? expensesB;

  bool get isEmpty => summaries.isEmpty;
  bool get hasAnySelection => tripAId != null || tripBId != null;
  bool get pairReady => tripAId != null && tripBId != null;

  ExpenseSummaryEntity? get summaryA => _summaryFor(tripAId);
  ExpenseSummaryEntity? get summaryB => _summaryFor(tripBId);

  ExpenseSummaryEntity? _summaryFor(String? tripId) {
    if (tripId == null) return null;
    for (final s in summaries) {
      if (s.tripId == tripId) return s;
    }
    return null;
  }

  bool get isLoadingPair =>
      pairReady && (expensesA == null || expensesB == null);

  Map<ExpenseCategory, double> get categoryTotalsA =>
      _categoryTotals(expensesA);
  Map<ExpenseCategory, double> get categoryTotalsB =>
      _categoryTotals(expensesB);

  static Map<ExpenseCategory, double> _categoryTotals(
    List<ExpenseEntity>? expenses,
  ) {
    final list = expenses ?? const [];
    return {
      for (final category in ExpenseCategory.values)
        category: list
            .where((e) => e.category == category)
            .fold(0.0, (sum, e) => sum + e.amount),
    };
  }

  /// Categories with a nonzero total on either side, in declaration order —
  /// the rows of the "financial comparison" table.
  List<ExpenseCategory> get categoriesPresent {
    final totalsA = categoryTotalsA;
    final totalsB = categoryTotalsB;
    return [
      for (final category in ExpenseCategory.values)
        if ((totalsA[category] ?? 0) > 0 || (totalsB[category] ?? 0) > 0)
          category,
    ];
  }

  /// The 3-state hint line under the title.
  String get hintLine {
    final a = summaryA;
    final b = summaryB;
    if (a == null) {
      return 'Pick two memories to put their spending side by side.';
    }
    if (b == null) return 'Now pick a second one.';
    return '${a.tripName} vs ${b.tripName} — tap either to swap it out.';
  }

  ExpenseCompareState copyWith({
    List<ExpenseSummaryEntity>? summaries,
    String? tripAId,
    bool clearTripAId = false,
    String? tripBId,
    bool clearTripBId = false,
    List<ExpenseEntity>? expensesA,
    bool clearExpensesA = false,
    List<ExpenseEntity>? expensesB,
    bool clearExpensesB = false,
  }) => ExpenseCompareState(
    summaries: summaries ?? this.summaries,
    tripAId: clearTripAId ? null : (tripAId ?? this.tripAId),
    tripBId: clearTripBId ? null : (tripBId ?? this.tripBId),
    expensesA: clearExpensesA ? null : (expensesA ?? this.expensesA),
    expensesB: clearExpensesB ? null : (expensesB ?? this.expensesB),
  );

  @override
  List<Object?> get props => [
    summaries,
    tripAId,
    tripBId,
    expensesA,
    expensesB,
  ];
}
