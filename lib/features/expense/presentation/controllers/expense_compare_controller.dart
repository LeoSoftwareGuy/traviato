import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../providers/expense_providers.dart';
import 'expense_compare_state.dart';

part 'expense_compare_controller.g.dart';

@riverpod
class ExpenseCompareController extends _$ExpenseCompareController {
  @override
  Future<ExpenseCompareState> build() async {
    final repo = ref.watch(expenseRepositoryProvider);
    final result = await repo.getSummaries();
    final summaries = result.fold(
      (failure) => throw PresentationFailureException(failure),
      (s) => s,
    );
    return ExpenseCompareState(summaries: summaries);
  }

  /// Selection rules (`docs/design/README.md` § 9): tap an unselected row →
  /// fills A, then B. Tap A → B is promoted to A, B clears. Tap B → clears
  /// B. Tap a third row when both are full → it becomes A and B clears.
  Future<void> selectTrip(String tripId) async {
    final current = state.value;
    if (current == null) return;

    if (tripId == current.tripAId) {
      // Promote B into A's slot. If B's expenses haven't finished loading
      // yet, expensesA must also go null (not fall back to the old A's
      // stale list) so the promoted pick shows as loading.
      state = AsyncData(
        current.copyWith(
          tripAId: current.tripBId,
          clearTripAId: current.tripBId == null,
          expensesA: current.expensesB,
          clearExpensesA: current.expensesB == null,
          clearTripBId: true,
          clearExpensesB: true,
        ),
      );
      return;
    }

    if (tripId == current.tripBId) {
      state = AsyncData(
        current.copyWith(clearTripBId: true, clearExpensesB: true),
      );
      return;
    }

    if (current.tripAId == null) {
      state = AsyncData(current.copyWith(tripAId: tripId));
      await _loadExpenses(tripId);
      return;
    }

    if (current.tripBId == null) {
      state = AsyncData(current.copyWith(tripBId: tripId));
      await _loadExpenses(tripId);
      return;
    }

    // Both full — the newly tapped row becomes A, B clears.
    state = AsyncData(
      current.copyWith(
        tripAId: tripId,
        clearExpensesA: true,
        clearTripBId: true,
        clearExpensesB: true,
      ),
    );
    await _loadExpenses(tripId);
  }

  /// Routes the fetch into whichever slot (A or B) currently holds [tripId]
  /// once it resolves — not the slot it was originally kicked off for, so a
  /// promotion (tapping A while B's fetch is still in flight) still lands
  /// correctly instead of being discarded.
  Future<void> _loadExpenses(String tripId) async {
    final repo = ref.read(expenseRepositoryProvider);
    final result = await repo.getExpensesForTrip(tripId);
    final current = state.value;
    if (current == null) return;
    final expenses = result.fold(
      (failure) => throw PresentationFailureException(failure),
      (e) => e,
    );
    if (current.tripAId == tripId) {
      state = AsyncData(current.copyWith(expensesA: expenses));
    } else if (current.tripBId == tripId) {
      state = AsyncData(current.copyWith(expensesB: expenses));
    }
    // else: the pick moved on (or was cleared) while this fetch was in
    // flight — discard.
  }

  void clearSelection() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        clearTripAId: true,
        clearExpensesA: true,
        clearTripBId: true,
        clearExpensesB: true,
      ),
    );
  }
}
