import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/journal/presentation/widgets/day_range_hero.dart';

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
          body: DayRangeHero(
            days: days,
            selectedDay: selectedDay,
            onSelect: onSelect ?? (_) {},
            isDayLocked: _isFuture,
          ),
        ),
      ),
    );
  }

  testWidgets(
    'blurs and shows a lock icon only for future days, not past or today',
    (tester) async {
      final days = [
        today.subtract(const Duration(days: 2)), // past
        today, // today (selected)
        today.add(const Duration(days: 2)), // future
      ];

      await pump(tester, days: days, selectedDay: today);

      // Exactly one future day is locked — a real blur filter on its
      // thumbnail, not opacity dimming (that was the earlier #113 bug).
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.byType(ImageFiltered), findsOneWidget);
      expect(find.byType(AnimatedOpacity), findsNothing);
    },
  );

  testWidgets(
    'renders all-past days (a finished, wrapped-up memory) fully sharp '
    'with no lock icon',
    (tester) async {
      final days = List.generate(
        4,
        (i) => today.subtract(Duration(days: 10 - i)),
      );

      await pump(tester, days: days, selectedDay: days.first);

      expect(find.byIcon(Icons.lock_outline), findsNothing);
      expect(find.byType(ImageFiltered), findsNothing);
    },
  );

  testWidgets('only the selected tile gets the active border styling', (
    tester,
  ) async {
    final selected = today;
    final unselected = today.subtract(const Duration(days: 1));

    await pump(
      tester,
      days: [unselected, selected],
      selectedDay: selected,
    );

    final containers = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .toList();
    expect(containers, hasLength(2));

    final borderWidths = containers
        .map((c) => (c.decoration! as BoxDecoration).border!.top.width)
        .toList();

    // One tile (the selected one) has the thicker active border; the
    // other keeps the plain, non-active border — a selection distinction,
    // not a date-based one.
    expect(borderWidths, containsAll(<double>[1, 2]));
  });

  testWidgets(
    'tapping a future day does not invoke onSelect and shows a locked '
    'message instead',
    (tester) async {
      final future = today.add(const Duration(days: 3));
      var tapped = false;

      await pump(
        tester,
        days: [today, future],
        selectedDay: today,
        onSelect: (_) => tapped = true,
      );

      await tester.tap(find.byIcon(Icons.lock_outline));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tapped, isFalse);
      expect(find.text("This day hasn't happened yet"), findsOneWidget);
    },
  );

  testWidgets('tapping today invokes onSelect', (tester) async {
    final past = today.subtract(const Duration(days: 1));
    DateTime? selectedTapped;

    await pump(
      tester,
      days: [past, today],
      selectedDay: past,
      onSelect: (day) => selectedTapped = day,
    );

    await tester.tap(
      find.byKey(Key('journal-day-hero-${today.toIso8601String()}')),
    );
    await tester.pump();

    expect(selectedTapped, today);
  });
}
