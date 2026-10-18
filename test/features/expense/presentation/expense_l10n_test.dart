import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/features/expense/domain/entities/expense_category.dart';
import 'package:traviato/features/expense/presentation/controllers/expense_sort_mode.dart';
import 'package:traviato/features/expense/presentation/pages/expense_compare_page.dart';
import 'package:traviato/features/expense/presentation/pages/expenses_page.dart';
import 'package:traviato/features/expense/presentation/providers/expense_providers.dart';
import 'package:traviato/features/expense/presentation/widgets/add_expense_sheet.dart';
import 'package:traviato/features/expense/presentation/widgets/expense_compare_verdict.dart';
import 'package:traviato/features/expense/presentation/widgets/expense_labels.dart';
import 'package:traviato/features/expense/presentation/widgets/expense_money_format.dart';
import 'package:traviato/l10n/app_localizations.dart';

import '../../../helpers/localized_app.dart';
import '../fakes/fake_expense_repository.dart';

final _en = lookupAppLocalizations(const Locale('en'));
final _ru = lookupAppLocalizations(const Locale('ru'));
final _et = lookupAppLocalizations(const Locale('et'));

FakeExpenseRepository _repo() => FakeExpenseRepository()
  ..summariesResult = Right([
    buildExpenseSummaryEntity(
      tripId: 't1',
      tripName: 'Riga',
      place: 'Latvia',
      durationDays: 3,
      totalAmount: 1234.5,
      itemCount: 2,
    ),
    buildExpenseSummaryEntity(
      tripId: 't2',
      tripName: 'Tartu',
      place: null,
      durationDays: 1,
      totalAmount: 80,
      itemCount: 1,
    ),
  ])
  ..expensesForTripResult = Right([
    buildExpenseEntity(id: 'e1', amount: 1200),
    buildExpenseEntity(
      id: 'e2',
      title: 'Bus',
      amount: 34.5,
      category: ExpenseCategory.transport,
    ),
  ]);

void main() {
  group('money', () {
    test('English keeps its format; ru/et put the euro last', () {
      expect(formatEuro(1234.5, 'en'), '€1,234.50');
      expect(formatEuro(42, 'en'), '€42');
      expect(formatEuro(1234.5, 'ru'), '1 234,50 €');
      expect(formatEuro(1234.5, 'et'), '1 234,50 €');
      expect(formatEuro(42, 'et'), '42 €');
    });

    test('typed amounts accept a decimal comma and grouping spaces', () {
      expect(parseEuroAmount('12,50'), 12.5);
      expect(parseEuroAmount('12.50'), 12.5);
      expect(parseEuroAmount(' 1 234,50 '), 1234.5);
      expect(parseEuroAmount('1 234,5'), 1234.5);
      expect(parseEuroAmount(''), isNull);
      expect(parseEuroAmount('abc'), isNull);
    });
  });

  test('every category and sort mode has a distinct label per language', () {
    for (final l10n in [_en, _ru, _et]) {
      expect(
        {for (final c in ExpenseCategory.values) expenseCategoryLabel(l10n, c)},
        hasLength(ExpenseCategory.values.length),
      );
      expect(
        {for (final m in ExpenseSortMode.values) expenseSortLabel(l10n, m)},
        hasLength(ExpenseSortMode.values.length),
      );
    }
    for (final c in ExpenseCategory.values) {
      expect(expenseCategoryLabel(_en, c), c.displayName);
    }
  });

  test('verdict reads in Russian with names quoted and euro last', () {
    final a = buildExpenseSummaryEntity(
      tripId: 'a',
      tripName: 'Рига',
      durationDays: 2,
      totalAmount: 300,
    );
    final b = buildExpenseSummaryEntity(
      tripId: 'b',
      tripName: 'Тарту',
      durationDays: 2,
      totalAmount: 200,
    );
    expect(
      buildCompareVerdict(l10n: _ru, a: a, b: b),
      'Поездка «Рига» обошлась на 100 € дороже, и в день тоже уходило '
      'на 50 € больше. «Тарту» — дешевле в пересчёте на день.',
    );
  });

  testWidgets('Expenses overview reads in Russian', (tester) async {
    setScreenSize(tester, height: 2400);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [expenseRepositoryProvider.overrideWithValue(_repo())],
        child: localizedApp(
          locale: const Locale('ru'),
          home: const ExpensesPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('РАСХОДЫ'), findsOneWidget);
    expect(find.text('Сравнить'), findsOneWidget);
    expect(find.text('Сначала новые'), findsOneWidget);
    expect(find.text('2 ИЗ 2'), findsOneWidget);
    expect(find.text('1 234,50 €'), findsWidgets);
    expect(find.text('3 дн. · 2 записи'), findsOneWidget);
    expect(find.text('ПО КАТЕГОРИЯМ'), findsOneWidget);
    expect(find.text('Еда и напитки'), findsWidgets);
    expect(find.text('Bus'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final locale in const [Locale('en'), Locale('ru'), Locale('et')]) {
    testWidgets('Expenses and Compare lay out without overflow at 360pt in '
        '${locale.languageCode}', (tester) async {
      setScreenSize(tester, height: 2400);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [expenseRepositoryProvider.overrideWithValue(_repo())],
          child: localizedApp(locale: locale, home: const ExpensesPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [expenseRepositoryProvider.overrideWithValue(_repo())],
          child: localizedApp(locale: locale, home: const ExpenseComparePage()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Riga'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tartu'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('add-expense sheet saves an amount typed with a comma', (
    tester,
  ) async {
    final repo = FakeExpenseRepository()
      ..addExpenseResult = Right(buildExpenseEntity(amount: 12.5));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [expenseRepositoryProvider.overrideWithValue(repo)],
        child: localizedApp(
          locale: const Locale('et'),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AddExpenseSheet.show(
                  context,
                  trips: [buildExpenseSummaryEntity(tripId: 't1')],
                  initialTripId: 't1',
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

    expect(find.text('Uus kulu'), findsOneWidget);
    expect(find.textContaining('Täna ·'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Õhtusöök päikeseloojangul'),
      'Kohv',
    );
    await tester.enterText(find.widgetWithText(TextFormField, '0'), '12,50');
    await tester.ensureVisible(find.text('Salvesta kulu'));
    await tester.tap(find.text('Salvesta kulu'));
    await tester.pumpAndSettle();

    expect(repo.lastAddExpenseArgs?['amount'], 12.5);
  });
}
