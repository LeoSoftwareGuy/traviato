import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_album.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_album_painter.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_scene_spec.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_story.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_texts.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_timeline.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_photo_images.dart';
import 'package:traviato/l10n/app_localizations.dart';

import 'gv_placeholder_photos.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final album = GoldenVowsAlbum(GoldenVowsTimeline.reference());
  final en = lookupAppLocalizations(const Locale('en'));
  final ru = lookupAppLocalizations(const Locale('ru'));

  setUpAll(() async {
    for (final (family, asset) in const [
      ('CormorantGaramond', 'assets/fonts/CormorantGaramond[wght].ttf'),
      ('PinyonScript', 'assets/fonts/PinyonScript-Regular.ttf'),
      ('GreatVibes', 'assets/fonts/GreatVibes-Regular.ttf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
    }
  });

  group('leaves (spec §5.3 table)', () {
    test('the cover, 4 heroes, 3 chapters, the carousel and the heart', () {
      expect(album.leaves.first.page, isNull);
      expect(
        [for (final leaf in album.leaves.skip(1)) leaf.page!.kind],
        [
          ...List.filled(4, GvPageKind.hero),
          ...List.filled(3, GvPageKind.chapter),
          GvPageKind.carousel,
          GvPageKind.heart,
        ],
      );
    });

    test('turn at the spec times; each shows from the turn above it', () {
      final turns = [for (final leaf in album.leaves) leaf.turnAt];
      const expected = [
        12.9,
        17.15,
        21.40,
        25.65,
        29.90,
        34.55,
        39.20,
        43.85,
        51.10,
      ];
      for (var i = 0; i < expected.length; i++) {
        expect(turns[i], closeTo(expected[i], 1e-9));
      }
      expect(turns.last, isNull);
      expect(album.leaves.first.showFrom, closeTo(11.9, 1e-9));
      for (var i = 1; i < album.leaves.length; i++) {
        expect(album.leaves[i].showFrom, album.leaves[i - 1].turnAt);
      }
    });

    test('a memory with no chapters or carousel goes hero → heart', () {
      final short = GoldenVowsAlbum(
        GoldenVowsTimeline.forStory(
          GoldenVowsStory(
            names: 'A & B',
            date: DateTime(2026),
            heroes: const [GvHero(photoId: 'p')],
          ),
        ),
      );
      expect(
        [for (final leaf in short.leaves) leaf.page?.kind],
        [
          null,
          GvPageKind.hero,
          GvPageKind.heart,
        ],
      );
      // No packing card: the album rises as the invitation ends.
      expect(short.riseAt, closeTo(5.4, 1e-9));
    });
  });

  group('motion', () {
    test('the album rises from 11.9 and leaves after the close', () {
      expect(album.visibleAt(11.8), isFalse);
      expect(album.bodyAt(11.9).dy, 1950);
      expect(album.bodyAt(11.9).angleDeg, 3);
      expect(album.bodyAt(13.1).dy, closeTo(0, 1e-9));
      final gone = album.bodyAt(61.35 + 1.0);
      expect(gone.dy, closeTo(-320, 1e-9));
      expect(gone.scale, closeTo(0.92, 1e-9));
      expect(gone.opacity, closeTo(0, 1e-9));
      expect(album.visibleAt(62.4), isFalse);
    });

    test('the top leaf follows the turns', () {
      expect(album.topAt(13.0), 0);
      expect(album.topAt(14.1), 0);
      expect(album.topAt(14.2), 1);
      expect(album.topAt(55), album.leaves.length - 1);
      expect(album.topAt(60), 0, reason: 'the cover swings back');
    });

    test('a turn: 0° → −100°, shade to 0.32, fade at the end', () {
      expect(album.turnAt(1, 17.0).angleDeg, 0);
      final mid = album.turnAt(1, 17.15 + 0.625);
      expect(mid.angleDeg, closeTo(-50, 1e-9));
      expect(album.turnAt(1, 17.15 + 0.875).shade, closeTo(0.32, 1e-9));
      expect(album.turnAt(1, 17.15 + 0.9).opacity, 1);
      final end = album.turnAt(1, 17.15 + 1.25);
      expect(end.angleDeg, closeTo(-100, 1e-9));
      expect(end.opacity, closeTo(0, 1e-9));
    });

    test('the cover swings back at the close as its shade clears', () {
      final start = album.turnAt(0, 59.95);
      expect(start.angleDeg, closeTo(-100, 1e-9));
      expect(start.shade, closeTo(0.32, 1e-9));
      final shut = album.turnAt(0, 59.95 + 1.3);
      expect(shut.angleDeg, closeTo(0, 1e-9));
      expect(shut.shade, closeTo(0, 1e-9));
    });

    test('photos zoom 1 → 1.08 over their page’s visible life', () {
      expect(album.zoomAt(1, 12.9), 1);
      expect(album.zoomAt(1, 18.4), closeTo(1.08, 1e-9));
      expect(album.zoomAt(1, 15.6), allOf(greaterThan(1), lessThan(1.08)));
    });

    test('the carousel slides over its 8.5 s', () {
      final carousel = album.leaves.indexWhere(
        (leaf) => leaf.page?.kind == GvPageKind.carousel,
      );
      expect(album.slideAt(carousel, 43.85), 0);
      expect(album.slideAt(carousel, 43.85 + 4.25), closeTo(0.5, 1e-9));
      expect(album.slideAt(carousel, 52.35), closeTo(1, 1e-9));
    });

    test('the hinge keeps the spine fixed and swings the free edge', () {
      for (final angle in const [-20.0, -81.0, -100.0]) {
        final m = GoldenVowsAlbum.hinge(angle);
        expect(
          MatrixUtils.transformPoint(m, const Offset(70, 500)).dx,
          closeTo(70, 1e-6),
        );
      }
      // Past 90° the free edge is across the spine.
      final edge = MatrixUtils.transformPoint(
        GoldenVowsAlbum.hinge(-81.3),
        const Offset(1010, 960),
      );
      expect(edge.dx, closeTo(291, 3), reason: 'matches the 13.7 s still');
    });
  });

  group('layouts', () {
    test('carousel print widths follow the aspect, clamped', () {
      expect(GvCarouselLayout.printWidth(1), 460);
      expect(GvCarouselLayout.printWidth(0.5), 292 + 30);
      expect(GvCarouselLayout.printWidth(2), 624 + 30);
      expect(GvCarouselLayout.rowWidth(const [100, 100, 100]), 372);
      expect(GvCarouselLayout.rowX(0, 2000, 0), 40);
      expect(GvCarouselLayout.rowX(0, 2000, 1), -1460);
      expect(GvCarouselLayout.rowX(1, 2000, 0), -1130);
      expect(GvCarouselLayout.rowX(1, 2000, 1), 370);
      expect(GvCarouselLayout.rows([1, 2, 3, 4, 5]), [
        [1, 2, 3],
        [4, 5],
      ]);
    });

    test('chapters cycle layouts A, B, C', () {
      expect(GvChapterLayouts.forChapter(0), GvChapterLayouts.a);
      expect(GvChapterLayouts.forChapter(1), GvChapterLayouts.b);
      expect(GvChapterLayouts.forChapter(2), GvChapterLayouts.c);
      expect(GvChapterLayouts.forChapter(3), GvChapterLayouts.a);
    });

    test('photos are cover-cropped, centred, and zoom in', () {
      const box = Size(712, 800);
      final wide = gvCoverCrop(
        const Size(1500, 1000),
        box,
        1,
      );
      expect(wide.height, closeTo(1000, 1e-9));
      expect(wide.width / wide.height, closeTo(712 / 800, 1e-9));
      expect(wide.center.dx, closeTo(750, 1e-9));
      expect(wide.center.dy, closeTo(500, 1e-9));
      final tall = gvCoverCrop(
        const Size(600, 1200),
        box,
        1.08,
      );
      expect(tall.width, closeTo(600 / 1.08, 1e-9));
      expect(tall.center.dx, closeTo(300, 1e-9));
      expect(tall.center.dy, closeTo(600, 1e-9));
    });
  });

  group('texts', () {
    test('captions and chapter lines are uppercase; long notes fit', () {
      final texts = GoldenVowsTexts(
        GoldenVowsStory(
          names: 'A & B',
          date: DateTime(2026),
          heroes: const [
            GvHero(
              photoId: 'p',
              caption: 'The vows · 15:10',
              note:
                  'A much longer note than the card was ever meant to hold, '
                  'going on and on about the day',
            ),
            GvHero(photoId: 'q'),
          ],
          chapters: const [
            GvChapter(
              title: 'Getting ready',
              line: 'Chapter one · Morning',
              photoIds: ['a', 'b', 'c'],
            ),
          ],
        ),
        en,
      );
      final hero = texts.album.heroes.first;
      expect(hero.caption!.plainText, 'THE VOWS · 15:10');
      expect(hero.note!.width, lessThanOrEqualTo(GvHeroTexts.noteMaxWidth));
      expect(hero.note!.height, lessThanOrEqualTo(190));
      expect(texts.album.heroes.last.caption, isNull);
      expect(texts.album.heroes.last.note, isNull);
      expect(
        texts.album.chapters.single.line!.plainText,
        'CHAPTER ONE · MORNING',
      );
      expect(texts.album.carousel, isNull);
      texts.dispose();
    });

    test('the heart page counts moments and days in each language', () {
      final story = GoldenVowsFixtures.wedding;
      final english = GoldenVowsTexts(story, en);
      expect(english.album.heart.title.plainText, 'Every moment');
      expect(english.album.heart.line!.plainText, '64 MOMENTS · ONE DAY');
      english.dispose();
      final russian = GoldenVowsTexts(
        GoldenVowsStory(
          names: 'A',
          date: DateTime(2026),
          heartPhotoIds: GoldenVowsFixtures.heartIds(21),
          dayCount: 3,
        ),
        ru,
      );
      expect(russian.album.heart.line!.plainText, '21 МОМЕНТ · 3 ДНЯ');
      russian.dispose();
    });
  });

  test('the album shows each photo once, in order', () {
    final ids = GoldenVowsFixtures.wedding.albumPhotoIds;
    expect(ids, hasLength(4 + 9 + 12));
    expect(ids.first, 'hero-1');
    expect(ids.last, 'carousel-12');
    expect(ids.toSet(), hasLength(ids.length));
  });

  testWidgets('the same instant renders the same pixels (export-ready)', (
    tester,
  ) async {
    final texts = GoldenVowsTexts(GoldenVowsFixtures.wedding, en);
    late final Map<String, MemoryImage> photos;
    await tester.pumpWidget(const SizedBox());
    final context = tester.element(find.byType(SizedBox));
    final images = SkyPhotoImages((id) => photos[id]);
    await tester.runAsync(() async {
      photos = await GvPlaceholderPhotos.generate();
      for (final photo in photos.values) {
        await precacheImage(photo, context);
      }
      images.load(GoldenVowsFixtures.wedding.albumPhotoIds);
      await images.ready;
    });
    expect(images.loadedCount, 25);

    Future<Uint8List> render(double t) async {
      final recorder = ui.PictureRecorder();
      GoldenVowsAlbumPainter(
        album: album,
        story: GoldenVowsFixtures.wedding,
        texts: texts.album,
        images: images,
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
      for (final t in const [13.7, 20.0, 33.0, 48.0, 60.4]) {
        expect(listEquals(await render(t), await render(t)), isTrue);
      }
    });
    images.dispose();
    texts.dispose();
  });
}
