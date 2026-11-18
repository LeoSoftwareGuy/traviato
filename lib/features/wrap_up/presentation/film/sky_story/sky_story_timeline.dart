import 'dart:math' as math;

import '../../../domain/film_text_rules.dart';
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
/// A page whose words need longer to read plays longer (#399 T1).
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

  /// [story]'s film: its page count, each page's own layout, and time to
  /// read each page's words (#399 T1).
  static FilmTimeline<SkySceneSpec> forStory(SkyStory story) {
    final layouts = story.layouts;
    final count = story.pages.length;
    return forChapters(
      count,
      layouts: layouts,
      minChapterDurs: [
        for (final (i, page) in story.pages.indexed)
          readingDur(page, layouts[i], isLast: i == count - 1),
      ],
    );
  }

  /// How long page [page] must play for its words to be read: from when
  /// they appear until the page starts to fall (`SkyBalloonPath.exitStart`),
  /// at least [FilmTextRules.readingTime].
  static double readingDur(
    SkyPage page,
    SkyPageLayout layout, {
    required bool isLast,
  }) {
    final exitLead = isLast ? 1.75 : 0.25;
    final words = [
      page.note,
      page.skyLine,
    ].nonNulls.map((w) => w.trim()).where((w) => w.isNotEmpty).firstOrNull;
    final caption = page.hero.caption?.trim();
    return [
      if (words != null)
        wordsAt(layout) + FilmTextRules.readingTime(words) + exitLead,
      if (caption != null && caption.isNotEmpty)
        heroAt(layout) + FilmTextRules.readingTime(caption) + exitLead,
      0.0,
    ].reduce(math.max);
  }

  /// When a page's note (or sky line) appears, s after its start
  /// (`SkyPageBeats.cardAt` / `writeAt`).
  static double wordsAt(SkyPageLayout layout) => switch (layout) {
    SkyPageLayout.fan => 1.2,
    SkyPageLayout.taped => 1.95,
    SkyPageLayout.flyOut => 4.4,
  };

  /// When the hero (and its caption) lands, s after its start.
  static double heroAt(SkyPageLayout layout) => switch (layout) {
    SkyPageLayout.fan => 0.35,
    SkyPageLayout.taped => 0.75,
    SkyPageLayout.flyOut => 3.25,
  };

  static FilmTimeline<SkySceneSpec> forChapters(
    int count, {
    List<SkyPageLayout>? layouts,
    List<double>? minChapterDurs,
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
      final chapter = math.max(
        count == 1
            ? onlyChapterDur
            : isLast
            ? lastChapterDur
            : (long ? shortChapterDur : chapterDur),
        minChapterDurs?[i] ?? 0,
      );
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
