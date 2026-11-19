import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/theme/app_spacing.dart';
import 'package:traviato/features/home/presentation/widgets/memories_grid_section.dart';

import '../../../../helpers/localized_app.dart';
import '../../../trip/fakes/fake_trip_repository.dart';

/// Home's side padding.
const _side = AppSpacing.xl;

Future<void> _pump(WidgetTester tester, {required double screenWidth}) async {
  tester.view
    ..physicalSize = Size(screenWidth, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    localizedApp(
      locale: const Locale('en'),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: _side),
          child: MemoriesGridSection(
            trips: [
              for (var i = 1; i <= 3; i++)
                buildTripCard(id: 't$i', name: 'Memory $i'),
            ],
            onTripTap: (_) {},
            onTripLongPress: (_) {},
          ),
        ),
      ),
    ),
  );
}

Rect _tile(WidgetTester tester, String name) => tester.getRect(
  find.ancestor(of: find.text(name), matching: find.byType(InkWell)).first,
);

void main() {
  // iPhone SE and Pro Max logical widths (#424).
  for (final width in [375.0, 430.0]) {
    testWidgets('two columns with equal side margins at $width wide', (
      tester,
    ) async {
      await _pump(tester, screenWidth: width);

      final left = _tile(tester, 'Memory 1');
      final right = _tile(tester, 'Memory 2');
      final third = _tile(tester, 'Memory 3');

      expect(left.left, closeTo(_side, .01));
      expect(width - right.right, closeTo(_side, .01));
      expect(right.left - left.right, closeTo(memoryGridGap, .01));
      expect(left.width, closeTo(right.width, .01));
      // Same aspect as the old 161.5 × 160 tile.
      expect(left.width / left.height, closeTo(161.5 / 160, .01));
      // The odd one starts the next row, in the left column.
      expect(third.left, closeTo(left.left, .01));
      expect(third.top, greaterThan(left.bottom));
    });
  }

  testWidgets('tiles are larger than the old fixed 161.5 on a 393 phone', (
    tester,
  ) async {
    await _pump(tester, screenWidth: 393);

    expect(_tile(tester, 'Memory 1').width, greaterThan(161.5));
  });
}
