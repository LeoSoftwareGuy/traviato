import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_beat.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_canvas.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_scene_spec.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_story.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_texts.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_reading_time.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_track.dart';
import 'package:traviato/l10n/app_localizations.dart';

import 'neon_test_fonts.dart';

/// Neon Night shows the user's words whole, long enough to read (#399).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final en = lookupAppLocalizations(const ui.Locale('en'));
  const beat = NeonBeat();
  setUpAll(loadNeonNightFonts);

  NnPhoto photo(String id, String at, [String? caption]) =>
      NnPhoto(id: id, takenAt: at, caption: caption);

  NeonNightStory night(List<NnChapter> chapters, {NnTotals? totals}) =>
      NeonNightStory(
        title: 'ADE',
        date: DateTime(2026, 10, 17),
        chapters: chapters,
        totals: totals,
      );

  group('the typed line (T1)', () {
    test('a full excerpt wraps to 3 lines, no cut', () {
      const note = 'Waiting for a metre and a half of ribs: we ordered 4.5 kg';
      expect(NnChapterTexts.typedTextFor(note), note);
      final photos = [photo('a', '18:25'), photo('b', '18:40')];
      final story = night([
        NnChapter(
          title: 'Ribs',
          from: '18:25',
          to: '19:00',
          photos: photos,
          moments: [NnSplit(photos)],
          note: note,
        ),
      ]);
      final texts = NnChapterTexts(story, 0, en);
      expect(texts.typedLines, inInclusiveRange(2, 3));
      expect((texts.typed!.text! as TextSpan).text, isNot(contains('…')));
      texts.dispose();
    });

    test('too long: its first whole sentences; nothing when none fits', () {
      final long = [
        'We waited for ribs.',
        for (var i = 0; i < 8; i++) 'Then we danced until the morning came.',
      ].join(' ');
      expect(NnChapterTexts.typedTextFor(long), startsWith('We waited'));
      expect(NnChapterTexts.typedTextFor(long), endsWith('.'));
      expect(
        NnChapterTexts.typedTextFor(List.filled(80, 'word').join(' ')),
        isNull,
      );
    });

    test('the card plays long enough to type and read it', () {
      const note =
          'The best set I have ever heard, we stayed until the lights came on';
      final beats = NnReadingTime.cardBeats(
        NnChapter(
          title: 'AMF',
          from: '01:04',
          to: '05:00',
          photos: [photo('a', '01:04')],
          moments: [
            NnTimeline([photo('a', '01:04'), photo('b', '01:10')]),
          ],
          note: note,
        ),
        beat,
      );
      // Typed from lb 4, read for 0.8 + 66/12 s ≈ 6.3 s (13.2 beats).
      expect(beats, 20);
      expect(beats % 4, 0);
    });
  });

  group('captions (T1)', () {
    test('a captioned split shows each caption in turn, the moment '
        'growing by whole bars', () {
      final photos = [
        photo('a', '23:10', 'боча пролил пиво'),
        photo('b', '23:20', 'боча застрял в толчке'),
      ];
      final split = NnSplit(photos);
      final texts = NnMomentTexts(
        split,
        NnChapter(
          title: 'Club',
          from: '23:00',
          to: '00:00',
          photos: photos,
          moments: [split],
        ),
        en,
      );
      final labels = texts as NnLabelTexts;
      expect(
        [for (final c in labels.captions) c.text],
        [
          'боча пролил пиво',
          'боча застрял в толчке',
        ],
      );
      // 2.1 + 2.55 s of reading from lb 1 → 12 beats, not the spec's 8.
      expect(NnReadingTime.momentBeats(split, beat), 12);
      texts.dispose();
    });

    test('no captions: the spec lengths stand', () {
      final split = NnSplit([photo('a', '23:10'), photo('b', '23:20')]);
      expect(NnReadingTime.momentBeats(split, beat), 0);
    });

    test('a zoom holds on a captioned photo', () {
      final photos = [
        photo('a', '06:40', 'fast check-in at the airport, half asleep'),
      ];
      final chapter = NnChapter(
        title: 'Airport',
        from: '06:40',
        to: '07:00',
        photos: photos,
        moments: [
          NnTimeline([photos.first, photo('b', '06:50')]),
        ],
      );
      final holds = NnReadingTime.zoomHolds(chapter, 1, beat);
      expect(holds.single, greaterThan(0));
    });

    test('the film stays on the track: every scene whole bars, the Finale '
        'on a downbeat, deterministic', () {
      final photos = [
        photo('a', '23:10', 'боча пролил пиво'),
        photo('b', '23:20', 'our castle'),
        photo('c', '23:30', 'боча застрял в толчке'),
      ];
      final story = night([
        NnChapter(
          title: 'Club',
          from: '23:00',
          to: '00:00',
          photos: photos,
          moments: [NnBurst(photos), NnTimeline(photos)],
          note: 'Brussels never changes: great beer and good food.',
        ),
      ]);
      final a = NeonNightCanvas.timelineFor(story, beat: NeonTrack.beat);
      final b = NeonNightCanvas.timelineFor(story, beat: NeonTrack.beat);
      expect(a.startBeats, b.startBeats);
      for (final scene in a.scenes) {
        expect(scene.spec.beats % 4, 0, reason: '${scene.spec}');
      }
      expect(NeonTrack.partsForTimeline(a), isNotEmpty);
      final moments = [
        for (final s in a.scenes)
          if (s.spec case final NnMomentSpec m) m.beats,
      ];
      expect(moments.first, greaterThan(NnMomentType.burst.beats));
    });
  });

  group('the end card (T4)', () {
    test('zero counts are left out', () {
      final photos = [photo('a', '23:10'), photo('b', '23:20')];
      final story = night([
        NnChapter(
          title: 'Club',
          from: '23:00',
          to: '00:00',
          photos: photos,
          moments: [NnSplit(photos)],
        ),
      ], totals: const NnTotals(photos: 28, notes: 0, ticks: 0, moments: 28));
      expect(NnEndingTexts.totalsFor(story, en), '28 PHOTOS');
    });
  });
}
