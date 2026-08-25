import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/expense/domain/entities/expense_category.dart';
import 'package:traviato/features/expense/presentation/providers/expense_providers.dart';
import 'package:traviato/features/expense/presentation/widgets/add_expense_sheet.dart';

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
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AddExpenseSheet.show(
                context,
                trips: [
                  buildExpenseSummaryEntity(tripId: 't1', tripName: 'Iceland'),
                  buildExpenseSummaryEntity(
                    tripId: 't2',
                    tripName: 'Santorini',
                  ),
                ],
                initialTripId: 't2',
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('validates the title and amount before saving', (tester) async {
    final repo = FakeExpenseRepository();
    await _pump(tester, repo: repo);

    await tester.ensureVisible(find.text('Save expense'));
    await tester.tap(find.text('Save expense'));
    await tester.pumpAndSettle();

    expect(find.text('What was it?'), findsWidgets);
    expect(find.text('Enter an amount greater than 0.'), findsOneWidget);
    expect(repo.lastAddExpenseArgs, isNull);
  });

  testWidgets('defaults to the initial memory, today\'s date, and lets a '
      'category be picked', (tester) async {
    final repo = FakeExpenseRepository();
    await _pump(tester, repo: repo);

    expect(find.text('Santorini'), findsOneWidget); // pre-selected dropdown
    expect(find.textContaining('Today ·'), findsOneWidget);

    await tester.ensureVisible(find.text('Transport'));
    await tester.tap(find.text('Transport'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Sunset dinner'),
      'Fuel fill-up',
    );
    await tester.enterText(find.widgetWithText(TextFormField, '0'), '55');
    await tester.ensureVisible(find.text('Save expense'));
    await tester.tap(find.text('Save expense'));
    await tester.pumpAndSettle();

    expect(repo.lastAddExpenseArgs, isNotNull);
    expect(repo.lastAddExpenseArgs!['tripId'], 't2');
    expect(repo.lastAddExpenseArgs!['category'], ExpenseCategory.transport);
  });

  testWidgets('saves with the selected memory, category, amount and a '
      'picked date', (tester) async {
    final repo = FakeExpenseRepository()
      ..addExpenseResult = Right(
        buildExpenseEntity(tripId: 't2', title: 'Fuel fill-up', amount: 55),
      );
    await _pump(tester, repo: repo);

    await tester.ensureVisible(find.text('Transport'));
    await tester.tap(find.text('Transport'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Sunset dinner'),
      'Fuel fill-up',
    );
    await tester.enterText(find.widgetWithText(TextFormField, '0'), '55');

    // Change the pre-filled (today's) date via the platform date picker.
    await tester.ensureVisible(find.textContaining('Today ·'));
    await tester.tap(find.textContaining('Today ·'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save expense'));
    await tester.tap(find.text('Save expense'));
    await tester.pumpAndSettle();

    expect(repo.lastAddExpenseArgs, isNotNull);
    expect(repo.lastAddExpenseArgs!['tripId'], 't2');
    expect(repo.lastAddExpenseArgs!['title'], 'Fuel fill-up');
    expect(repo.lastAddExpenseArgs!['amount'], 55.0);
    expect(repo.lastAddExpenseArgs!['category'], ExpenseCategory.transport);
  });

  testWidgets('shows an error snackbar when the mutation fails', (
    tester,
  ) async {
    final repo = FakeExpenseRepository()
      ..addExpenseResult = const Left(NetworkFailure());
    await _pump(tester, repo: repo);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Sunset dinner'),
      'Fuel fill-up',
    );
    await tester.enterText(find.widgetWithText(TextFormField, '0'), '55');

    await tester.ensureVisible(find.text('Save expense'));
    await tester.tap(find.text('Save expense'));
    await tester.pumpAndSettle();

    expect(find.text('Please check your connection.'), findsOneWidget);
  });
}
