@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_grain.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_canvas.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_scene_spec.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_story.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_photo_images.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_placeholder_photo.dart';
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
  final night = story ?? NeonNightFixtures.reference;
  final photo = NeonPlaceholderPhoto.forIds(NeonNightFixtures.photoIds(night));

  // Decode the photos first, so the frames don't race the image loads.
  await tester.pumpWidget(const SizedBox());
  final context = tester.element(find.byType(SizedBox));
  final (:thumbs, :large, :tiles) = NeonPhotoImages.idsFor(
    night,
    NeonNightCanvas.timelineFor(night),
  );
  await tester.runAsync(() async {
    for (final id in thumbs) {
      await precacheImage(NeonPhotoImages.thumbProvider(photo, id)!, context);
    }
    for (final id in large) {
      await precacheImage(NeonPhotoImages.largeProvider(photo, id)!, context);
    }
    for (final id in tiles) {
      await precacheImage(NeonPhotoImages.tileProvider(photo, id)!, context);
    }
  });

  await tester.pumpWidget(
    Localizations(
      locale: locale,
      delegates: AppLocalizations.localizationsDelegates,
      child: NeonNightCanvas(
        story: night,
        photo: photo,
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

  // Chapter cards (§5.3), at the MP4's instants: the numeral slamming in
  // pink, the sheet popping, the highlight, the three laser zooms, Ch 2's
  // short card without a note, Ch 3's typed line on 2 lines.
  testWidgets('chapter cards', skip: _skip, (tester) async {
    await _pumpFilm(tester);
    await _expectAt(tester, const [
      ('09_6', 9.6),
      ('10_3', 10.3),
      ('11_2', 11.2),
      ('12_9', 12.9),
      ('13_6', 13.6),
      ('14_0', 14.0),
      ('15_7', 15.7),
      ('16_8', 16.8),
      ('26_0', 26.0),
      ('36_4', 36.4),
      ('41_6', 41.6),
    ], 'card');
  });

  testWidgets('chapter cards, reduced flashing', skip: _skip, (tester) async {
    await _pumpFilm(tester, reduced: true);
    await _expectAt(tester, const [
      ('09_6', 9.6),
      ('13_6', 13.6),
    ], 'card_reduced');
  });

  testWidgets('chapter cards in Russian', skip: _skip, (tester) async {
    await _pumpFilm(
      tester,
      story: NeonNightFixtures.referenceRu,
      locale: const Locale('ru'),
    );
    await _expectAt(tester, const [('15_7', 15.7), ('26_0', 26.0)], 'card_ru');
  });

  // 2 photos in Ch 1 (a 12-beat card, two zooms), no notes.
  testWidgets('a small night: few photos, no notes', skip: _skip, (
    tester,
  ) async {
    final story = NeonNightFixtures.few;
    final timeline = NeonNightCanvas.timelineFor(story);
    final card = timeline.chapterCard(0);
    final beat = timeline.beat;
    await _pumpFilm(tester, story: story);
    await _expectAt(tester, [
      ('sheet', card.start + beat.beatToSec(5)),
      ('zoom1', card.start + beat.beatToSec(7.5)),
      ('zoom2', card.start + beat.beatToSec(10.5)),
    ], 'card_few');
  });

  // Moments (§5.4–5.6) at the MP4's instants: strips wiping and pulsing,
  // frames popping and jumping, the timeline scrolling with its
  // highlight, the peak fanning out.
  testWidgets('moments', skip: _skip, (tester) async {
    await _pumpFilm(tester);
    await _expectAt(tester, const [
      ('17_5', 17.5),
      ('19_0', 19.048),
      ('21_5', 21.5),
      ('23_3', 23.333),
      ('28_9', 28.9),
      ('29_8', 29.8),
      ('31_9', 31.905),
      ('42_3', 42.3),
      ('44_3', 44.286),
    ], 'moment');
  });

  testWidgets('moments, reduced flashing', skip: _skip, (tester) async {
    await _pumpFilm(tester, reduced: true);
    await _expectAt(tester, const [
      ('19_0', 19.048),
      ('29_8', 29.8),
      ('44_3', 44.286),
    ], 'moment_reduced');
  });

  testWidgets('moments in Russian', skip: _skip, (tester) async {
    await _pumpFilm(
      tester,
      story: NeonNightFixtures.referenceRu,
      locale: const Locale('ru'),
    );
    await _expectAt(tester, const [
      ('19_0', 19.048),
      ('23_3', 23.333),
      ('31_9', 31.905),
      ('44_3', 44.286),
    ], 'moment_ru');
  });

  // 2 strips, 2 frames, a 3-item timeline, a 3-strip peak.
  testWidgets('moments with few photos', skip: _skip, (tester) async {
    final story = NeonNightFixtures.few;
    final timeline = NeonNightCanvas.timelineFor(story);
    final beat = timeline.beat;
    double atBeat(int scene, double lb) =>
        timeline.scenes[scene].start + beat.beatToSec(lb);
    // Ignition, Plan? no (few has no plan), Card 1, Split, Card 2, Burst,
    // Timeline, Card 3, Peak.
    await _pumpFilm(tester, story: story);
    await _expectAt(tester, [
      ('split', atBeat(2, 4)),
      ('burst', atBeat(4, 5.3)),
      ('timeline', atBeat(5, 4.5)),
      ('peak', atBeat(7, 5)),
    ], 'moment_few');
  });

  // Note (§5.7) at the MP4's instants: the tag, each line lighting with
  // its flicker, the signature, the exit fade.
  testWidgets('note', skip: _skip, (tester) async {
    await _pumpFilm(tester);
    await _expectAt(tester, const [
      ('45_9', 45.9),
      ('46_6', 46.6),
      ('47_5', 47.5),
      ('49_0', 49.048),
      ('50_5', 50.5),
      ('51_3', 51.3),
    ], 'note');
  });

  testWidgets('note, reduced flashing', skip: _skip, (tester) async {
    await _pumpFilm(tester, reduced: true);
    await _expectAt(tester, const [('46_6', 46.6)], 'note_reduced');
  });

  testWidgets('note in Russian', skip: _skip, (tester) async {
    await _pumpFilm(
      tester,
      story: NeonNightFixtures.referenceRu,
      locale: const Locale('ru'),
    );
    await _expectAt(tester, const [('50_5', 50.5)], 'note_ru');
  });

  // One short line; no time, photo or first name.
  testWidgets('a short note', skip: _skip, (tester) async {
    final story = NeonNightFixtures.few;
    final timeline = NeonNightCanvas.timelineFor(story);
    final note = timeline.scenes.firstWhere(
      (s) => s.spec is NnNoteSpec,
    );
    await _pumpFilm(tester, story: story);
    await _expectAt(tester, [
      ('lit', note.start + timeline.beat.beatToSec(4)),
    ], 'note_few');
  });

  // Finale (§5.8) and Ending (§5.9) at the MP4's instants: the drop, the
  // heart building and outlined, the glow-up and confetti, the headline,
  // the heart fading, the end card, the fade to black.
  testWidgets('finale and ending', skip: _skip, (tester) async {
    await _pumpFilm(tester);
    await _expectAt(tester, const [
      ('51_5', 51.5),
      ('52_5', 52.5),
      ('54_3', 54.286),
      ('55_5', 55.5),
      ('56_2', 56.19),
      ('58_0', 58.0),
      ('59_5', 59.5),
      ('60_5', 60.5),
      ('62_4', 62.381),
      ('64_0', 64.0),
    ], 'finale');
  });

  testWidgets('finale, reduced flashing', skip: _skip, (tester) async {
    await _pumpFilm(tester, reduced: true);
    await _expectAt(tester, const [
      ('51_5', 51.5),
      ('55_5', 55.5),
    ], 'finale_reduced');
  });

  testWidgets('finale and ending in Russian', skip: _skip, (tester) async {
    await _pumpFilm(
      tester,
      story: NeonNightFixtures.referenceRu,
      locale: const Locale('ru'),
    );
    await _expectAt(tester, const [
      ('56_2', 56.19),
      ('62_4', 62.381),
    ], 'finale_ru');
  });

  // 11 photos repeating over ~220 cells; counted totals; the note's line
  // as headline.
  testWidgets('a small night: finale and ending', skip: _skip, (tester) async {
    final story = NeonNightFixtures.few;
    final timeline = NeonNightCanvas.timelineFor(story);
    final beat = timeline.beat;
    await _pumpFilm(tester, story: story);
    await _expectAt(tester, [
      ('heart', timeline.finaleCue + beat.beatToSec(10)),
      ('end', timeline.endingCue + beat.beatToSec(7)),
    ], 'finale_few');
  });
}
