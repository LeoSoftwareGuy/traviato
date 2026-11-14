import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_beat.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_chapter_card_painter.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_finale_painter.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_heart.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_canvas.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_story.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_texts.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_photo_images.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_scene_painter.dart';
import 'package:traviato/l10n/app_localizations.dart';

import 'neon_test_fonts.dart';
import 'neon_test_photos.dart';

void main() {
  const beat = NeonBeat();
  final en = lookupAppLocalizations(const ui.Locale('en'));
  final ru = lookupAppLocalizations(const ui.Locale('ru'));

  group('heart cells (§5.8)', () {
    final heart = NnHeart(photos: 86);

    test('about 220 cells on a 44 px grid, every centre inside', () {
      expect(heart.cells, hasLength(222));
      for (final cell in heart.cells) {
        expect(cell.width, 44);
        expect(NnHeart.path.contains(cell.center), isTrue);
        // On the 20-column grid centred in the box.
        expect((cell.left - 100) % 44, 0);
      }
    });

    test('photo per cell: ⌊k × N / cells⌋ mod N', () {
      final few = NnHeart(photos: 11);
      expect(few.photoFor(0), 0);
      expect(few.photoFor(few.cells.length - 1), 10);
      // Every photo shows, in order.
      final shown = [
        for (var k = 0; k < few.cells.length; k++) few.photoFor(k),
      ];
      expect(shown.toSet(), hasLength(11));
      expect(shown, orderedEquals([...shown]..sort()));
      // More photos than cells are sampled evenly.
      final many = NnHeart(photos: 400);
      expect(many.photoFor(1), 400 ~/ many.cells.length);
    });

    test('the pop-in order is a seeded permutation', () {
      expect(heart.ranks.toSet(), hasLength(heart.cells.length));
      expect(heart.ranks, NnHeart(photos: 3).ranks);
      expect(
        heart.ranks.take(10),
        isNot(orderedEquals(List.generate(10, (i) => i))),
      );
    });

    test('cell of rank r pops at lb 0.5 + 5.5 r / cells, turning to 0°', () {
      final first = heart.ranks.indexOf(0);
      final last = heart.ranks.indexOf(heart.cells.length - 1);
      expect(heart.popBeat(first), 0.5);
      expect(heart.popBeat(last), closeTo(6, 0.03));
      expect(heart.popAt(0.49, first, beat), (0.0, 0.0));
      final (s, degrees) = heart.popAt(0.5 + beat.secToBeat(0.35), first, beat);
      expect(s, closeTo(1, 1e-9));
      expect(degrees, closeTo(0, 1e-9));
      for (var k = 0; k < 20; k++) {
        expect(heart.startDegrees(k).abs(), lessThanOrEqualTo(20));
      }
    });

    test('the outline draws from lb 6 over 2 beats', () {
      expect(NnHeart.outlineAt(5.9), 0);
      expect(NnHeart.outlineAt(7), inExclusiveRange(0, 1));
      expect(NnHeart.outlineAt(8), 1);
    });
  });

  group('heartbeat', () {
    const finale = 51.429;
    double at(double lb) => finale + beat.beatToSec(lb);

    test('still before lb 8, a lub-dub on every beat after', () {
      expect(NnHeart.beatScale(at(7.5), finale, beat), 1);
      expect(NnHeart.beatScale(at(8), finale, beat), closeTo(1.05, 1e-6));
      // The dub, 0.16 s later: 0.05 × (e^(−0.16/0.09) + 0.6).
      expect(
        NnHeart.beatScale(at(9) + 0.16, finale, beat),
        closeTo(1 + 0.05 * (math.exp(-0.16 / 0.09) + 0.6), 1e-6),
      );
      // Late in the beat only the dub's tail is left.
      expect(NnHeart.beatScale(at(9.9), finale, beat), lessThan(1.003));
      // It carries on into the Ending.
      expect(NnHeart.beatScale(at(18), finale, beat), closeTo(1.05, 1e-6));
    });

    test('reduced: half the amplitude', () {
      expect(
        NnHeart.beatScale(at(8), finale, beat, reducedFlashing: true),
        closeTo(1.025, 1e-6),
      );
    });
  });

  group('confetti', () {
    test('follows §5.8: from (540, 700), up, then falling', () {
      final start = NnConfetti.piece(1, 0, 0)!;
      expect(start.position.dx, closeTo(540 + 30 * math.sin(0), 1e-9));
      expect(start.position.dy, 700);
      final up = NnConfetti.piece(1, 0, 0.3)!;
      expect(up.position.dy, lessThan(700));
      final down = NnConfetti.piece(1, 0, 3)!;
      expect(down.position.dy, greaterThan(up.position.dy));
    });

    test('opaque until 3 s, gone at 5 s; seeded', () {
      expect(NnConfetti.piece(2, 5, 2.9)!.opacity, 1);
      expect(NnConfetti.piece(2, 5, 4)!.opacity, closeTo(0.5, 1e-9));
      expect(NnConfetti.piece(2, 5, 5.01), isNull);
      expect(NnConfetti.piece(2, 5, -0.01), isNull);
      final a = NnConfetti.piece(1, 7, 1.2)!;
      final b = NnConfetti.piece(1, 7, 1.2)!;
      expect(a.position, b.position);
      expect(a.color, b.color);
      expect(a.size.width, inInclusiveRange(8, 16));
      expect(a.size.height, inInclusiveRange(14, 26));
    });

    test('70 pieces at lb 8, 50 at lb 12', () {
      expect(NnConfetti.bursts, [(1, 70, 8.0), (2, 50, 12.0)]);
    });
  });

  group('flashes', () {
    final timeline = NeonNightCanvas.timelineFor(NeonNightFixtures.reference);
    final finale = timeline.finaleCue;
    final glowUp = finale + beat.beatToSec(8);

    test('the drop 0.5, the glow-up 0.22', () {
      final flash = NeonFlashPainter(
        timeline: timeline,
        time: ValueNotifier(0),
      );
      expect(flash.dropAt(finale), closeTo(0.5, 1e-9));
      expect(flash.dropAt(glowUp), closeTo(0.22, 1e-3));
      expect(flash.dropAt(finale - 0.01), 0);
      // Chapter slams stay pink and separate.
      expect(flash.flashAt(finale), 0);
    });

    test('reduced: 0.12 and 0.08', () {
      final flash = NeonFlashPainter(
        timeline: timeline,
        time: ValueNotifier(0),
        reducedFlashing: true,
      );
      expect(flash.dropAt(finale), closeTo(0.12, 1e-9));
      expect(flash.dropAt(glowUp), closeTo(0.08, 1e-3));
    });
  });

  test('every heart photo decodes tiny, once', () {
    final story = NeonNightFixtures.few;
    final (thumbs: _, large: _, :tiles) = NeonPhotoImages.idsFor(
      story,
      NeonNightCanvas.timelineFor(story),
    );
    expect(tiles.toSet(), {for (final p in story.allPhotos) p.id});
  });

  group('texts', () {
    setUpAll(loadNeonNightFonts);

    test('the headline: its own, else the note, else a default', () {
      expect(
        NnFinaleTexts.headlineFor(NeonNightFixtures.reference, en),
        'BEST NIGHT EVER',
      );
      expect(
        NnFinaleTexts.headlineFor(NeonNightFixtures.few, en),
        'SHORT AND SWEET',
      );
      final bare = NeonNightStory(
        title: 'Rave',
        date: DateTime(2026),
        chapters: NeonNightFixtures.few.chapters,
      );
      expect(NnFinaleTexts.headlineFor(bare, en), 'WHAT A NIGHT');
      expect(NnFinaleTexts.headlineFor(bare, ru), 'ВОТ ЭТО НОЧЬ');
    });

    test('the end card in English and Russian', () {
      String text(TextPainter p) => (p.text! as TextSpan).text!;
      final texts = NeonNightTexts(NeonNightFixtures.reference, en);
      expect(text(texts.ending.totals), '142 PHOTOS · 9 NOTES · 3 TICKS');
      expect(text(texts.ending.titleDate), 'NIGHT OUT · SAT 14 NOV');
      expect(texts.finale.headline.size.width, lessThanOrEqualTo(961));
      texts.dispose();
      final ruTexts = NeonNightTexts(NeonNightFixtures.referenceRu, ru);
      expect(text(ruTexts.ending.totals), '142 ФОТО · 9 ЗАМЕТОК · 3 ОТМЕТКИ');
      ruTexts.dispose();
      expect(ru.neonNight_moments(143), '143 момента');
      expect(ru.neonNight_moments(21), '21 момент');
      expect(en.neonNight_moments(1), '1 moment');
    });

    test('totals counted from the story when none are given', () {
      final totals = NeonNightFixtures.few.endTotals;
      expect(totals.photos, 11);
      expect(totals.notes, 1);
      expect(totals.ticks, 0);
      expect(totals.moments, 11);
    });
  });

  testWidgets('Finale and Ending render the same at the same instant', (
    tester,
  ) async {
    await loadNeonNightFonts();
    final story = NeonNightFixtures.reference;
    final texts = NeonNightTexts(story, en);
    final timeline = NeonNightCanvas.timelineFor(story);
    Future<Uint8List> render(double t) async {
      final time = ValueNotifier(t);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(1080, 1920);
      NeonScenePainter(
        timeline: timeline,
        story: story,
        texts: texts,
        photos: const NoPhotos(),
        time: time,
      ).paint(canvas, size);
      NeonTopPainter(
        timeline: timeline,
        texts: texts,
        time: time,
      ).paint(canvas, size);
      NeonFlashPainter(timeline: timeline, time: time).paint(canvas, size);
      final picture = recorder.endRecording();
      final image = await picture.toImage(270, 480);
      final bytes = await image.toByteData();
      image.dispose();
      picture.dispose();
      return bytes!.buffer.asUint8List();
    }

    await tester.runAsync(() async {
      // Drop, building, outline, glow-up + confetti, headline, fading,
      // end card.
      for (final t in const [51.5, 52.5, 54.3, 55.3, 56.2, 59.3, 62.4]) {
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
