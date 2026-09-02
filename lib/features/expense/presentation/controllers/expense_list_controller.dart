import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../../../core/events/global_event.dart';
import '../../../../core/events/global_event_bus.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/expense_summary_entity.dart';
import '../providers/expense_providers.dart';
import 'expense_list_state.dart';
import 'expense_sort_mode.dart';

part 'expense_list_controller.g.dart';

@riverpod
class ExpenseListController extends _$ExpenseListController {
  @override
  Future<ExpenseListState> build() async {
    final sub = ref.watch(globalEventBusProvider).stream.listen(_onEvent);
    ref.onDispose(sub.cancel);

    final repo = ref.watch(expenseRepositoryProvider);
    final result = await repo.getSummaries();
    final summaries = result.fold(
      (failure) => throw PresentationFailureException(failure),
      (s) => s,
    );

    final initial = ExpenseListState(summaries: summaries);
    final visible = initial.visibleSummaries;
    if (visible.isEmpty) return initial;
    final defaultSelection = visible.first;

    final expensesResult = await repo.getExpensesForTrip(
      defaultSelection.tripId,
    );
    final expenses = expensesResult.fold(
      (failure) => throw PresentationFailureException(failure),
      (e) => e,
    );
    return initial.copyWith(
      selectedTripId: defaultSelection.tripId,
      selectedTripExpenses: expenses,
    );
  }

  void _onEvent(GlobalEvent event) {
    final current = state.value;
    if (current == null) return;
    switch (event) {
      case TripCreatedDispatched(:final trip):
        if (current.summaries.any((s) => s.tripId == trip.id)) return;
        final hadNoSelection = current.selectedTripId == null;
        state = AsyncData(
          current.copyWith(
            summaries: [
              ExpenseSummaryEntity(
                tripId: trip.id,
                tripName: trip.name,
                place: trip.destination,
                startDate: trip.startDate,
                durationDays: trip.durationDays,
                totalAmount: 0,
                itemCount: 0,
              ),
              ...current.summaries,
            ],
          ),
        );
        // The list was empty (nothing to select yet) — select the new
        // memory so its (empty) detail section renders, matching the
        // always-a-selection behavior of the initial load in build().
        if (hadNoSelection) unawaited(selectTrip(trip.id));
      case TripDeletedDispatched(:final tripId):
        final clearSelection = current.selectedTripId == tripId;
        state = AsyncData(
          current.copyWith(
            summaries: current.summaries
                .where((s) => s.tripId != tripId)
                .toList(),
            clearSelectedTripId: clearSelection,
            clearSelectedTripExpenses: clearSelection,
          ),
        );
      case TripUpdatedDispatched(:final trip):
        state = AsyncData(
          current.copyWith(
            summaries: [
              for (final s in current.summaries)
                if (s.tripId == trip.id)
                  ExpenseSummaryEntity(
                    tripId: trip.id,
                    tripName: trip.name,
                    place: trip.destination,
                    startDate: trip.startDate,
                    durationDays: trip.durationDays,
                    totalAmount: s.totalAmount,
                    itemCount: s.itemCount,
                  )
                else
                  s,
            ],
          ),
        );
      case StarsAwardedDispatched():
      case WrapUpPublishedDispatched():
      // Not relevant to expenses.
    }
  }

  void setSearchQuery(String query) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        searchQuery: query,
        visibleSummaryCount: kExpenseSummaryPageSize,
      ),
    );
  }

  void setSortMode(ExpenseSortMode mode) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        sortMode: mode,
        visibleSummaryCount: kExpenseSummaryPageSize,
      ),
    );
  }

  void loadMoreSummaries() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        visibleSummaryCount:
            current.visibleSummaryCount + kExpenseSummaryPageSize,
      ),
    );
  }

  Future<void> selectTrip(String tripId) async {
    final current = state.value;
    if (current == null || current.selectedTripId == tripId) return;
    state = AsyncData(
      current.copyWith(
        selectedTripId: tripId,
        clearSelectedTripExpenses: true,
        visibleExpenseCount: kExpenseListPageSize,
      ),
    );
    await _loadSelectedTripExpenses(tripId);
  }

  Future<void> _loadSelectedTripExpenses(String tripId) async {
    final repo = ref.read(expenseRepositoryProvider);
    final result = await repo.getExpensesForTrip(tripId);
    final current = state.value;
    // The selection may have moved on (or the controller disposed) while
    // this fetch was in flight.
    if (current == null || current.selectedTripId != tripId) return;
    final expenses = result.fold(
      (failure) => throw PresentationFailureException(failure),
      (e) => e,
    );
    state = AsyncData(current.copyWith(selectedTripExpenses: expenses));
  }

  void loadMoreExpenses() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        visibleExpenseCount: current.visibleExpenseCount + kExpenseListPageSize,
      ),
    );
  }

  /// Called by the add-expense mutation after a successful insert.
  void applyExpenseAdded(ExpenseEntity expense) {
    final current = state.value;
    if (current == null) return;

    final summaries = [
      for (final s in current.summaries)
        if (s.tripId == expense.tripId)
          ExpenseSummaryEntity(
            tripId: s.tripId,
            tripName: s.tripName,
            place: s.place,
            durationDays: s.durationDays,
            totalAmount: s.totalAmount + expense.amount,
            itemCount: s.itemCount + 1,
          )
        else
          s,
    ];

    final selectedExpenses = current.selectedTripId == expense.tripId
        ? ([expense, ...?current.selectedTripExpenses]..sort(
            (a, b) => b.spentOn.compareTo(a.spentOn),
          ))
        : current.selectedTripExpenses;

    state = AsyncData(
      current.copyWith(
        summaries: summaries,
        selectedTripExpenses: selectedExpenses,
      ),
    );
  }
}
