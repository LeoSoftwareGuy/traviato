import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/expense/domain/entities/expense_category.dart';
import 'package:traviato/features/expense/presentation/pages/expenses_page.dart';
import 'package:traviato/features/expense/presentation/providers/expense_providers.dart';

import '../../fakes/fake_expense_repository.dart';

Future<void> _pump(
  WidgetTester tester, {
  required FakeExpenseRepository repo,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [expenseRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(theme: AppTheme.dark, home: const ExpensesPage()),
    ),
  );
}

void main() {
  testWidgets('renders each memory with its total and item count', (
    tester,
  ) async {
    final repo = FakeExpenseRepository()
      ..summariesResult = Right([
        buildExpenseSummaryEntity(
          tripId: 't1',
          tripName: 'Iceland ring road',
          totalAmount: 2280,
          itemCount: 15,
          durationDays: 11,
        ),
        buildExpenseSummaryEntity(
          tripId: 't2',
          tripName: 'Santorini blues',
          totalAmount: 1341,
          itemCount: 13,
          durationDays: 6,
        ),
      ])
      ..expensesForTripResult = const Right([]);
    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();

    // Iceland is the biggest spender, so it's also auto-selected and its
    // name/total repeat in the "Selected memory" detail section below.
    expect(find.text('Iceland ring road'), findsWidgets);
    expect(find.text('€2,280'), findsWidgets);
    expect(find.text('11d · 15 items'), findsOneWidget);
    expect(find.text('Santorini blues'), findsOneWidget);
    expect(find.text('€1,341'), findsOneWidget);
    expect(find.text('6d · 13 items'), findsOneWidget);
  });

  testWidgets('searching filters the visible memories', (tester) async {
    final repo = FakeExpenseRepository()
      ..summariesResult = Right([
        buildExpenseSummaryEntity(
          tripId: 't1',
          tripName: 'Iceland ring road',
          totalAmount: 50,
        ),
        // Bigger total so it's the default selection too — Iceland should
        // then be fully absent from the page, not just the filtered row.
        buildExpenseSummaryEntity(
          tripId: 't2',
          tripName: 'Santorini blues',
          totalAmount: 500,
        ),
      ])
      ..expensesForTripResult = const Right([]);
    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'santo');
    await tester.pumpAndSettle();

    expect(find.text('Santorini blues'), findsWidgets);
    expect(find.text('Iceland ring road'), findsNothing);
  });

  testWidgets('tapping a row loads and shows its category breakdown', (
    tester,
  ) async {
    final repo = FakeExpenseRepository()
      ..summariesResult = Right([
        buildExpenseSummaryEntity(
          tripId: 't1',
          tripName: 'Iceland ring road',
          totalAmount: 80,
        ),
        buildExpenseSummaryEntity(
          tripId: 't2',
          tripName: 'Santorini blues',
          totalAmount: 200,
        ),
      ])
      ..expensesForTripResult = Right([
        buildExpenseEntity(
          tripId: 't2',
          category: ExpenseCategory.accommodation,
          amount: 200,
        ),
      ]);
    await _pump(tester, repo: repo);
    await tester.pumpAndSettle(); // default-selects t2 (biggest spender)

    expect(find.text('Selected memory'), findsOneWidget);
    expect(find.text('Santorini blues'), findsWidgets);
    // Appears both as the "Biggest category" stat value and in the "By
    // category" breakdown row.
    expect(find.text('Accommodation'), findsWidgets);

    await tester.tap(find.text('Iceland ring road'));
    await tester.pumpAndSettle();

    expect(repo.lastExpensesForTripId, 't1');
  });

  testWidgets('shows the empty state when there are no memories', (
    tester,
  ) async {
    final repo = FakeExpenseRepository()..summariesResult = const Right([]);
    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();

    expect(find.text('No expenses yet'), findsOneWidget);
    expect(find.text('Create your first memory'), findsOneWidget);
  });
}
