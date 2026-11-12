import '../timeline/film_timeline.dart';
import 'sky_scene_spec.dart';
import 'sky_story.dart';

/// Sky Story's beats on the film clock (#345), with the reference film's
/// lengths (docs/design/sky-story/design-spec.md §5): three chapters give
/// its 54 s and its scene boundaries. Other page counts keep the film
/// within 40–75 s (phase 6):
/// - 1 page: the page holds longer (32.5 s; a single still page held
///   any longer drags);
/// - 2–4 pages: the reference's lengths (41.5 · 54 · 66.5 s);
/// - 5 pages: the pages before the last are a second shorter (75 s, down
///   from 79). Interludes stay, so each page has fallen away before the
///   next one's header fades in.
abstract final class SkyStoryTimeline {
  static const openingDur = 5.0;

  /// Title → first chapter.
  static const firstInterludeDur = 2.0;
  static const interludeDur = 3.0;

  /// Into the last chapter: the page tilts out over full night.
  static const lastInterludeDur = 2.5;
  static const chapterDur = 9.5;

  /// The pages before the last in a 5-page film: the taped page's note and
  /// signature are written by ~5.7 s, so it still holds a while.
  static const shortChapterDur = 8.5;

  /// The last chapter ends on the quote and the page drifting down.
  static const lastChapterDur = 11.5;

  /// A one-page film's only chapter.
  static const onlyChapterDur = 14.5;
  static const gatherDur = 3.0;
  static const outroDur = 8.0;

  static const maxChapters = 5;

  /// [story]'s film: its page count, and each page's own layout.
  static FilmTimeline<SkySceneSpec> forStory(SkyStory story) =>
      forChapters(story.pages.length, layouts: story.layouts);

  static FilmTimeline<SkySceneSpec> forChapters(
    int count, {
    List<SkyPageLayout>? layouts,
  }) {
    assert(count >= 1 && count <= maxChapters, 'chapters: $count');
    assert(layouts == null || layouts.length == count, 'layouts: $layouts');
    final long = count == maxChapters;
    final scenes = <(double, SkySceneSpec)>[
      (openingDur, const SkyOpeningSpec()),
    ];
    for (var i = 0; i < count; i++) {
      final isLast = i == count - 1;
      final interlude = i == 0
          ? firstInterludeDur
          : (isLast ? lastInterludeDur : interludeDur);
      final chapter = count == 1
          ? onlyChapterDur
          : isLast
          ? lastChapterDur
          : (long ? shortChapterDur : chapterDur);
      scenes
        ..add((interlude, SkyInterludeSpec(index: i)))
        ..add((
          chapter,
          SkyChapterSpec(index: i, count: count, layout: layouts?[i]),
        ));
    }
    scenes
      ..add((gatherDur, const SkyGatherSpec()))
      ..add((outroDur, const SkyOutroSpec()));
    return FilmTimeline.sequence(scenes);
  }
}
