import 'dart:math' as math;

import '../../../domain/film_text_rules.dart';
import '../timeline/film_timeline.dart';
import 'sky_page_beats.dart';
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
    final mins = [
      for (final (i, page) in story.pages.indexed)
        readingDur(page, layouts[i], isLast: i == count - 1),
    ];
    final durs = fittedChapterDurs(count, mins, story.targetSeconds);
    final paces = [
      for (final (i, page) in story.pages.indexed)
        paceFor(page, layouts[i], durs[i], isLast: i == count - 1),
    ];
    return forChapters(
      count,
      layouts: layouts,
      minChapterDurs: durs,
      paces: paces,
    );
  }

  /// The most a page stretches or shrinks to fit the film's length (#434).
  static const minFit = 0.75;
  static const maxFit = 1.6;

  /// A page never plays shorter than this: the taped page's note and
  /// signature are written by ~5.7 s.
  static const minChapterDur = 7.0;

  /// The pages' lengths for a film of [count] pages: the reference's, or
  /// with [target] (`content.film_seconds`, #434) scaled together so the
  /// film lasts about [target] — within [minFit]–[maxFit] of the
  /// reference, never under a page's reading time ([mins]).
  static List<double> fittedChapterDurs(
    int count,
    List<double> mins,
    double? target,
  ) {
    List<double> scaled(double f) => [
      for (var i = 0; i < count; i++)
        f == 1
            ? chapterDurFor(i, count, mins[i])
            : math.max(
                math.max(chapterDurFor(i, count, 0) * f, minChapterDur),
                mins[i],
              ),
    ];
    if (target == null) return scaled(1);
    final fixed =
        forChapters(count).total -
        [
          for (var i = 0; i < count; i++) chapterDurFor(i, count, 0),
        ].fold(0.0, (a, b) => a + b);
    var lo = minFit;
    var hi = maxFit;
    for (var k = 0; k < 40; k++) {
      final mid = (lo + hi) / 2;
      final total = fixed + scaled(mid).fold(0.0, (a, b) => a + b);
      if (total < target) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return scaled((lo + hi) / 2);
  }

  /// The slowest a page deals its photos (#422), s between two.
  static const maxDealGap = 1.2;

  /// The share of a page by which its hero has landed when it deals slower:
  /// the rest is for seeing the whole page.
  static const dealShare = 0.5;

  /// How a page of [duration] s deals its photos (#422): one after another
  /// over about half the page instead of all within its first second, then
  /// the hero. The note's timing doesn't move, so its reading time holds;
  /// the hero still lands in time for its caption to be read. Null for the
  /// reference's pace: a fly-out page, or no time to spare.
  static ({double dealGap, double heroAt})? paceFor(
    SkyPage page,
    SkyPageLayout layout,
    double duration, {
    required bool isLast,
  }) {
    final (from, baseHero) = switch (layout) {
      SkyPageLayout.fan => (-0.9, 0.35),
      SkyPageLayout.taped => (-0.75, 0.75),
      SkyPageLayout.flyOut => (0.0, 0.0),
    };
    if (layout == SkyPageLayout.flyOut) return null;
    final deals = math.min(page.extras.length, SkyPage.maxExtras);
    final exitLead = isLast ? 1.75 : 0.25;
    final caption = page.hero.caption?.trim() ?? '';
    final latestHero =
        duration -
        exitLead -
        (caption.isEmpty ? 1.5 : FilmTextRules.readingTime(caption));
    final hero = math.min(duration * dealShare, latestHero);
    final gap = ((hero - from) / (deals + 1)).clamp(
      SkyPageBeats.fanDealGap,
      maxDealGap,
    );
    if (gap <= SkyPageBeats.fanDealGap + 1e-9) return null;
    return (
      dealGap: gap,
      heroAt: math.max(baseHero, from + gap * (deals + 1)),
    );
  }

  /// Chapter [i] of [count]'s length: the reference's, or longer for its
  /// words ([min]).
  static double chapterDurFor(int i, int count, double min) {
    final isLast = i == count - 1;
    return math.max(
      count == 1
          ? onlyChapterDur
          : isLast
          ? lastChapterDur
          : (count == maxChapters ? shortChapterDur : chapterDur),
      min,
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
    List<({double dealGap, double heroAt})?>? paces,
  }) {
    assert(count >= 1 && count <= maxChapters, 'chapters: $count');
    assert(layouts == null || layouts.length == count, 'layouts: $layouts');
    final scenes = <(double, SkySceneSpec)>[
      (openingDur, const SkyOpeningSpec()),
    ];
    for (var i = 0; i < count; i++) {
      final isLast = i == count - 1;
      final interlude = i == 0
          ? firstInterludeDur
          : (isLast ? lastInterludeDur : interludeDur);
      final chapter = chapterDurFor(i, count, minChapterDurs?[i] ?? 0);
      final pace = paces?[i];
      scenes
        ..add((interlude, SkyInterludeSpec(index: i)))
        ..add((
          chapter,
          SkyChapterSpec(
            index: i,
            count: count,
            layout: layouts?[i],
            dealGap: pace?.dealGap,
            heroAt: pace?.heroAt,
          ),
        ));
    }
    scenes
      ..add((gatherDur, const SkyGatherSpec()))
      ..add((outroDur, const SkyOutroSpec()));
    return FilmTimeline.sequence(scenes);
  }
}
