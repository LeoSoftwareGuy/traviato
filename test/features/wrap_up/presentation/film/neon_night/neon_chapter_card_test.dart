import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_chapter_card.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_chapter_card_painter.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_canvas.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_scene_spec.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_story.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_texts.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_photo_images.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_scene_painter.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_type.dart';
import 'package:traviato/l10n/app_localizations.dart';

import 'neon_test_fonts.dart';
import 'neon_test_photos.dart';

void main() {
  group('contact sheet (§5.3)', () {
    test(
      'rows = clamp(2 + (n − 10) ÷ 8, 2, 5); tiles = 10 + 8 × (rows − 2)',
      () {
        for (final (photos, rows, tiles) in const [
          (10, 2, 10),
          (12, 2, 10),
          (18, 3, 18),
          (34, 5, 34),
          (40, 5, 34),
          (200, 5, 34),
        ]) {
          final sheet = NnContactSheet.forPhotos(photos);
          expect(sheet.rows, rows, reason: '$photos photos');
          expect(sheet.tiles, hasLength(tiles), reason: '$photos photos');
        }
      },
    );

    test('heroes A and B span 2×2; the rest follow in reading order', () {
      final tiles = NnContactSheet.forPhotos(34).tiles;
      expect(tiles[0], const Rect.fromLTWH(72, 950, 225, 225));
      expect(tiles[1], const Rect.fromLTWH(72 + 2 * 118.5, 950, 106.5, 106.5));
      expect(tiles[2].top, 950 + 118.5);
      // Hero B is the 4th photo, at col 3.
      expect(tiles[3], const Rect.fromLTWH(72 + 3 * 118.5, 950, 225, 225));
      expect(tiles[10], const Rect.fromLTWH(72, 950 + 2 * 118.5, 106.5, 106.5));
      // Inside the 1080 frame.
      for (final tile in tiles) {
        expect(tile.right, lessThanOrEqualTo(1008 + 1e-9));
      }
    });

    test('fewer than 10 photos: one row of up to 4 heroes', () {
      expect(NnContactSheet.forPhotos(1).tiles, hasLength(1));
      final tiles = NnContactSheet.forPhotos(9).tiles;
      expect(tiles, hasLength(4));
      expect([for (final t in tiles) t.width], everyElement(225));
      expect(tiles.last.right, closeTo(72 + 8 * 118.5 - 12, 1e-9));
    });

    test('gridBottom = 950 + rows × 118.5 − 12', () {
      expect(NnContactSheet.forPhotos(34).bottom, 950 + 5 * 118.5 - 12);
      expect(NnContactSheet.forPhotos(3).bottom, 950 + 2 * 118.5 - 12);
    });
  });

  test('titles over 10 characters with 2+ words split at the middle', () {
    expect(NeonType.splitTitle('DOORS OPEN'), 'DOORS OPEN');
    expect(NeonType.splitTitle('AFTER MIDNIGHT'), 'AFTER\nMIDNIGHT');
    expect(NeonType.splitTitle('SUPERCALIFRAGILISTIC'), 'SUPERCALIFRAGILISTIC');
    expect(
      NeonType.splitTitle('THE LONG MIDDLE BIT'),
      'THE LONG\nMIDDLE BIT',
    );
  });

  group('highlight', () {
    NnCardTiming timing({int zooms = 3, int beats = 16, int tiles = 34}) =>
        NnCardTiming(
          chapterNumber: 1,
          beats: beats,
          zooms: zooms,
          tiles: tiles,
        );

    test('jumps every beat from lb 4, never twice on one tile', () {
      final long = timing();
      expect(long.highlights, hasLength(2), reason: 'stops at lb 6');
      final short = timing(zooms: 0, beats: 8);
      expect(short.highlights, hasLength(4), reason: 'runs to the end');
      for (var j = 1; j < short.highlights.length; j++) {
        expect(short.highlights[j], isNot(short.highlights[j - 1]));
      }
      expect(short.highlights, timing(zooms: 0, beats: 8).highlights);
    });

    test('the current tile 1, its trail 0.5 and 0.25', () {
      final short = timing(zooms: 0, beats: 8);
      expect(short.highlightAt(3.9), isEmpty);
      final h = short.highlights;
      final at = short.highlightAt(6.5);
      expect(at[h[2]], 1);
      expect(at[h[1]], 0.5);
      if (h[0] != h[2]) expect(at[h[0]], 0.25);
      expect(short.highlightAt(8), isEmpty);
    });

    test('reduced flashing fades the current tile in over 0.15 s', () {
      final short = timing(zooms: 0, beats: 8);
      final half = short.beat.secToBeat(0.075);
      expect(
        short.highlightAt(4 + half, reducedFlashing: true)[short.highlights[0]],
        closeTo(0.5, 1e-9),
      );
    });
  });

  group('laser zooms', () {
    test('picks distinct tiles, one per zoom', () {
      final t = NnCardTiming(chapterNumber: 3, beats: 16, zooms: 3, tiles: 34);
      expect(t.zoomTiles, hasLength(3));
      expect(t.zoomTiles.toSet(), hasLength(3));
      final two = NnCardTiming(chapterNumber: 3, beats: 12, zooms: 2, tiles: 2);
      expect(two.zoomTiles.toSet(), {0, 1});
    });

    test('cycles at lb 6, 9, 12; each 3 beats', () {
      final t = NnCardTiming(chapterNumber: 1, beats: 16, zooms: 3, tiles: 34);
      expect(t.zoomAt(5.9), isNull);
      expect(t.zoomAt(6), 0);
      expect(t.zoomAt(8.99), 0);
      expect(t.zoomAt(9), 1);
      expect(t.zoomAt(14.9), 2);
      expect(t.zoomAt(15), isNull);
      final one = NnCardTiming(chapterNumber: 1, beats: 12, zooms: 1, tiles: 1);
      expect(one.zoomAt(9.5), isNull);
    });

    test('flies out over lb c+½…c+1, holds, flies back from c+2½', () {
      expect(NnCardTiming.zoomAmount(6.4, 0), 0);
      expect(NnCardTiming.zoomAmount(6.75, 0), inExclusiveRange(0, 1));
      expect(NnCardTiming.zoomAmount(7, 0), 1);
      expect(NnCardTiming.zoomAmount(8.4, 0), 1);
      expect(NnCardTiming.zoomAmount(8.75, 0), closeTo(0.5, 1e-9));
      expect(NnCardTiming.zoomAmount(9, 0), 0);
    });

    test('the laser grows over ½ beat and fades from c + 2', () {
      expect(NnCardTiming.laserAt(5.9, 0), (0.0, 0.0));
      expect(NnCardTiming.laserAt(6.5, 0), (1.0, 1.0));
      final (length, alpha) = NnCardTiming.laserAt(8.25, 0);
      expect(length, 1);
      expect(alpha, closeTo(0.5, 1e-9));
      expect(NnCardTiming.laserAt(8.5, 0), (0.0, 0.0));
    });
  });

  test('the film decodes sheet tiles small; zoom picks and moments large', () {
    final story = NeonNightFixtures.reference;
    final (:thumbs, :large, tiles: _) = NeonPhotoImages.idsFor(
      story,
      NeonNightCanvas.timelineFor(story),
    );
    expect(thumbs, hasLength(34 + 10 + 34));
    final moments = {
      for (final chapter in story.chapters)
        for (final moment in chapter.moments)
          for (final photo in moment.photos) photo.id,
    };
    expect(large, containsAll(moments));
    expect(large.toSet(), hasLength(large.length));
    // Zooms only on the first and last cards: Ch 2's large photos are
    // its timeline's.
    expect(
      large.where((id) => id.startsWith('ch2-')).toSet(),
      {for (final p in story.chapters[1].moments.single.photos) p.id},
    );
  });

  group('the slam flash', () {
    final timeline = NeonNightCanvas.timelineFor(NeonNightFixtures.reference);
    final cue = timeline.chapterCard(0).start;

    test('pink 0.4 on the cue, gone by the next scene', () {
      final flash = NeonFlashPainter(
        timeline: timeline,
        time: ValueNotifier(0),
      );
      expect(flash.flashAt(cue), closeTo(0.4, 1e-6));
      expect(flash.flashAt(cue + 1), lessThan(0.01));
      expect(flash.flashAt(cue - 0.01), 0);
    });

    test('reduced: 0.12, τ 0.4', () {
      final flash = NeonFlashPainter(
        timeline: timeline,
        time: ValueNotifier(0),
        reducedFlashing: true,
      );
      expect(flash.flashAt(cue), closeTo(0.12, 1e-6));
    });
  });

  group('texts', () {
    final en = lookupAppLocalizations(const ui.Locale('en'));
    setUpAll(loadNeonNightFonts);

    test('header, numeral, title, typed line, time labels', () {
      final texts = NeonNightTexts(NeonNightFixtures.reference, en);
      final ch1 = texts.chapters[0];
      expect((ch1.header.text! as TextSpan).text, 'CH 01/03');
      expect((ch1.range.text! as TextSpan).text, '22:10 – 23:40');
      expect(ch1.typedLines, 1);
      expect(ch1.typedLength, '> QUEUE WAS WORTH IT. BARELY.'.length);
      expect(ch1.title.size.width, lessThanOrEqualTo(861));
      expect(texts.chapters[1].typed, isNull);
      expect(texts.chapters[2].typedLines, 2);
      texts.dispose();
    });

    test('the bar sits under the typed line, or 70 px under the sheet', () {
      final story = NeonNightFixtures.reference;
      final texts = NeonNightTexts(story, en);
      final timeline = NeonNightCanvas.timelineFor(story);
      NnChapterCardPainter card(int i) => NnChapterCardPainter(
        spec: timeline.chapterCard(i).spec as NnChapterCardSpec,
        chapter: story.chapters[i],
        texts: texts.chapters[i],
        photos: const NoPhotos(),
        beat: timeline.beat,
        reducedFlashing: false,
      );
      expect(card(0).barTop, 1690);
      expect(card(1).barTop, 950 + 2 * 118.5 - 12 + 70);
      expect(card(2).barTop, 950 + 5 * 118.5 - 12 + 50 + 104 + 30);
      texts.dispose();
    });
  });

  testWidgets('a card renders the same at the same instant', (tester) async {
    await loadNeonNightFonts();
    final story = NeonNightFixtures.reference;
    final texts = NeonNightTexts(
      story,
      lookupAppLocalizations(const ui.Locale('en')),
    );
    final timeline = NeonNightCanvas.timelineFor(story);
    Future<Uint8List> render(double t) async {
      final painter = NeonScenePainter(
        timeline: timeline,
        story: story,
        texts: texts,
        photos: const NoPhotos(),
        time: ValueNotifier(t),
      );
      final recorder = ui.PictureRecorder();
      painter.paint(Canvas(recorder), const Size(1080, 1920));
      final picture = recorder.endRecording();
      final image = await picture.toImage(270, 480);
      final bytes = await image.toByteData();
      image.dispose();
      picture.dispose();
      return bytes!.buffer.asUint8List();
    }

    await tester.runAsync(() async {
      // Slam, sheet popping, highlight, typing, a zoom landing, Ch 3.
      for (final t in const [9.6, 10.6, 11.6, 12.4, 13.2, 15.7, 41.6]) {
        expect(
          listEquals(await render(t), await render(t)),
          isTrue,
          reason: 't = $t',
        );
      }
    });
    texts.dispose();
  });
}
