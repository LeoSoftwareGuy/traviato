@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_canvas.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_story.dart';
import 'package:traviato/l10n/app_localizations.dart';

/// Goldens render on Windows only, like Sky Story's.
final bool _skip = !Platform.isWindows;

/// The film's bundled fonts; widget tests otherwise render text in Ahem.
Future<void> loadGoldenVowsFonts() async {
  for (final (family, asset) in const [
    ('CormorantGaramond', 'assets/fonts/CormorantGaramond[wght].ttf'),
    ('PinyonScript', 'assets/fonts/PinyonScript-Regular.ttf'),
    ('GreatVibes', 'assets/fonts/GreatVibes-Regular.ttf'),
  ]) {
    await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
  }
}

Future<void> _pumpFilm(
  WidgetTester tester,
  GoldenVowsStory story,
  Locale locale,
) async {
  tester.view.physicalSize = const Size(540, 960);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await loadGoldenVowsFonts();
  await tester.pumpWidget(
    Localizations(
      locale: locale,
      delegates: AppLocalizations.localizationsDelegates,
      child: GoldenVowsCanvas(story: story),
    ),
  );
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
      find.byType(GoldenVowsCanvas),
      matchesGoldenFile('goldens/${prefix}_$name.png'),
    );
  }
  await tester.pumpWidget(const SizedBox());
}

void main() {
  // Compare with docs/design/golden-vows/ref-*.png. The album, heart and
  // ending arrive in later phases; until then the ambient layer shows.
  testWidgets('the wedding at the reference instants', skip: _skip, (
    tester,
  ) async {
    await _pumpFilm(tester, GoldenVowsFixtures.wedding, const Locale('en'));
    await _expectAt(tester, const [
      ('00_8', 0.8),
      ('02', 2.0),
      ('04_4', 4.4),
      ('05_3', 5.3),
      ('06', 6.0),
      ('08', 8.0),
      ('10', 10.0),
      ('12_3', 12.3),
      ('14', 14.0),
      ('40', 40.0),
      ('69_5', 69.5),
    ], 'wedding');
  });

  testWidgets('in Russian: Cyrillic script and serif', skip: _skip, (
    tester,
  ) async {
    await _pumpFilm(tester, GoldenVowsFixtures.weddingRu, const Locale('ru'));
    await _expectAt(tester, const [('04_4', 4.4), ('10', 10.0)], 'wedding_ru');
  });

  testWidgets('a memory with nothing packed skips the card', skip: _skip, (
    tester,
  ) async {
    await _pumpFilm(
      tester,
      GoldenVowsStory(names: 'Mia & Jonas', date: DateTime(2026, 9, 5)),
      const Locale('en'),
    );
    await _expectAt(tester, const [('04_4', 4.4), ('08', 8.0)], 'bare');
  });

  testWidgets('long names wrap onto two lines', skip: _skip, (tester) async {
    await _pumpFilm(
      tester,
      GoldenVowsStory(
        occasionLine: 'Our Engagement',
        names: 'Alexandra-Margaretha & Maximilian-Johannes',
        date: DateTime(2026, 9, 5),
        place: 'Schloss Neuschwanstein, Bavaria',
      ),
      const Locale('en'),
    );
    await _expectAt(tester, const [('04_4', 4.4)], 'long_names');
  });
}
