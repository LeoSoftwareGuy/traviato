import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_neon_night.dart';
import 'package:traviato/features/wrap_up/domain/film_text_rules.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_beat.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_moments.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_canvas.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_from_wrap_up.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_scene_spec.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_story.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_texts.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_reading_time.dart';

import 'neon_test_fonts.dart';

/// Neon Night plays each chapter's note lines inside its moments (#426):
/// on their photos, zoomed in a timeline, under the photos in a split or
/// burst — no scene of their own.
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
    List<WrapUpNeonMoment> moments = const [
      WrapUpNeonMoment(
        type: 'timeline',
        photoIds: ['a0', 'a1', 'a2', 'a3', 'a4', 'a5'],
      ),
    ],
  }) => WrapUpNeonNight(
    title: 'Amsterdam',
    startDate: DateTime(2026, 9, 1),
    chapters: [
      WrapUpNeonChapter(
        title: 'Brussels',
        photos: photos,
        note: card,
        excerpts: excerpts,
        moments: moments,
      ),
    ],
    note: note,
  );

  NeonNightStory story(WrapUpNeonNight nn, {Set<String>? shown}) =>
      neonNightFromWrapUp(
        nn,
        photoIds: shown ?? {for (final photo in photos) photo.id},
      )!;

  Map<String, String> linesOf(NnChapter chapter) => {
    for (final moment in chapter.moments)
      for (final photo in moment.photos)
        if (photo.line != null) photo.id: photo.line!,
  };

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
    test('the card types its line; the others go on their photos', () {
      final chapter = story(
        nn(excerpts: const [ribs, rave, bikes], card: ribs.text),
      ).chapters.single;
      expect(chapter.note, ribs.text);
      final lines = linesOf(chapter);
      expect(lines['a4'], rave.text);
      // The card's line isn't repeated.
      expect(lines.values, isNot(contains(ribs.text)));
      // Without a photo of its own: one of the moment's, never none.
      expect(lines.values, contains(bikes.text));
      expect(lines, hasLength(2));
    });

    test("a line whose photo isn't in a moment goes on the nearest one", () {
      final chapter = story(
        nn(
          excerpts: const [rave],
          moments: const [
            WrapUpNeonMoment(type: 'split', photoIds: ['a1', 'a2', 'a5']),
          ],
        ),
      ).chapters.single;
      // a4 is nearest a5.
      expect(linesOf(chapter), {'a5': rave.text});
    });

    test('a photo the app cannot show falls back to a moment photo', () {
      final chapter = story(
        nn(excerpts: const [rave]),
        shown: {for (final photo in photos) photo.id}..remove('a4'),
      ).chapters.single;
      expect(linesOf(chapter).keys.single, isNot('a4'));
    });

    test('a line too long to show is left out; more lines than photos too', () {
      final huge = WrapUpNeonExcerpt(
        text: List.filled(20, 'unbelievably').join(' '),
        noteId: 'n9',
      );
      expect(
        linesOf(story(nn(excerpts: [huge, bikes])).chapters.single).values,
        [bikes.text],
      );
      final two = story(
        nn(
          excerpts: const [ribs, rave, bikes],
          moments: const [
            WrapUpNeonMoment(type: 'split', photoIds: ['a1', 'a4']),
          ],
        ),
      ).chapters.single;
      expect(linesOf(two), {'a1': ribs.text, 'a4': rave.text});
    });

    test('the Note scene drops a line a moment already plays', () {
      final played = WrapUpNeonNote(text: rave.text, number: 2);
      expect(story(nn(excerpts: const [rave], note: played)).note, isNull);
      const other = WrapUpNeonNote(text: 'Best night ever', number: 3);
      expect(story(nn(excerpts: const [rave], note: other)).note, isNotNull);
    });
  });

  group('the timeline', () {
    test('lines play in their moments: no scene of their own', () {
      final night = story(nn(excerpts: const [rave, bikes]));
      final timeline = NeonNightCanvas.timelineFor(night);
      final kinds = {for (final s in timeline.scenes) s.spec.runtimeType};
      expect(kinds, {
        NnIgnitionSpec,
        NnChapterCardSpec,
        NnMomentSpec,
        NnFinaleSpec,
        NnEndingSpec,
      });
      // The moment grows so each line can be read.
      final plain = NnReadingTime.momentBeats(
        story(nn()).chapters.single.moments.single,
        beat,
      );
      final lined = NnReadingTime.momentBeats(
        night.chapters.single.moments.single,
        beat,
      );
      expect(lined, greaterThan(plain));
      expect(lined % 4, 0);
    });

    test('a lit item with words zooms in for its reading time', () {
      final moment =
          story(nn(excerpts: const [rave])).chapters.single.moments.single
              as NnTimeline;
      final texts = NnTimelineTexts(moment, story(nn()).chapters.single);
      final k = moment.photos.indexWhere((p) => p.line != null);
      expect(k, 4);
      expect(texts.captions[k]!.text, rave.text);
      final holds = NnTimelineTexts.holdsFor(texts.captions, beat);
      expect(
        beat.beatToSec(holds[k]),
        greaterThanOrEqualTo(
          FilmTextRules.readingTime(rave.text) +
              NnTimelineLayout.zoomIn +
              NnTimelineLayout.zoomOut,
        ),
      );
      final layout = NnTimelineLayout(moment.photos.length, holds: holds);
      final from = layout.highlightStart(k);
      expect(layout.zoomAt(k, from - 0.1, beat), 0);
      expect(layout.zoomAt(k, from + holds[k] / 2, beat), 1);
      expect(layout.zoomAt(k, from + holds[k], beat), 0);
      // Big, centred, inside the frame with its words under it.
      final rect = layout.zoomRect(k, texts.captions[k]!.size.height);
      expect(rect.width, greaterThan(NnTimelineLayout.width * 1.5));
      expect(rect.center.dx, closeTo(540, 0.01));
      expect(
        rect.bottom + NnTimelineLayout.zoomGap + texts.captions[k]!.size.height,
        lessThan(1760),
      );
      texts.dispose();
    });
  });
}
