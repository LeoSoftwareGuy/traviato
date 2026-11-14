@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_grain.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_canvas.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_story.dart';
import 'package:traviato/l10n/app_localizations.dart';

import 'neon_test_fonts.dart';

/// Goldens render on Windows only, like the other films'.
final bool _skip = !Platform.isWindows;

Future<void> _pumpFilm(
  WidgetTester tester, {
  bool reduced = false,
  NeonNightStory? story,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(540, 960);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // The grain is made before the film, so it starts at once.
  await tester.runAsync(NeonGrain.load);
  await loadNeonNightFonts();
  await tester.pumpWidget(
    Localizations(
      locale: locale,
      delegates: AppLocalizations.localizationsDelegates,
      child: NeonNightCanvas(
        story: story ?? NeonNightFixtures.reference,
        reducedFlashing: reduced,
      ),
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
  // Compare with docs/design/neon-night/stills/. Ignition and Plan are in;
  // the chapters, note and finale arrive in later phases.
  testWidgets('the ambient layers at the reference instants', skip: _skip, (
    tester,
  ) async {
    await _pumpFilm(tester);
    await _expectAt(tester, const [
      // The envelope tube's flicker dip, then gores and bands lit.
      ('00_1', 0.1),
      ('01_2', 1.2),
      // The title tearing in (glitch); every tube on.
      ('02_0', 2.0),
      ('02_2', 2.2),
      ('02_4', 2.4),
      // Its reflection and the date, then the sign halfway to the corner.
      ('03_2', 3.2),
      ('03_55', 3.55),
      // Plan: heading glitching, rows rising, ticks landing.
      ('04_0', 4.0),
      ('05_0', 5.0),
      ('06_25', 6.25),
      ('08_6', 8.6),
      ('09_3', 9.3),
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
      ('02_0', 2.0),
      ('05_25', 5.25),
      ('06_25', 6.25),
      ('51_45', 51.45),
      ('55_25', 55.25),
    ], 'ambient_reduced');
  });

  testWidgets('in Russian: Cyrillic titles and plan', skip: _skip, (
    tester,
  ) async {
    await _pumpFilm(
      tester,
      story: NeonNightFixtures.referenceRu,
      locale: const Locale('ru'),
    );
    await _expectAt(tester, const [
      ('03_2', 3.2),
      ('08_6', 8.6),
    ], 'ru');
  });

  testWidgets('a longer plan: 5 rows and "+3 MORE"', skip: _skip, (
    tester,
  ) async {
    await _pumpFilm(tester, story: NeonNightFixtures.longPlan);
    await _expectAt(tester, const [('08_6', 8.6)], 'long_plan');
  });
}
