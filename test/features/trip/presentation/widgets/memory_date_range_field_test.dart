import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/core/widgets/app_date_picker_sheet.dart';
import 'package:traviato/features/trip/presentation/widgets/memory_date_range_field.dart';

void main() {
  testWidgets('Starts opens the app date picker sheet and reports the pick '
      '(#163)', (tester) async {
    DateTime? picked;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: MemoryDateRangeField(
            startDate: DateTime(2026, 2, 25),
            endDate: DateTime(2026, 3, 1),
            onStartDateChanged: (date) => picked = date,
            onEndDateChanged: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('25 Feb 2026'));
    await tester.pumpAndSettle();

    expect(find.byType(AppDatePickerSheet), findsOneWidget);
    expect(find.byType(DatePickerDialog), findsNothing);
    // The field card also shows "STARTS"; the sheet's eyebrow is the second.
    expect(find.text('STARTS'), findsNWidgets(2));

    await tester.tap(find.text('27'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(picked, DateTime(2026, 2, 27));
  });

  testWidgets('dismissing the sheet leaves the date unchanged', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: MemoryDateRangeField(
            startDate: null,
            endDate: null,
            onStartDateChanged: (_) {},
            onEndDateChanged: (_) => calls++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Pick a date').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(calls, 0);
  });
}
