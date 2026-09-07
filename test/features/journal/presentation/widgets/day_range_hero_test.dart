import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/journal/presentation/widgets/day_range_hero.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required List<DateTime> days,
    required DateTime selectedDay,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DayRangeHero(
            days: days,
            selectedDay: selectedDay,
            onSelect: (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets(
    'renders every day tile at full opacity with no lock icon, '
    'for past, today and future days alike',
    (tester) async {
      final today = DateTime.now();
      final days = [
        today.subtract(const Duration(days: 2)), // past
        today, // today (selected)
        today.add(const Duration(days: 2)), // future
      ];

      await pump(tester, days: days, selectedDay: today);

      // No leftover "locked" affordance anywhere, regardless of date.
      expect(find.byIcon(Icons.lock_outline), findsNothing);

      // Every tile — including the two unselected, one past and one
      // future — renders at full opacity (no date-driven dimming).
      final opacityWidgets = tester.widgetList<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(opacityWidgets, isEmpty);
    },
  );

  testWidgets(
    'renders all-past days (a finished, wrapped-up memory) at full '
    'opacity with no lock icon',
    (tester) async {
      final today = DateTime.now();
      final days = List.generate(
        4,
        (i) => today.subtract(Duration(days: 10 - i)),
      );

      await pump(tester, days: days, selectedDay: days.first);

      expect(find.byIcon(Icons.lock_outline), findsNothing);
      expect(find.byType(AnimatedOpacity), findsNothing);
    },
  );

  testWidgets('only the selected tile gets the active border styling', (
    tester,
  ) async {
    final today = DateTime.now();
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
}
