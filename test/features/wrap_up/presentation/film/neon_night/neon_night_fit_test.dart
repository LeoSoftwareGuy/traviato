import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_canvas.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_fit.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_scene_spec.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_story.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_texts.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_track.dart';

import 'neon_test_fonts.dart';

/// Neon Night held to the longest film on the player's own timeline
/// (#450): ADE played 85 s on the phone while the edge function estimated
/// under 75.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final story = NeonNightFixtures.reference;
  final length = NnFit.lengthOf(story, NeonTrack.beat);

  test('a film within the limit is left as it is', () {
    expect(NnFit.toLongest(story, maxSeconds: length + 1), same(story));
  });

  test('just over: the first steps only — words, then a merge, the Plan '
      'kept', () {
    final fitted = NnFit.toLongest(story, maxSeconds: length - 0.5);
    expect(NnFit.lengthOf(fitted, NeonTrack.beat), lessThan(length));
    expect(fitted.plan, story.plan, reason: 'the Plan goes only third');
    for (final c in fitted.chapters) {
      expect(NnChapterTexts.zoomTilesFor(c, 1), isNotEmpty);
    }
  });

  test('far over: every step, never below the floor', () {
    final fitted = NnFit.toLongest(story, maxSeconds: 10);
    expect(fitted.plan, isEmpty);
    for (final (i, c) in fitted.chapters.indexed) {
      expect(c.moments.length, lessThanOrEqualTo(1));
      // Never a chapter's line, never its last zoom.
      expect(c.note, story.chapters[i].note == null ? isNull : isNotNull);
      expect(NnChapterTexts.zoomTilesFor(c, i + 1), hasLength(1));
      for (final m in c.moments) {
        expect(
          m.photos.where((p) => p.line != null || p.caption != null).length,
          lessThanOrEqualTo(1),
        );
      }
    }
    expect(fitted.chapters, hasLength(story.chapters.length));
    expect(fitted.note, story.note, reason: 'the Note scene stays');
  });

  test('a long card line keeps its first whole clause', () {
    expect(
      NnFit.shortClause('Kuko Unreal всю ночь, домой пришли в 8 утра'),
      'Kuko Unreal всю ночь',
    );
    expect(
      NnFit.shortClause('Брюссель не меняется отличное пиво и еда'),
      isNull,
    );
  });

  group('a moment keeps its last caption (#456)', () {
    // Laid out as on the phone: the line fits, so it is read.
    setUpAll(loadNeonNightFonts);
    const line =
        'Приземлились в Амстердаме, сразу пошли завтракать и долго сидели';
    NeonNightStory night({String? split2Line = line}) {
      const card = [
        NnPhoto(id: 'a', takenAt: '09:40'),
        NnPhoto(id: 'b', takenAt: '09:42'),
        NnPhoto(id: 'c', takenAt: '09:50'),
      ];
      final split = NnSplit([
        const NnPhoto(id: 'd', takenAt: '13:19', caption: 'coffee shop'),
        const NnPhoto(
          id: 'e',
          takenAt: '14:25',
          caption: 'getting oatmeal',
        ).quiet.withLine(split2Line ?? ''),
      ]);
      return NeonNightStory(
        title: 'ADE',
        date: DateTime(2026, 10, 23),
        chapters: [
          NnChapter(
            title: 'Амстердам',
            from: '09:40',
            to: '14:25',
            photos: [...card, ...split.photos],
            cardPhotos: card,
            moments: [split],
            note: 'Прибыл в аэропорт за 10 минут до посадки',
          ),
        ],
      );
    }

    List<NnPhoto> splitOf(NeonNightStory s) =>
        s.chapters.single.moments.single.photos;

    test('far over: the line goes, the caption stays, no time shows', () {
      final fitted = NnFit.toLongest(night(), maxSeconds: 5);
      final photos = splitOf(fitted);
      expect(photos.first.caption, 'coffee shop');
      expect(photos.every((p) => p.line == null), isTrue);
      expect(fitted.chapters.single.note, isNotNull, reason: 'card line');
      for (final p in photos) {
        expect(p.timeLabel, isNull, reason: 'a captioned photo: ${p.id}');
      }
    });

    test('the line is shortened to a clause before it goes', () {
      final story = night();
      final length = NnFit.lengthOf(story, NeonTrack.beat);
      // Each limit walks the same steps from the start, a little further.
      final seen = <String?>[];
      late NeonNightStory s;
      for (var limit = length; limit > 5; limit -= 0.2) {
        s = NnFit.toLongest(story, maxSeconds: limit);
        final words = splitOf(s).last.line;
        if (seen.isEmpty || seen.last != words) seen.add(words);
      }
      expect(seen, [line, 'Приземлились в Амстердаме', null]);
      expect(splitOf(s).first.caption, 'coffee shop');
    });
  });

  test('a moment holds longer by at most a bar a photo (#456)', () {
    final reference = NeonNightFixtures.reference;
    final long = NeonNightStory(
      title: reference.title,
      date: reference.date,
      chapters: [
        for (final c in reference.chapters)
          NnChapter(
            title: c.title,
            from: c.from,
            to: c.to,
            photos: c.photos,
            cardPhotos: c.cardPhotos,
            moments: [
              for (final m in c.moments)
                switch (m) {
                  NnSplit() => NnSplit([
                    for (final p in m.photos.take(2)) p.quiet,
                  ], place: m.place),
                  _ => m,
                },
            ],
            note: c.note,
          ),
      ],
      targetSeconds: 75,
    );
    final timeline = NeonNightCanvas.timelineFor(long, beat: NeonTrack.beat);
    final splits = [
      for (final scene in timeline.scenes)
        if (scene.spec case NnMomentSpec(type: NnMomentType.split)) scene,
    ];
    expect(splits, isNotEmpty);
    for (final split in splits) {
      expect(split.spec.beats, NnMomentType.split.beats);
    }
  });
}
