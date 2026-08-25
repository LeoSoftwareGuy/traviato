import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/features/expense/presentation/controllers/expense_compare_controller.dart';
import 'package:traviato/features/expense/presentation/providers/expense_providers.dart';

import '../../fakes/fake_expense_repository.dart';

ProviderContainer _buildContainer(FakeExpenseRepository repo) {
  return ProviderContainer(
    retry: (_, _) => null,
    overrides: [expenseRepositoryProvider.overrideWithValue(repo)],
  );
}

void main() {
  test('loads summaries with nothing selected', () async {
    final repo = FakeExpenseRepository()
      ..summariesResult = Right([
        buildExpenseSummaryEntity(tripId: 't1'),
        buildExpenseSummaryEntity(tripId: 't2'),
      ]);
    final container = _buildContainer(repo);
    addTearDown(container.dispose);

    final state = await container.read(
      expenseCompareControllerProvider.future,
    );

    expect(state.summaries, hasLength(2));
    expect(state.tripAId, isNull);
    expect(state.tripBId, isNull);
    expect(repo.getExpensesForTripCallCount, 0);
  });

  test('selectTrip fills A then B, fetching each lazily', () async {
    final repo = FakeExpenseRepository()
      ..summariesResult = Right([
        buildExpenseSummaryEntity(tripId: 't1'),
        buildExpenseSummaryEntity(tripId: 't2'),
      ])
      ..expensesForTripResult = const Right([]);
    final container = _buildContainer(repo);
    addTearDown(container.dispose);
    container.listen(expenseCompareControllerProvider, (_, _) {});
    await container.read(expenseCompareControllerProvider.future);
    final notifier = container.read(expenseCompareControllerProvider.notifier);

    await notifier.selectTrip('t1');
    var state = container.read(expenseCompareControllerProvider).value!;
    expect(state.tripAId, 't1');
    expect(state.tripBId, isNull);
    expect(state.expensesA, isNotNull);

    await notifier.selectTrip('t2');
    state = container.read(expenseCompareControllerProvider).value!;
    expect(state.tripAId, 't1');
    expect(state.tripBId, 't2');
    expect(state.expensesB, isNotNull);
    expect(repo.getExpensesForTripCallCount, 2);
  });

  test(
    'tapping A promotes B to A and clears B, reusing its expenses',
    () async {
      final repo = FakeExpenseRepository()
        ..summariesResult = Right([
          buildExpenseSummaryEntity(tripId: 't1'),
          buildExpenseSummaryEntity(tripId: 't2'),
        ])
        ..expensesForTripResult = Right([buildExpenseEntity(tripId: 't2')]);
      final container = _buildContainer(repo);
      addTearDown(container.dispose);
      container.listen(expenseCompareControllerProvider, (_, _) {});
      await container.read(expenseCompareControllerProvider.future);
      final notifier = container.read(
        expenseCompareControllerProvider.notifier,
      );

      await notifier.selectTrip('t1');
      await notifier.selectTrip('t2');
      expect(repo.getExpensesForTripCallCount, 2);

      // Tap A (t1) — B (t2) should be promoted into A's slot without a new
      // fetch, since t2's expenses are already loaded.
      await notifier.selectTrip('t1');
      final state = container.read(expenseCompareControllerProvider).value!;
      expect(state.tripAId, 't2');
      expect(state.tripBId, isNull);
      expect(state.expensesA!.single.tripId, 't2');
      expect(state.expensesB, isNull);
      expect(repo.getExpensesForTripCallCount, 2); // no extra fetch
    },
  );

  test('tapping A with no B clears A entirely', () async {
    final repo = FakeExpenseRepository()
      ..summariesResult = Right([buildExpenseSummaryEntity(tripId: 't1')])
      ..expensesForTripResult = const Right([]);
    final container = _buildContainer(repo);
    addTearDown(container.dispose);
    container.listen(expenseCompareControllerProvider, (_, _) {});
    await container.read(expenseCompareControllerProvider.future);
    final notifier = container.read(expenseCompareControllerProvider.notifier);

    await notifier.selectTrip('t1');
    await notifier.selectTrip('t1');

    final state = container.read(expenseCompareControllerProvider).value!;
    expect(state.tripAId, isNull);
    expect(state.expensesA, isNull);
  });

  test('tapping B clears only B', () async {
    final repo = FakeExpenseRepository()
      ..summariesResult = Right([
        buildExpenseSummaryEntity(tripId: 't1'),
        buildExpenseSummaryEntity(tripId: 't2'),
      ])
      ..expensesForTripResult = const Right([]);
    final container = _buildContainer(repo);
    addTearDown(container.dispose);
    container.listen(expenseCompareControllerProvider, (_, _) {});
    await container.read(expenseCompareControllerProvider.future);
    final notifier = container.read(expenseCompareControllerProvider.notifier);

    await notifier.selectTrip('t1');
    await notifier.selectTrip('t2');
    await notifier.selectTrip('t2');

    final state = container.read(expenseCompareControllerProvider).value!;
    expect(state.tripAId, 't1');
    expect(state.tripBId, isNull);
    expect(state.expensesB, isNull);
  });

  test(
    'tapping a third row when both are full replaces A and clears B',
    () async {
      final repo = FakeExpenseRepository()
        ..summariesResult = Right([
          buildExpenseSummaryEntity(tripId: 't1'),
          buildExpenseSummaryEntity(tripId: 't2'),
          buildExpenseSummaryEntity(tripId: 't3'),
        ])
        ..expensesForTripResult = const Right([]);
      final container = _buildContainer(repo);
      addTearDown(container.dispose);
      container.listen(expenseCompareControllerProvider, (_, _) {});
      await container.read(expenseCompareControllerProvider.future);
      final notifier = container.read(
        expenseCompareControllerProvider.notifier,
      );

      await notifier.selectTrip('t1');
      await notifier.selectTrip('t2');
      await notifier.selectTrip('t3');

      final state = container.read(expenseCompareControllerProvider).value!;
      expect(state.tripAId, 't3');
      expect(state.tripBId, isNull);
      expect(state.expensesA, isNotNull);
    },
  );

  test('clearSelection resets both picks', () async {
    final repo = FakeExpenseRepository()
      ..summariesResult = Right([
        buildExpenseSummaryEntity(tripId: 't1'),
        buildExpenseSummaryEntity(tripId: 't2'),
      ])
      ..expensesForTripResult = const Right([]);
    final container = _buildContainer(repo);
    addTearDown(container.dispose);
    container.listen(expenseCompareControllerProvider, (_, _) {});
    await container.read(expenseCompareControllerProvider.future);
    final notifier = container.read(expenseCompareControllerProvider.notifier);

    await notifier.selectTrip('t1');
    await notifier.selectTrip('t2');
    notifier.clearSelection();

    final state = container.read(expenseCompareControllerProvider).value!;
    expect(state.tripAId, isNull);
    expect(state.tripBId, isNull);
    expect(state.expensesA, isNull);
    expect(state.expensesB, isNull);
  });
}
