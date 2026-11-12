import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_canvas.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_heart.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_heart_painter.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_story.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_texts.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_timeline.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_tokens.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/gv_random.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_photo_images.dart';
import 'package:traviato/l10n/app_localizations.dart';

import 'gv_placeholder_photos.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const h0 = 52.35;
  final heart = GoldenVowsHeart(start: h0, photoCount: 64);

  group('cells (spec §5.4, matching a Python port of the JS)', () {
    test('counts and sizes for 20, 64 and 200 photos', () {
      for (final (photos, cells, size) in const [
        (1, 42, 111.1),
        (20, 42, 111.1),
        (64, 62, 89.9),
        (120, 116, 64.5),
        (200, 200, 49.9),
      ]) {
        final (c, list) = GoldenVowsHeart.layout(photos);
        expect(list, hasLength(cells), reason: '$photos photos');
        expect(c, closeTo(size, 0.05), reason: '$photos photos');
      }
    });

    test('every cell is inside the heart curve, top rows first', () {
      final (_, cells) = GoldenVowsHeart.layout(64);
      for (final cell in cells) {
        final x = (cell.dx - 540) / 370;
        final y = -(cell.dy - 900) / 370 + 0.1;
        final a = x * x + y * y - 1;
        expect(a * a * a - x * x * y * y * y, lessThanOrEqualTo(0));
      }
      for (var i = 1; i < cells.length; i++) {
        expect(cells[i].dy, greaterThanOrEqualTo(cells[i - 1].dy));
      }
    });
  });

  group('seeded tiles and confetti', () {
    test('tiles start 1450 px out, in seed 53 order', () {
      final r = GvRandom(53);
      final a = r.next() * 2 * math.pi;
      final tilt = r.next() * 70 - 35;
      final first = heart.tiles.first;
      expect(first.start.dx, closeTo(540 + 1450 * math.cos(a), 1e-9));
      expect(first.start.dy, closeTo(900 + 1450 * math.sin(a), 1e-9));
      expect(first.tiltDeg, closeTo(tilt, 1e-9));
      for (final tile in heart.tiles) {
        expect(
          (tile.start - GoldenVowsHeart.centre).distance,
          closeTo(1450, 1e-6),
        );
      }
    });

    test('photos repeat only below 44', () {
      final few = GoldenVowsHeart(start: 0, photoCount: 20);
      expect(few.tiles, hasLength(42));
      expect({for (final t in few.tiles) t.photo}, hasLength(20));
      expect(
        [for (final t in heart.tiles) t.photo],
        [
          for (var i = 0; i < 62; i++) i,
        ],
      );
      expect(GoldenVowsHeart(start: 0, photoCount: 0).isEmpty, isTrue);
    });

    test('54 confetti pieces: seed 29, 7 draws each, colours cycling', () {
      expect(heart.confetti, hasLength(54));
      final r = GvRandom(29);
      final a = r.next() * 2 * math.pi;
      final d = 260 + r.next() * 520;
      final w = 10 + r.next() * 16;
      final h = 6 + r.next() * 8;
      final rot = r.next() * 720 - 360;
      final fall = 500 + r.next() * 500;
      final round = r.next() > 0.7;
      final first = heart.confetti.first;
      expect(first.burst.dx, closeTo(math.cos(a) * d, 1e-9));
      expect(first.burst.dy, closeTo(math.sin(a) * d * 0.9 - 120, 1e-9));
      expect(first.width, closeTo(w, 1e-9));
      expect(first.height, closeTo(h, 1e-9));
      expect(first.rotDeg, closeTo(rot, 1e-9));
      expect(first.fall, closeTo(fall, 1e-9));
      expect(first.round, round);
      expect(first.color, GoldenVowsColors.gold);
      expect(heart.confetti[4].color, GoldenVowsColors.goldDeep);
      expect(heart.confetti[5].color, GoldenVowsColors.gold);
      // The next piece starts on the 8th draw.
      final next = r.next() * 2 * math.pi;
      final nd = 260 + r.next() * 520;
      expect(heart.confetti[1].burst.dx, closeTo(math.cos(next) * nd, 1e-9));
    });
  });

  group('motion (from h0)', () {
    test('tile i flies in from h0 + 0.2 + 2.0·i/M over 1.2 s', () {
      final first = heart.tiles.first;
      expect(heart.tileAt(0, h0 + 0.2).centre, _near(first.start));
      final settled = heart.tileAt(0, h0 + 1.4);
      expect(settled.centre, _near(first.cell));
      expect(settled.angleDeg, closeTo(0, 1e-9));
      final last = heart.tiles.length - 1;
      final lastStart = h0 + 0.2 + last / heart.tiles.length * 2.0;
      expect(
        heart.tileAt(last, lastStart).centre,
        _near(heart.tiles[last].start),
      );
      expect(
        heart.tileAt(last, lastStart + 1.2).centre,
        _near(heart.tiles[last].cell),
      );
    });

    test('two beats to 1.05 from +3.4, 0.35 s legs', () {
      expect(heart.beatScaleAt(h0 + 3.4), closeTo(1, 1e-9));
      expect(heart.beatScaleAt(h0 + 3.75), closeTo(1.05, 1e-9));
      expect(heart.beatScaleAt(h0 + 4.1), closeTo(1, 1e-9));
      expect(heart.beatScaleAt(h0 + 4.45), closeTo(1.05, 1e-9));
      expect(heart.beatScaleAt(h0 + 4.8), closeTo(1, 1e-9));
    });

    test('confetti bursts at +3.45, falls and fades from +4.55', () {
      final piece = heart.confetti.first;
      expect(heart.confettiAt(0, h0 + 3.4).opacity, 0);
      final out = heart.confettiAt(0, h0 + 4.55);
      expect(out.centre.dx, closeTo(540 + piece.burst.dx, 1e-9));
      expect(out.angleDeg, closeTo(piece.rotDeg, 1e-9));
      expect(out.opacity, 1);
      final down = heart.confettiAt(0, h0 + 4.55 + 2.6);
      expect(down.centre.dy, closeTo(900 + piece.burst.dy + piece.fall, 1e-9));
      expect(down.angleDeg, closeTo(2 * piece.rotDeg, 1e-9));
      expect(down.opacity, closeTo(0, 1e-9));
    });

    test('ropes, basket and line come in; the line leaves', () {
      expect(heart.ropeAt(0, h0 + 4.0), closeTo(0, 1e-9));
      expect(heart.ropeAt(0, h0 + 4.8), closeTo(1, 1e-9));
      expect(heart.ropeAt(1, h0 + 4.8), lessThan(1));
      expect(heart.basketAt(h0 + 4.6).dy, closeTo(32, 1e-9));
      expect(heart.basketAt(h0 + 5.2).dy, closeTo(0, 1e-9));
      expect(heart.basketAt(h0 + 5.2).opacity, 1);
      expect(heart.lineAt(h0 + 4.4).top, closeTo(1560, 1e-9));
      expect(heart.lineAt(h0 + 5.6).top, closeTo(1520, 1e-9));
      expect(heart.lineAt(h0 + 5.6).opacity, closeTo(1, 1e-9));
      expect(heart.lineAt(h0 + 6.8).opacity, closeTo(0, 1e-9));
    });

    test('the balloon rises to −2100 tilting 3°, gone by close + 1.4', () {
      expect(heart.riseAt(h0 + 6.2).dy, closeTo(0, 1e-9));
      final up = heart.riseAt(h0 + 9.0);
      expect(up.dy, closeTo(-2100, 1e-9));
      expect(up.angleDeg, closeTo(3, 1e-9));
      final timeline = GoldenVowsTimeline.reference();
      expect(
        h0 + GoldenVowsHeart.length,
        closeTo(timeline.closeStart + 1.4, 1e-9),
      );
      expect(heart.visibleAt(h0 + GoldenVowsHeart.length), isFalse);
    });
  });

  group('story', () {
    test('moments count the heart photos, capped at 200 for the heart', () {
      final story = GoldenVowsStory(
        names: 'A',
        date: DateTime(2026),
        heartPhotoIds: GoldenVowsFixtures.heartIds(230),
      );
      expect(story.momentCount, 230);
      expect(story.heartPhotos, hasLength(200));
    });

    test('the end line is the memory’s own, else the default', () {
      final en = lookupAppLocalizations(const Locale('en'));
      final own = GoldenVowsTexts(
        GoldenVowsStory(names: 'A', date: DateTime(2026), endLine: 'Always'),
        en,
      );
      expect(own.album.endLine.plainText, 'Always');
      own.dispose();
      final fallback = GoldenVowsTexts(GoldenVowsFixtures.wedding, en);
      expect(fallback.album.endLine.plainText, 'Forever starts here');
      fallback.dispose();
    });
  });

  testWidgets('the same instant renders the same pixels (export-ready)', (
    tester,
  ) async {
    for (final (family, asset) in const [
      ('CormorantGaramond', 'assets/fonts/CormorantGaramond[wght].ttf'),
      ('PinyonScript', 'assets/fonts/PinyonScript-Regular.ttf'),
      ('GreatVibes', 'assets/fonts/GreatVibes-Regular.ttf'),
    ]) {
      await tester.runAsync(
        () => (FontLoader(family)..addFont(rootBundle.load(asset))).load(),
      );
    }
    final story = GoldenVowsFixtures.wedding;
    final texts = GoldenVowsTexts(
      story,
      lookupAppLocalizations(const Locale('en')),
    );
    late final Map<String, MemoryImage> photos;
    final images = SkyPhotoImages(
      (id) => GoldenVowsCanvas.heartImage(photos[id]!),
    );
    await tester.runAsync(() async {
      photos = await GvPlaceholderPhotos.generate(hearts: 64);
      images.load(story.heartPhotos);
      await images.ready;
    });
    expect(images.loadedCount, 64);

    Future<Uint8List> render(double t) async {
      final recorder = ui.PictureRecorder();
      GoldenVowsHeartPainter(
        heart: heart,
        photoIds: story.heartPhotos,
        images: images,
        texts: texts.album,
        time: ValueNotifier(t),
      ).paint(Canvas(recorder), const Size(1080, 1920));
      final picture = recorder.endRecording();
      final image = await picture.toImage(1080, 1920);
      final bytes = await image.toByteData();
      image.dispose();
      picture.dispose();
      return bytes!.buffer.asUint8List();
    }

    await tester.runAsync(() async {
      for (final t in const [53.2, 55.9, 57.3, 59.4]) {
        expect(listEquals(await render(t), await render(t)), isTrue);
      }
    });
    images.dispose();
    texts.dispose();
  });
}

Matcher _near(Offset expected) => predicate<Offset>(
  (actual) => (actual - expected).distance < 1e-6,
  'within 1e-6 of $expected',
);
