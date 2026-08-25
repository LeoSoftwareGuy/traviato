import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/checklist/presentation/widgets/checklist_progress_bar.dart';

const _trackWidth = 300.0;

double _fillWidth(WidgetTester tester) =>
    tester.getSize(find.byType(AnimatedContainer)).width;

double _trackAvailableWidth(WidgetTester tester) =>
    tester.getSize(find.byType(ClipRRect)).width;

Future<void> _pump(
  WidgetTester tester, {
  required int checkedCount,
  required int totalCount,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: _trackWidth,
          child: ChecklistProgressBar(
            checkedCount: checkedCount,
            totalCount: totalCount,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the checked/total counts', (tester) async {
    await _pump(tester, checkedCount: 2, totalCount: 8);
    expect(find.text('2 of 8 packed'), findsOneWidget);
  });

  testWidgets('renders a non-zero fill for a non-zero fraction', (
    tester,
  ) async {
    await _pump(tester, checkedCount: 1, totalCount: 4);
    await tester.pumpAndSettle();

    final track = _trackAvailableWidth(tester);
    expect(_fillWidth(tester), closeTo(track * 0.25, 0.5));
  });

  testWidgets(
    'checking another item continues from the current fill instead of '
    'resetting to empty',
    (tester) async {
      await _pump(tester, checkedCount: 1, totalCount: 4);
      await tester.pumpAndSettle();
      final track = _trackAvailableWidth(tester);
      expect(_fillWidth(tester), closeTo(track * 0.25, 0.5));

      await _pump(tester, checkedCount: 2, totalCount: 4);
      // A single frame after the target changes — a restart-from-zero bug
      // would read 0 here instead of continuing from the settled value.
      await tester.pump();

      expect(_fillWidth(tester), closeTo(track * 0.25, 0.5));

      await tester.pumpAndSettle();
      expect(_fillWidth(tester), closeTo(track * 0.5, 0.5));
    },
  );
}
