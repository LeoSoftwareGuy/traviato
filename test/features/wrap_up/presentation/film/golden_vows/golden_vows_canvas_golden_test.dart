@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_canvas.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_story.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_timeline.dart';
import 'package:traviato/l10n/app_localizations.dart';

import 'gv_placeholder_photos.dart';

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

  // Generate and decode the placeholders first, so the film starts at once.
  await tester.pumpWidget(const SizedBox());
  final context = tester.element(find.byType(SizedBox));
  late final Map<String, MemoryImage> photos;
  await tester.runAsync(() async {
    photos = await GvPlaceholderPhotos.generate(
      hearts: story.heartPhotos.length,
    );
    for (final photo in photos.values) {
      await precacheImage(photo, context);
    }
    for (final id in story.heartPhotos) {
      await precacheImage(GoldenVowsCanvas.heartImage(photos[id]!), context);
    }
  });

  await tester.pumpWidget(
    Localizations(
      locale: locale,
      delegates: AppLocalizations.localizationsDelegates,
      child: GoldenVowsCanvas(story: story, photo: (id) => photos[id]),
    ),
  );
  // The film starts once its photos are ready (here at once): this frame
  // is its t = 0.
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
      find.byType(GoldenVowsCanvas),
      matchesGoldenFile('goldens/${prefix}_$name.png'),
    );
  }
  await tester.pumpWidget(const SizedBox());
}

void main() {
  // Compare with docs/design/golden-vows/ref-*.png. The photos are
  // generated placeholders; the heart and ending arrive in later phases.
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
      ('13_3', 13.3),
      ('13_7', 13.7),
      ('15_5', 15.5),
      ('17_6', 17.6),
      ('20', 20.0),
      ('24', 24.0),
      ('28', 28.0),
      ('32_5', 32.5),
      ('36', 36.0),
      ('41', 41.0),
      ('46', 46.0),
      ('50', 50.0),
      ('51_7', 51.7),
      ('52_8', 52.8),
      ('53_6', 53.6),
      ('54', 54.0),
      ('55', 55.0),
      ('55_9', 55.9),
      ('56_5', 56.5),
      ('57', 57.0),
      ('58_4', 58.4),
      ('59_4', 59.4),
      ('60_4', 60.4),
      ('61_5', 61.5),
      ('61_8', 61.8),
      ('62_5', 62.5),
      ('63_5', 63.5),
      ('64_5', 64.5),
      ('66_6', 66.6),
      ('68_6', 68.6),
      ('69_3', 69.3),
      ('69_5', 69.5),
      ('69_9', 69.9),
    ], 'wedding');
  });

  testWidgets('in Russian: Cyrillic script and serif', skip: _skip, (
    tester,
  ) async {
    await _pumpFilm(tester, GoldenVowsFixtures.weddingRu, const Locale('ru'));
    await _expectAt(tester, const [
      ('04_4', 4.4),
      ('10', 10.0),
      ('15_5', 15.5),
      ('32_5', 32.5),
      ('46', 46.0),
      ('54', 54.0),
      ('58_4', 58.4),
      ('66_6', 66.6),
    ], 'wedding_ru');
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

  // The heart's extremes: few photos repeat to fill 42 cells; 200 fill 200.
  for (final (name, count) in const [('few', 20), ('many', 200)]) {
    testWidgets('a heart of $count photos', skip: _skip, (tester) async {
      final story = GoldenVowsStory(
        names: 'Mia & Jonas',
        date: DateTime(2026, 9, 5),
        heartPhotoIds: GoldenVowsFixtures.heartIds(count),
      );
      await _pumpFilm(tester, story, const Locale('en'));
      final h0 = GoldenVowsTimeline.forStory(story).heartStart;
      await _expectAt(tester, [
        ('formed', h0 + 3.0),
        ('lifting', h0 + 7.0),
      ], 'heart_$name');
    });
  }
}
