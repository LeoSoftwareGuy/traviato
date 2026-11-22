import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_beat.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_moments.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_canvas.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_scene_spec.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_story.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_texts.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_scene_painter.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_tokens.dart';
import 'package:traviato/l10n/app_localizations.dart';

import 'neon_test_fonts.dart';
import 'neon_test_photos.dart';

void main() {
  const beat = NeonBeat();
  final en = lookupAppLocalizations(const ui.Locale('en'));
  final ru = lookupAppLocalizations(const ui.Locale('ru'));

  group('split (§5.4a)', () {
    test('strips: sw 316 for 3, 487 for 2, 26 apart from x 40', () {
      expect(NnSplitLayout.stripWidth(3), closeTo(316, 0.01));
      expect(NnSplitLayout.stripWidth(2), 487);
      expect(NnSplitLayout.strip(0, 3).left, 40);
      expect(NnSplitLayout.strip(0, 3).width, closeTo(316, 0.01));
      expect(NnSplitLayout.strip(2, 3).right, closeTo(1040, 1e-9));
      expect(NnSplitLayout.strip(1, 2).left, 40 + 487 + 26);
    });

    test('each strip wipes down from lb 0.5 i over 0.45 s', () {
      expect(NnSplitLayout.wipe(0.99, 2, beat), 0);
      expect(NnSplitLayout.wipe(1.1, 2, beat), inExclusiveRange(0, 1));
      expect(NnSplitLayout.wipe(1 + beat.secToBeat(0.45), 2, beat), 1);
      expect(NnSplitLayout.pulses(1), [3, 6]);
    });
  });

  group('burst (§5.4b)', () {
    test('frame i pops in from 1.25× at lb 1 + i, opaque after 0.13 s', () {
      expect(NnBurstLayout.pop(1.9, 1, beat), (0.0, 0.0));
      final (scale, alpha) = NnBurstLayout.pop(2, 1, beat);
      expect(scale, 1.25);
      expect(alpha, 0);
      final (settled, opaque) = NnBurstLayout.pop(
        2 + beat.secToBeat(0.4),
        1,
        beat,
      );
      expect(settled, closeTo(1, 1e-9));
      expect(opaque, 1);
    });

    test('frame i jumps to the front for a beat from lb 5 + i', () {
      expect(NnBurstLayout.jump(5.5, 0), 1.06);
      expect(NnBurstLayout.jump(5.8, 0), inExclusiveRange(1, 1.06));
      expect(NnBurstLayout.jump(6, 0), isNull);
      expect(NnBurstLayout.order(4, 4), [0, 1, 2, 3]);
      expect(NnBurstLayout.order(5.2, 4), [1, 2, 3, 0]);
      expect(NnBurstLayout.order(7.5, 4), [0, 1, 3, 2]);
    });
  });

  group('timeline (§5.5b)', () {
    test('masonry: each item goes in the shorter column', () {
      final layout = NnTimelineLayout(8);
      final items = layout.items;
      expect(items[0], const Rect.fromLTWH(70, 330, 440, 280));
      // Item 1 is tall and goes right.
      expect(items[1], const Rect.fromLTWH(570, 330, 440, 560));
      expect(items[2], const Rect.fromLTWH(70, 710, 440, 280));
      expect(items[3].left, 570);
      expect(items[3].top, 990);
      expect(items[6].height, 560);
      expect(layout.maxScroll, layout.contentBottom - 1540);
    });

    test('the highlight moves one item a beat from lb 2, then holds', () {
      final layout = NnTimelineLayout(3);
      expect(layout.highlightAt(1.9), isNull);
      expect(layout.highlightAt(2), 0);
      expect(layout.highlightAt(4.5), 2);
      expect(layout.highlightAt(11), 2);
    });

    test('the list scrolls to centre the highlight, within its range', () {
      final layout = NnTimelineLayout(8);
      expect(layout.scrollAt(1.5, beat), 0);
      // Item 0 is above the middle: no scroll.
      expect(layout.scrollFor(0), 0);
      final last = layout.scrollFor(7);
      expect(last, lessThanOrEqualTo(layout.maxScroll));
      expect(layout.scrollAt(11.5, beat), last);
      // Mid-scroll, between the two items' scrolls.
      final j = 5;
      final mid = layout.scrollAt(2 + j + beat.secToBeat(0.175), beat);
      expect(
        mid,
        inInclusiveRange(layout.scrollFor(j - 1), layout.scrollFor(j)),
      );
      // A short timeline never scrolls.
      expect(NnTimelineLayout(3).maxScroll, 0);
    });
  });

  group('peak (§5.6b)', () {
    test('strips 16° apart, centre green, outer ones painted first', () {
      expect(
        [for (var i = 0; i < 5; i++) NnPeakLayout.degrees(i, 5)],
        [
          -32,
          -16,
          0,
          16,
          32,
        ],
      );
      expect(NnPeakLayout.degrees(0, 3), -16);
      expect(NnPeakLayout.color(2, 5), NeonColors.green);
      expect(NnPeakLayout.color(1, 5), NeonColors.pink);
      expect(NnPeakLayout.color(1, 4), NeonColors.pink);
      expect(NnPeakLayout.order(1, 5), [0, 4, 1, 3, 2]);
      // The pulsing strip comes to the top.
      expect(NnPeakLayout.order(3.5, 5).last, 1);
    });

    test('the strips pop open from 0°, 0.08 s apart', () {
      expect(NnPeakLayout.degreesAt(0, 0, 5, beat), closeTo(0, 1e-9));
      expect(NnPeakLayout.degreesAt(beat.secToBeat(0.6), 0, 5, beat), -32);
      expect(
        NnPeakLayout.degreesAt(beat.secToBeat(0.6), 4, 5, beat),
        isNot(32),
      );
    });

    test('the fan: 9 beams −80…+80°, cyan and pink', () {
      expect(NnPeakLayout.beamDegrees(0), -80);
      expect(NnPeakLayout.beamDegrees(8), 80);
      expect(NnPeakLayout.beamColor(0), NeonColors.cyan);
      expect(NnPeakLayout.beamColor(1), NeonColors.pink);
    });
  });

  test("the timeline follows each chapter's moments", () {
    final timeline = NeonNightCanvas.timelineFor(NeonNightFixtures.few);
    expect(
      [
        for (final scene in timeline.scenes)
          if (scene.spec case NnMomentSpec(:final type)) type,
      ],
      [
        NnMomentType.split,
        NnMomentType.burst,
        NnMomentType.timeline,
        NnMomentType.peak,
      ],
    );
    expect(
      NeonNightCanvas.timelineFor(NeonNightFixtures.reference).totalBeats,
      // The spec's 136, plus a bar to read the note (#399), plus a bar
      // on each two-zoom card for the ~2.4 s zooms (#448).
      148,
    );
  });

  group('labels', () {
    setUpAll(loadNeonNightFonts);

    String label(NnMomentTexts texts) => (texts as NnLabelTexts).label!.text;

    test('split: time · place; burst: BURST · time; peak: first → last', () {
      final texts = NeonNightTexts(NeonNightFixtures.reference, en);
      final ch1 = texts.chapters[0].moments;
      expect(label(ch1[0]), '23:10 · MAIN STAGE');
      expect(label(ch1[1]), 'BURST · 23:31');
      final timeline = texts.chapters[1].moments.single as NnTimelineTexts;
      expect(timeline.times, hasLength(8));
      expect(
        timeline.title.size.width,
        lessThanOrEqualTo(NnTimelineTexts.titleWidth + 1),
      );
      final peak = texts.chapters[2].moments.single as NnPeakTexts;
      expect((peak.range.text! as TextSpan).text, '00:10 → 00:37');
      expect(
        peak.title.size.width,
        lessThanOrEqualTo(NnPeakTexts.titleWidth + 1),
      );
      texts.dispose();
    });

    test('in Russian, and without a place', () {
      final texts = NeonNightTexts(NeonNightFixtures.referenceRu, ru);
      expect(label(texts.chapters[0].moments[0]), '23:10 · ГЛАВНАЯ СЦЕНА');
      expect(label(texts.chapters[0].moments[1]), 'СЕРИЯ · 23:31');
      texts.dispose();
      final few = NeonNightTexts(NeonNightFixtures.few, en);
      expect(label(few.chapters[0].moments.single), '23:00');
      few.dispose();
    });

    test('a captioned photo never shows its time (#456)', () {
      const chapter = [
        NnPhoto(id: 'a', takenAt: '13:10'),
        NnPhoto(id: 'b', takenAt: '13:12'),
        NnPhoto(id: 'c', takenAt: '13:14'),
      ];
      final quiet = [
        const NnPhoto(id: 'd', takenAt: '13:19', caption: 'coffee shop').quiet,
        const NnPhoto(id: 'e', takenAt: '14:25', caption: 'our castle').quiet,
      ];
      NnChapter withMoment(NnMoment moment) => NnChapter(
        title: 'Амстердам',
        from: '13:10',
        to: '14:25',
        photos: [...chapter, ...moment.photos],
        cardPhotos: chapter,
        moments: [moment],
      );
      final split = NnMomentTexts(
        NnSplit(quiet),
        withMoment(NnSplit(quiet)),
        en,
      );
      expect((split as NnLabelTexts).label, isNull);
      final placed = NnMomentTexts(
        NnSplit(quiet, place: 'Dam'),
        withMoment(NnSplit(quiet)),
        en,
      );
      expect(label(placed), 'DAM');
      final burst = NnMomentTexts(
        NnBurst(quiet),
        withMoment(NnBurst(quiet)),
        en,
      );
      expect(label(burst), 'BURST');
      final timeline = [
        ...quiet,
        ...chapter,
      ]..sort((a, b) => a.takenAt.compareTo(b.takenAt));
      final lit =
          NnMomentTexts(
                NnTimeline(timeline),
                withMoment(NnTimeline(timeline)),
                en,
              )
              as NnTimelineTexts;
      for (final (i, photo) in timeline.indexed) {
        final (plain, _) = lit.times[i];
        expect(
          (plain.text! as TextSpan).text,
          photo.captioned ? '' : photo.takenAt,
        );
      }
      for (final t in [split, placed, burst, lit]) {
        t.dispose();
      }
    });
  });

  testWidgets('moments render the same at the same instant', (tester) async {
    await loadNeonNightFonts();
    final story = NeonNightFixtures.reference;
    final texts = NeonNightTexts(story, en);
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
      // Wiping, pulsing, popping, jumping, scrolling, the peak's glitch.
      for (final t in const [17.5, 19.05, 21.5, 23.33, 29.8, 31.9, 42.0]) {
        expect(
          listEquals(await render(t), await render(t)),
          isTrue,
          reason: 't = $t',
        );
      }
    });
    texts.dispose();
  });

  group('captions (#387)', () {
    setUpAll(loadNeonNightFonts);

    NnChapter chapter(List<NnPhoto> photos) => NnChapter(
      title: 'Doors open',
      from: '22:00',
      to: '23:00',
      photos: photos,
      moments: [NnTimeline(photos)],
    );

    test('a timeline item shows its time — a captioned one its caption or '
        'nothing (#456); the lit one its caption, large, and holds the '
        'highlight while it is read (#399 T2)', () {
      final photos = [
        const NnPhoto(id: 'a', takenAt: '22:10', caption: 'Lost the keys'),
        const NnPhoto(id: 'b', takenAt: '22:20'),
        NnPhoto(id: 'c', takenAt: '22:30', caption: 'word ' * 40),
      ];
      final texts = NnTimelineTexts(NnTimeline(photos), chapter(photos));
      String time(int i) => (texts.times[i].$1.text! as TextSpan).text!;
      expect([time(0), time(1), time(2)], ['', '22:20', '']);
      expect(texts.captions[0]!.text, 'Lost the keys');
      expect(texts.captions[1], isNull);
      // Too long for 3 lines: left out, never cut.
      expect(texts.captions[2], isNull);
      // 'Lost the keys': zoom in 0.35 + 0.8 + 13/12 + zoom out 0.3 s
      // ≈ 2.5 s → 6 beats at 126 bpm (#426).
      expect(NnTimelineTexts.holdsFor(texts.captions, const NeonBeat()), [
        6,
        1,
        1,
      ]);
      final layout = NnTimelineLayout(3, holds: const [4, 1, 1]);
      expect(layout.highlightAt(5.9), 0);
      expect(layout.highlightAt(6), 1);
      expect(layout.highlightAt(7), 2);
      texts.dispose();
    });

    test("a zoom's label is the photo's caption, else its time", () {
      final story = NeonNightFixtures.reference;
      final first = story.chapters.first;
      final captioned = NeonNightStory(
        title: story.title,
        date: story.date,
        plan: story.plan,
        chapters: [
          NnChapter(
            title: first.title,
            from: first.from,
            to: first.to,
            photos: [
              for (final p in first.photos)
                NnPhoto(
                  id: p.id,
                  takenAt: p.takenAt,
                  caption: 'Caption ${p.id}',
                ),
            ],
            moments: first.moments,
            note: first.note,
          ),
          ...story.chapters.skip(1),
        ],
        note: story.note,
        headline: story.headline,
        firstName: story.firstName,
        totals: story.totals,
      );
      final texts = NeonNightTexts(captioned, en);
      final labels = texts.chapters.first.tileLabels;
      expect(labels, isNotEmpty);
      for (final MapEntry(:key, :value) in labels.entries) {
        expect(value.text, 'Caption ${first.photos[key].id}');
      }
      final plain = NeonNightTexts(story, en).chapters.first.tileLabels;
      expect(plain.values.first.text, matches(RegExp(r'^\d\d:\d\d$')));
      texts.dispose();
    });
  });
}
