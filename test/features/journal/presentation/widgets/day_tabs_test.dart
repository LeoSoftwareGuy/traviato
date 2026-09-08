import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/journal/presentation/widgets/day_tabs.dart';

DateTime get _today {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

bool _isFuture(DateTime day) => day.isAfter(_today);

void main() {
  final today = _today;

  Future<void> pump(
    WidgetTester tester, {
    required List<DateTime> days,
    required DateTime selectedDay,
    ValueChanged<DateTime>? onSelect,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DayTabs(
            days: days,
            selectedDay: selectedDay,
            thumbnailForDay: (_) => null,
            onSelect: onSelect ?? (_) {},
            isDayLocked: _isFuture,
          ),
        ),
      ),
    );
  }

  testWidgets('shows a lock icon only for the future day', (tester) async {
    final future = today.add(const Duration(days: 2));
    await pump(
      tester,
      days: [today.subtract(const Duration(days: 1)), today, future],
      selectedDay: today,
    );

    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });

  testWidgets(
    'tapping a future day does not invoke onSelect and shows a locked '
    'message instead',
    (tester) async {
      final future = today.add(const Duration(days: 2));
      var tapped = false;

      await pump(
        tester,
        days: [today, future],
        selectedDay: today,
        onSelect: (_) => tapped = true,
      );

      await tester.tap(
        find.byKey(Key('journal-day-tab-${future.toIso8601String()}')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tapped, isFalse);
      expect(find.text("This day hasn't happened yet"), findsOneWidget);
    },
  );

  testWidgets('tapping a past day invokes onSelect', (tester) async {
    final past = today.subtract(const Duration(days: 1));
    DateTime? selectedTapped;

    await pump(
      tester,
      days: [past, today],
      selectedDay: today,
      onSelect: (day) => selectedTapped = day,
    );

    await tester.tap(
      find.byKey(Key('journal-day-tab-${past.toIso8601String()}')),
    );
    await tester.pump();

    expect(selectedTapped, past);
  });
}
