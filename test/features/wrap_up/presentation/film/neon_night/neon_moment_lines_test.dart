import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_neon_night.dart';
import 'package:traviato/features/wrap_up/domain/film_text_rules.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_beat.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_canvas.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_from_wrap_up.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_scene_spec.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_story.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_texts.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_photo_images.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_type.dart';

import 'neon_test_fonts.dart';

/// Neon Night plays each chapter's excerpts (#416).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadNeonNightFonts);
  const beat = NeonBeat();

  WrapUpNeonPhoto p(String id, int hour) =>
      WrapUpNeonPhoto(id: id, takenAt: DateTime(2026, 9, 1, hour));
  final photos = [for (var i = 0; i < 6; i++) p('a$i', 18 + i)];

  WrapUpNeonNight nn({
    List<WrapUpNeonExcerpt> excerpts = const [],
    String? card,
    WrapUpNeonNote? note,
  }) => WrapUpNeonNight(
    title: 'Amsterdam',
    startDate: DateTime(2026, 9, 1),
    chapters: [
      WrapUpNeonChapter(
        title: 'Brussels',
        photos: photos,
        note: card,
        excerpts: excerpts,
        moments: const [
          WrapUpNeonMoment(type: 'split', photoIds: ['a1', 'a2']),
        ],
      ),
    ],
    note: note,
  );

  NeonNightStory story(WrapUpNeonNight nn) => neonNightFromWrapUp(
    nn,
    photoIds: {for (final photo in photos) photo.id},
  )!;

  const ribs = WrapUpNeonExcerpt(
    text: 'Заказали 4,5 кг рёбер на троих!',
    noteId: 'n1',
    photoId: 'a1',
  );
  const rave = WrapUpNeonExcerpt(
    text: 'Danced at Shelter until 3, first time in a club since 2019!',
    noteId: 'n2',
    photoId: 'a4',
  );
  const bikes = WrapUpNeonExcerpt(
    text: 'Rented 3 bikes and rode 12 km to Zaandam.',
    noteId: 'n3',
  );

  group('the story', () {
    test("the card types its line; the others play over their photos", () {
      final chapter = story(
        nn(excerpts: const [ribs, rave, bikes], card: ribs.text),
      ).chapters.single;
      expect(chapter.note, ribs.text);
      expect([for (final l in chapter.lines) l.text], [rave.text, bikes.text]);
      expect(chapter.lines.first.photo.id, 'a4');
      // No photo of its own: one of the chapter's, never none.
      expect(chapter.lines.last.photo.id, isIn([for (final x in photos) x.id]));
    });

    test('a photo the app cannot show falls back to the chapter', () {
      final chapter = neonNightFromWrapUp(
        nn(excerpts: const [rave]),
        photoIds: {for (final photo in photos) photo.id}..remove('a4'),
      )!.chapters.single;
      expect(chapter.lines.single.photo.id, isNot('a4'));
    });

    test('a line too long to show whole is left out', () {
      final huge = WrapUpNeonExcerpt(
        text: List.filled(60, 'unbelievably').join(' '),
        noteId: 'n9',
      );
      expect(neonNoteLines(huge.text), isNull);
      expect(story(nn(excerpts: [huge, bikes])).chapters.single.lines, [
        isA<NnLine>().having((l) => l.text, 'text', bikes.text),
      ]);
    });

    test('the Note scene drops a line a chapter already plays', () {
      final played = WrapUpNeonNote(text: rave.text, number: 2);
      expect(story(nn(excerpts: const [rave], note: played)).note, isNull);
      const other = WrapUpNeonNote(text: 'Best night ever', number: 3);
      expect(story(nn(excerpts: const [rave], note: other)).note, isNotNull);
    });
  });

  group('the timeline', () {
    test('a chapter with lines gets a Lines scene after its moments', () {
      final night = story(nn(excerpts: const [ribs, rave, bikes]));
      final timeline = NeonNightCanvas.timelineFor(night);
      final specs = [for (final s in timeline.scenes) s.spec];
      final at = specs.indexWhere((s) => s is NnLinesSpec);
      expect(specs[at - 1], isA<NnMomentSpec>());
      final lines = specs[at] as NnLinesSpec;
      expect(lines.lineBeats, hasLength(3));
      for (final (k, b) in lines.lineBeats.indexed) {
        expect(b % 4, 0);
        // Each line is on screen for its reading time.
        final read = FilmTextRules.readingTime(night.chapters[0].lines[k].text);
        expect(beat.beatToSec(b), greaterThan(read));
      }
      // Its photos are decoded large.
      final (:thumbs, :large, :tiles) = NeonPhotoImages.idsFor(
        night,
        timeline,
      );
      expect(large, contains('a4'));
    });

    test('a chapter without excerpts has no Lines scene', () {
      final timeline = NeonNightCanvas.timelineFor(story(nn()));
      expect(timeline.scenes.where((s) => s.spec is NnLinesSpec), isEmpty);
      // Only the card's line: nothing left to play either.
      final card = NeonNightCanvas.timelineFor(
        story(nn(excerpts: const [ribs], card: ribs.text)),
      );
      expect(card.scenes.where((s) => s.spec is NnLinesSpec), isEmpty);
    });

    test('a short line holds 2 bars, a long one more', () {
      expect(NnLinesTexts.beatsFor(neonNoteLines('Ribs!')!, beat), 8);
      final long = neonNoteLines(rave.text)!;
      expect(NnLinesTexts.beatsFor(long, beat), greaterThan(8));
    });

    test('lineAt walks the lines in order', () {
      final spec = NnLinesSpec(chapter: 0, lineBeats: const [8, 12, 8]);
      expect(spec.beats, 28);
      expect(spec.lineAt(0), (line: 0, from: 0));
      expect(spec.lineAt(8), (line: 1, from: 8));
      expect(spec.lineAt(19.9), (line: 1, from: 8));
      expect(spec.lineAt(20), (line: 2, from: 20));
      expect(spec.startOf(2), 20);
    });
  });
}
