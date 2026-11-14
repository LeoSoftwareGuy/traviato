@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_grain.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_canvas.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_timeline.dart';

/// Goldens render on Windows only, like the other films'.
final bool _skip = !Platform.isWindows;

Future<void> _pumpFilm(WidgetTester tester, {bool reduced = false}) async {
  tester.view.physicalSize = const Size(540, 960);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // The grain is made before the film, so it starts at once.
  await tester.runAsync(NeonGrain.load);
  await tester.pumpWidget(
    NeonNightCanvas(
      timeline: NeonNightTimeline.reference(),
      reducedFlashing: reduced,
    ),
  );
  // This frame is the film's t = 0.
  await tester.pump();
}

Future<void> _expectAt(
  WidgetTester tester,
  List<(String, double)> shots,
  String prefix,
) async {
  var elapsed = 0.0;
  for (final (name, at) in shots) {
    await tester.pump(Duration(milliseconds: ((at - elapsed) * 1000).round()));
    elapsed = at;
    await expectLater(
      find.byType(NeonNightCanvas),
      matchesGoldenFile('goldens/${prefix}_$name.png'),
    );
  }
  await tester.pumpWidget(const SizedBox());
}

void main() {
  // Compare with docs/design/neon-night/stills/ (scene content arrives in
  // later phases; here only the ambient layers and the balloon sign).
  testWidgets('the ambient layers at the reference instants', skip: _skip, (
    tester,
  ) async {
    await _pumpFilm(tester);
    await _expectAt(tester, const [
      // The envelope tube's flicker dip, then gores and bands lit.
      ('00_1', 0.1),
      ('01_2', 1.2),
      // Every tube on, then halfway to the corner.
      ('02_4', 2.4),
      ('03_55', 3.55),
      // A chapter card (cyan lasers, more haze), a split, Ch2's card.
      ('12_9', 12.9),
      ('18', 18.0),
      ('25', 25.0),
      // Note (dimmer lasers), the drop, the glow-up.
      ('47', 47.0),
      ('51_45', 51.45),
      ('55_25', 55.25),
      // The sign moves to the end pose; the fade to black.
      ('60', 60.0),
      ('62', 62.0),
      ('64_5', 64.5),
    ], 'ambient');
  });

  testWidgets('reduced flashing', skip: _skip, (tester) async {
    await _pumpFilm(tester, reduced: true);
    await _expectAt(tester, const [
      ('00_1', 0.1),
      ('51_45', 51.45),
      ('55_25', 55.25),
    ], 'ambient_reduced');
  });
}
