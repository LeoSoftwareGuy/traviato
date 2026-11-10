import '../timeline/film_timeline.dart';
import 'sky_scene_spec.dart';

/// Sky Story's beats on the film clock (#345), with the reference film's
/// lengths (docs/design/sky-story/design-spec.md §5): three chapters give
/// its 54 s and its scene boundaries. How many chapters a memory gets, and
/// how long each runs, is decided with the director in a later phase.
abstract final class SkyStoryTimeline {
  static const openingDur = 5.0;

  /// Title → first chapter.
  static const firstInterludeDur = 2.0;
  static const interludeDur = 3.0;

  /// Into the last chapter: the page tilts out over full night.
  static const lastInterludeDur = 2.5;
  static const chapterDur = 9.5;

  /// The last chapter ends on the quote and the page drifting down.
  static const lastChapterDur = 11.5;
  static const gatherDur = 3.0;
  static const outroDur = 8.0;

  static const maxChapters = 5;

  static FilmTimeline<SkySceneSpec> forChapters(int count) {
    assert(count >= 1 && count <= maxChapters, 'chapters: $count');
    final scenes = <(double, SkySceneSpec)>[
      (openingDur, const SkyOpeningSpec()),
    ];
    for (var i = 0; i < count; i++) {
      final isLast = i == count - 1;
      scenes
        ..add((
          i == 0
              ? firstInterludeDur
              : (isLast ? lastInterludeDur : interludeDur),
          SkyInterludeSpec(index: i),
        ))
        ..add((
          isLast ? lastChapterDur : chapterDur,
          SkyChapterSpec(index: i, count: count),
        ));
    }
    scenes
      ..add((gatherDur, const SkyGatherSpec()))
      ..add((outroDur, const SkyOutroSpec()));
    return FilmTimeline.sequence(scenes);
  }
}
