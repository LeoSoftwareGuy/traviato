import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/expense/domain/entities/expense_category.dart';
import 'package:traviato/features/expense/presentation/pages/expense_compare_page.dart';
import 'package:traviato/features/expense/presentation/providers/expense_providers.dart';

import '../../fakes/fake_expense_repository.dart';

Future<void> _pump(
  WidgetTester tester, {
  required FakeExpenseRepository repo,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [expenseRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const ExpenseComparePage(),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the pick-two hint and both memories', (tester) async {
    final repo = FakeExpenseRepository()
      ..summariesResult = Right([
        buildExpenseSummaryEntity(tripId: 't1', tripName: 'Iceland'),
        buildExpenseSummaryEntity(tripId: 't2', tripName: 'Santorini'),
      ]);
    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();

    expect(
      find.text('Pick two memories to put their spending side by side.'),
      findsOneWidget,
    );
    expect(find.text('Pick two'), findsOneWidget);
    expect(find.text('Iceland'), findsOneWidget);
    expect(find.text('Santorini'), findsOneWidget);
  });

  testWidgets(
    'picking two memories reveals the comparison table and verdict',
    (tester) async {
      final repo = FakeExpenseRepository()
        ..summariesResult = Right([
          buildExpenseSummaryEntity(
            tripId: 't1',
            tripName: 'Iceland',
            totalAmount: 1000,
            durationDays: 5,
          ),
          buildExpenseSummaryEntity(
            tripId: 't2',
            tripName: 'Santorini',
            totalAmount: 600,
            durationDays: 10,
          ),
        ])
        ..expensesForTripResult = Right([
          buildExpenseEntity(category: ExpenseCategory.transport, amount: 100),
        ]);
      await _pump(tester, repo: repo);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Iceland'));
      await tester.pumpAndSettle();
      expect(find.text('Now pick a second one.'), findsOneWidget);

      await tester.tap(find.text('Santorini'));
      await tester.pumpAndSettle();

      expect(
        find.text('Iceland vs Santorini — tap either to swap it out.'),
        findsOneWidget,
      );
      expect(find.text('FINANCIAL COMPARISON'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.textContaining('more overall'), findsOneWidget); // verdict
      expect(find.text('✕ Done comparing'), findsOneWidget);
    },
  );

  testWidgets('"Done comparing" clears both picks', (tester) async {
    final repo = FakeExpenseRepository()
      ..summariesResult = Right([
        buildExpenseSummaryEntity(tripId: 't1', tripName: 'Iceland'),
        buildExpenseSummaryEntity(tripId: 't2', tripName: 'Santorini'),
      ])
      ..expensesForTripResult = const Right([]);
    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Iceland'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Santorini'));
    await tester.pumpAndSettle();
    expect(find.text('FINANCIAL COMPARISON'), findsOneWidget);

    await tester.tap(find.text('✕ Done comparing'));
    await tester.pumpAndSettle();

    expect(find.text('FINANCIAL COMPARISON'), findsNothing);
    expect(
      find.text('Pick two memories to put their spending side by side.'),
      findsOneWidget,
    );
  });

  testWidgets('tapping the first pick again clears it (nothing to promote)', (
    tester,
  ) async {
    final repo = FakeExpenseRepository()
      ..summariesResult = Right([
        buildExpenseSummaryEntity(tripId: 't1', tripName: 'Iceland'),
      ])
      ..expensesForTripResult = const Right([]);
    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Iceland'));
    await tester.pumpAndSettle();
    expect(find.text('Now pick a second one.'), findsOneWidget);

    await tester.tap(find.text('Iceland'));
    await tester.pumpAndSettle();
    expect(
      find.text('Pick two memories to put their spending side by side.'),
      findsOneWidget,
    );
  });
}
