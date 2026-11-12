@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story_canvas.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story_fixture.dart';
import 'package:traviato/l10n/app_localizations.dart';

// The Sky Story film (#345) at the reference stills' instants
// (docs/design/sky-story/ref-*.png) on the reference's memory, with the
// app's cover images standing in for its photos. Made on Windows and
// skipped elsewhere, like the classic film's goldens. Regenerate with
// `flutter test --update-goldens --tags golden`.
final bool _skip = !Platform.isWindows;

/// The film's bundled fonts; widget tests otherwise render text in Ahem.
Future<void> loadSkyStoryFonts() async {
  for (final (family, asset) in const [
    ('DMSerifDisplay', 'assets/fonts/DMSerifDisplay-Regular.ttf'),
    ('PlayfairDisplay', 'assets/fonts/PlayfairDisplay[wght].ttf'),
    ('OpenSans', 'assets/fonts/OpenSans[wdth,wght].ttf'),
    ('Caveat', 'assets/fonts/Caveat[wght].ttf'),
  ]) {
    await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
  }
}

Future<void> _pumpFilm(
  WidgetTester tester,
  SkyStory story,
  Locale locale,
) async {
  tester.view.physicalSize = const Size(540, 960);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await loadSkyStoryFonts();

  // Decode the photos first, so the frames don't race the image loads.
  await tester.pumpWidget(const SizedBox());
  final context = tester.element(find.byType(SizedBox));
  await tester.runAsync(() async {
    for (final id in story.photoIds.toSet()) {
      await precacheImage(SkyStoryFixtures.photo(id)!, context);
    }
    for (final id in story.mosaicPhotoIds) {
      await precacheImage(
        ResizeImage(SkyStoryFixtures.photo(id)!, width: 96),
        context,
      );
    }
    await precacheImage(
      const AssetImage('assets/images/brand/storyni_icon.png'),
      context,
    );
  });

  await tester.pumpWidget(
    Localizations(
      locale: locale,
      delegates: AppLocalizations.localizationsDelegates,
      child: SkyStoryCanvas(story: story, photo: SkyStoryFixtures.photo),
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
      find.byType(SkyStoryCanvas),
      matchesGoldenFile('goldens/${prefix}_$name.png'),
    );
  }
}

void main() {
  testWidgets('the film at the reference instants', skip: _skip, (
    tester,
  ) async {
    await _pumpFilm(tester, SkyStoryFixtures.lisbon, const Locale('en'));
    await _expectAt(tester, const [
      ('00', 0.5),
      ('03', 3.0),
      ('06', 6.0),
      ('09', 9.0),
      ('12', 12.0),
      ('15', 15.0),
      ('16_75', 16.75),
      ('17_25', 17.25),
      ('18', 18.0),
      ('21', 21.0),
      ('24', 24.0),
      ('27', 27.0),
      ('29_5', 29.5),
      ('30', 30.0),
      ('33', 33.0),
      ('36', 36.0),
      ('39', 39.0),
      ('42', 42.0),
      ('42_5', 42.5),
      ('44_5', 44.5),
      ('45', 45.0),
      ('45_5', 45.5),
      ('46', 46.0),
      ('47', 47.0),
      ('48', 48.0),
      ('50', 50.0),
      ('54', 53.8),
    ], 'film');
  });

  testWidgets('the Russian film', skip: _skip, (tester) async {
    await _pumpFilm(tester, SkyStoryFixtures.lisbonRu, const Locale('ru'));
    await _expectAt(tester, const [
      ('03', 3.0),
      ('15', 15.0),
      ('27', 27.0),
      ('39', 39.0),
      ('50', 50.0),
    ], 'film_ru');
  });

  // A real memory's pages (#345, phase 6): no headlines (the place stands
  // in), a run of days, a director's line on the sky in place of a note,
  // and a page with neither, whose caption moves onto the sky.
  final realMemory = SkyStory(
    title: 'Lisbon',
    startDate: DateTime(2026, 6, 9),
    endDate: DateTime(2026, 6, 14),
    momentCount: 40,
    pages: [
      SkyPage(
        firstDay: 4,
        lastDay: 7,
        date: DateTime(2026, 6, 12),
        endDate: DateTime(2026, 6, 15),
        photoCount: 31,
        hero: SkyPhoto(
          id: 'mountain_town',
          place: 'Alfama',
          takenAt: DateTime(2026, 6, 12, 9, 40),
        ),
        extras: const [
          SkyPhoto(id: 'rooftop_gathering', place: 'Alfama'),
          SkyPhoto(id: 'foodie'),
        ],
        skyLine: 'You counted eleven bridges and lost count.',
      ),
      SkyPage(
        firstDay: 8,
        date: DateTime(2026, 6, 16),
        photoCount: 9,
        hero: const SkyPhoto(id: 'maui', place: 'Cascais'),
        extras: const [
          SkyPhoto(id: 'canoe'),
          SkyPhoto(id: 'picnic_on_the_edge'),
          SkyPhoto(id: 'departure'),
        ],
      ),
    ],
  );

  testWidgets('a real memory: sky line, caption on the sky', skip: _skip, (
    tester,
  ) async {
    await _pumpFilm(tester, realMemory, const Locale('en'));
    await _expectAt(tester, const [('10', 10.0), ('26', 26.0)], 'real');
  });

  testWidgets('a real memory in Russian', skip: _skip, (tester) async {
    await _pumpFilm(tester, realMemory, const Locale('ru'));
    await _expectAt(tester, const [('10', 10.0)], 'real_ru');
  });
}
