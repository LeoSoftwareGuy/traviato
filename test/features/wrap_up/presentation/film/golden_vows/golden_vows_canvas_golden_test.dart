@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_canvas.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_timeline.dart';

/// Goldens render on Windows only, like Sky Story's.
final bool _skip = !Platform.isWindows;

void main() {
  // Phase 1 (#346): the ambient layer alone, at moments to compare with
  // docs/design/golden-vows/ref-00/02/14/40/68.png.
  testWidgets('the ambient layer at the reference instants', skip: _skip, (
    tester,
  ) async {
    tester.view.physicalSize = const Size(540, 960);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      GoldenVowsCanvas(timeline: GoldenVowsTimeline.reference()),
    );
    var elapsed = 0.0;
    for (final (name, at) in const [
      ('00_8', 0.8),
      ('02', 2.0),
      ('14', 14.0),
      ('40', 40.0),
      ('69_5', 69.5),
    ]) {
      await tester.pump(
        Duration(milliseconds: ((at - elapsed) * 1000).round()),
      );
      elapsed = at;
      await expectLater(
        find.byType(GoldenVowsCanvas),
        matchesGoldenFile('goldens/ambient_$name.png'),
      );
    }
    await tester.pumpWidget(const SizedBox());
  });
}
