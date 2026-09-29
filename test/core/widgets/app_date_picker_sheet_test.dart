import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/core/widgets/app_date_picker_sheet.dart';

/// Pumps a themed host, opens the picker over it, and returns its result.
Future<Future<DateTime?>> _open(
  WidgetTester tester, {
  required DateTime initialDate,
  String label = 'Pick a date',
}) async {
  late BuildContext hostContext;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            hostContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  final result = showAppDatePicker(
    context: hostContext,
    label: label,
    initialDate: initialDate,
    firstDate: DateTime(2026),
    lastDate: DateTime(2026, 12, 31),
  );
  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('renders the app sheet, not the platform dialog (#163)', (
    tester,
  ) async {
    await _open(tester, initialDate: DateTime(2026, 2, 25), label: 'Starts');

    expect(find.byType(AppDatePickerSheet), findsOneWidget);
    expect(find.byType(DatePickerDialog), findsNothing);
    expect(find.text('STARTS'), findsOneWidget);
    expect(find.text('Wed, 25 Feb 2026'), findsOneWidget);
  });

  testWidgets('tapping a day updates the headline; Done returns it', (
    tester,
  ) async {
    final result = await _open(tester, initialDate: DateTime(2026, 2, 25));

    await tester.tap(find.text('27'));
    await tester.pumpAndSettle();
    expect(find.text('Fri, 27 Feb 2026'), findsOneWidget);
    expect(find.byType(AppDatePickerSheet), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(await result, DateTime(2026, 2, 27));
    expect(find.byType(AppDatePickerSheet), findsNothing);
  });

  testWidgets('Cancel resolves with null even after tapping a day', (
    tester,
  ) async {
    final result = await _open(tester, initialDate: DateTime(2026, 2, 25));

    await tester.tap(find.text('27'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(await result, isNull);
  });

  testWidgets('clamps an out-of-range initial date instead of asserting', (
    tester,
  ) async {
    await _open(tester, initialDate: DateTime(2030, 5, 5));

    expect(tester.takeException(), isNull);
    expect(find.text('Thu, 31 Dec 2026'), findsOneWidget);
  });
}
