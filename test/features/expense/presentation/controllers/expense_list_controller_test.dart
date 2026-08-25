import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/events/global_event.dart';
import 'package:traviato/core/events/global_event_bus.dart';
import 'package:traviato/features/expense/presentation/controllers/expense_list_controller.dart';
import 'package:traviato/features/expense/presentation/providers/expense_providers.dart';
import 'package:traviato/features/trip/domain/entities/trip_card_entity.dart';

import '../../fakes/fake_expense_repository.dart';

ProviderContainer _buildContainer(
  FakeExpenseRepository repo, {
  GlobalEventBus? bus,
}) {
  return ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      expenseRepositoryProvider.overrideWithValue(repo),
      if (bus != null) globalEventBusProvider.overrideWithValue(bus),
    ],
  );
}

void main() {
  test(
    'loads summaries and selects the first one (latestFirst default)',
    () async {
      final repo = FakeExpenseRepository()
        ..summariesResult = Right([
          buildExpenseSummaryEntity(tripId: 't1', totalAmount: 100),
          buildExpenseSummaryEntity(tripId: 't2', totalAmount: 900),
        ])
        ..expensesForTripResult = Right([buildExpenseEntity(tripId: 't1')]);
      final container = _buildContainer(repo);
      addTearDown(container.dispose);

      final state = await container.read(
        expenseListControllerProvider.future,
      );

      expect(state.summaries, hasLength(2));
      // latestFirst does no re-sort — the first summary as returned wins,
      // regardless of amount.
      expect(state.selectedTripId, 't1');
      expect(repo.lastExpensesForTripId, 't1');
      expect(state.selectedTripExpenses, hasLength(1));
    },
  );

  test('does not select anything when there are no memories', () async {
    final repo = FakeExpenseRepository()..summariesResult = const Right([]);
    final container = _buildContainer(repo);
    addTearDown(container.dispose);

    final state = await container.read(expenseListControllerProvider.future);

    expect(state.isEmpty, isTrue);
    expect(state.selectedTripId, isNull);
    expect(repo.getExpensesForTripCallCount, 0);
  });

  test('selectTrip loads that trip\'s expenses lazily', () async {
    final repo = FakeExpenseRepository()
      ..summariesResult = Right([
        buildExpenseSummaryEntity(tripId: 't1', totalAmount: 100),
        buildExpenseSummaryEntity(tripId: 't2', totalAmount: 50),
      ])
      ..expensesForTripResult = Right([buildExpenseEntity(tripId: 't2')]);
    final container = _buildContainer(repo);
    addTearDown(container.dispose);
    container.listen(expenseListControllerProvider, (_, _) {});

    await container.read(expenseListControllerProvider.future);
    expect(repo.getExpensesForTripCallCount, 1); // default selection (t1)

    final notifier = container.read(expenseListControllerProvider.notifier);
    await notifier.selectTrip('t2');

    expect(repo.getExpensesForTripCallCount, 2);
    expect(repo.lastExpensesForTripId, 't2');
    final state = container.read(expenseListControllerProvider).value!;
    expect(state.selectedTripId, 't2');
    expect(state.selectedTripExpenses!.single.tripId, 't2');
  });

  test(
    'TripCreatedDispatched prepends a zero-expense summary and selects it '
    'when nothing was selected yet',
    () async {
      final repo = FakeExpenseRepository()
        ..summariesResult = const Right([])
        ..expensesForTripResult = const Right([]);
      final bus = GlobalEventBus();
      addTearDown(bus.dispose);
      final container = _buildContainer(repo, bus: bus);
      addTearDown(container.dispose);
      container.listen(expenseListControllerProvider, (_, _) {});

      final loaded = await container.read(
        expenseListControllerProvider.future,
      );
      expect(loaded.selectedTripId, isNull); // nothing to select yet

      bus.add(
        TripCreatedDispatched(
          trip: TripCardEntity(
            id: 'new-trip',
            userId: 'u1',
            name: 'Weekend getaway',
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
            status: TripStatus.upcoming,
            photoCount: 0,
            stars: 0,
            expenseTotal: 0,
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final state = container.read(expenseListControllerProvider).value!;
      expect(state.summaries, hasLength(1));
      expect(state.summaries.single.tripId, 'new-trip');
      expect(state.summaries.single.totalAmount, 0);
      // The regression this guards against: the newly created (and only)
      // memory must become selected so its detail section actually renders,
      // not just get added to the list.
      expect(state.selectedTripId, 'new-trip');
      expect(state.selectedTripExpenses, isNotNull);
    },
  );

  test(
    'TripDeletedDispatched removes the summary and clears its selection',
    () async {
      final repo = FakeExpenseRepository()
        ..summariesResult = Right([buildExpenseSummaryEntity(tripId: 't1')])
        ..expensesForTripResult = const Right([]);
      final bus = GlobalEventBus();
      addTearDown(bus.dispose);
      final container = _buildContainer(repo, bus: bus);
      addTearDown(container.dispose);
      container.listen(expenseListControllerProvider, (_, _) {});

      final loaded = await container.read(
        expenseListControllerProvider.future,
      );
      expect(loaded.selectedTripId, 't1');

      bus.add(const TripDeletedDispatched(tripId: 't1'));
      await Future<void>.delayed(Duration.zero);

      final state = container.read(expenseListControllerProvider).value!;
      expect(state.summaries, isEmpty);
      expect(state.selectedTripId, isNull);
      expect(state.selectedTripExpenses, isNull);
    },
  );

  test('loadMoreSummaries pages the memories list by 3', () async {
    final repo = FakeExpenseRepository()
      ..summariesResult = Right(
        List.generate(
          5,
          (i) => buildExpenseSummaryEntity(tripId: 't$i', totalAmount: 10),
        ),
      )
      ..expensesForTripResult = const Right([]);
    final container = _buildContainer(repo);
    addTearDown(container.dispose);
    container.listen(expenseListControllerProvider, (_, _) {});

    await container.read(expenseListControllerProvider.future);
    var state = container.read(expenseListControllerProvider).value!;
    expect(state.visibleSummaries, hasLength(3));
    expect(state.hasMoreSummaries, isTrue);

    container.read(expenseListControllerProvider.notifier).loadMoreSummaries();
    state = container.read(expenseListControllerProvider).value!;
    expect(state.visibleSummaries, hasLength(5));
    expect(state.hasMoreSummaries, isFalse);
  });

  test('setSearchQuery resets the memories page back to 3', () async {
    final repo = FakeExpenseRepository()
      ..summariesResult = Right(
        List.generate(
          5,
          (i) => buildExpenseSummaryEntity(tripId: 't$i', totalAmount: 10),
        ),
      )
      ..expensesForTripResult = const Right([]);
    final container = _buildContainer(repo);
    addTearDown(container.dispose);
    container.listen(expenseListControllerProvider, (_, _) {});

    await container.read(expenseListControllerProvider.future);
    final notifier = container.read(expenseListControllerProvider.notifier);
    notifier.loadMoreSummaries();
    expect(
      container.read(expenseListControllerProvider).value!.visibleSummaryCount,
      6,
    );

    notifier.setSearchQuery('t1');
    expect(
      container.read(expenseListControllerProvider).value!.visibleSummaryCount,
      3,
    );
  });

  test('applyExpenseAdded updates the summary total and item count', () async {
    final repo = FakeExpenseRepository()
      ..summariesResult = Right([
        buildExpenseSummaryEntity(tripId: 't1', totalAmount: 100, itemCount: 2),
      ])
      ..expensesForTripResult = Right([buildExpenseEntity(tripId: 't1')]);
    final container = _buildContainer(repo);
    addTearDown(container.dispose);
    container.listen(expenseListControllerProvider, (_, _) {});

    await container.read(expenseListControllerProvider.future);
    final notifier = container.read(expenseListControllerProvider.notifier);

    notifier.applyExpenseAdded(
      buildExpenseEntity(id: 'new', tripId: 't1', amount: 25),
    );

    final state = container.read(expenseListControllerProvider).value!;
    final summary = state.summaries.single;
    expect(summary.totalAmount, 125);
    expect(summary.itemCount, 3);
    expect(state.selectedTripExpenses!.any((e) => e.id == 'new'), isTrue);
  });
}
