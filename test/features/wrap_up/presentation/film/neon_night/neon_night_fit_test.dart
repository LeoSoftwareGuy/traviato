import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_fit.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_story.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_texts.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_track.dart';

/// Neon Night held to the longest film on the player's own timeline
/// (#450): ADE played 85 s on the phone while the edge function estimated
/// under 75.
void main() {
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
}
