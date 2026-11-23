import 'dart:math' as math;

import '../../../domain/wrap_up_limits.dart';
import 'golden_vows_story.dart';
import 'golden_vows_timeline.dart';

/// Golden Vows held to the longest film on the player's own timeline
/// (#458; Neon Night's NnFit, #450) — and a small album to about
/// [secondsPerPhoto] a photo (#460), giving up only pages without the
/// user's words for that. The edge function already trims the
/// notes (a shorter clause, then none) and pages for its estimate; on the
/// phone the album gives way in the same order: chapters' second pages of
/// prints (#460, the latest first), the carousel, the packing
/// card, main pages down to 2 (those without a note first, the latest
/// first), then shorter chapter pages — never below their title's reading
/// time. Never a chapter, the title page, the heart or a caption.
abstract final class GvFit {
  /// The fewest main pages the album keeps.
  static const minHeroes = 2;

  /// How far chapter pages shrink, a step at a time.
  static const minChapterScale = 0.3;
  static const chapterScaleStep = 0.05;

  /// A small album's limit a film photo (#460).
  static const secondsPerPhoto = 4.0;

  /// The album's limit: 75 s, and [secondsPerPhoto] × its photos below.
  static double limitFor(GoldenVowsStory story) {
    const longest = WrapUpLimits.longestFilmSeconds * 1.0;
    // Every photo the film could show (the heart's, else the count).
    final photos = story.momentCount;
    return photos == 0 ? longest : math.min(longest, secondsPerPhoto * photos);
  }

  static double lengthOf(GoldenVowsStory story) =>
      GoldenVowsTimeline.forStory(story).total;

  /// [story] as long as [maxSeconds] at most, or as short as its rules
  /// let it be.
  static GoldenVowsStory toLongest(
    GoldenVowsStory story, {
    double? maxSeconds,
    double longest = WrapUpLimits.longestFilmSeconds * 1.0,
  }) {
    final limit = maxSeconds ?? limitFor(story);
    bool fits(GoldenVowsStory s) => lengthOf(s) <= limit;
    // Only past [longest]: the steps that take the user's words.
    bool pastLongest(GoldenVowsStory s) => lengthOf(s) > longest;
    if (fits(story)) return story;
    var s = story;
    // Second pages of prints, the latest first: those without the
    // user's line first, one with a line only past [longest] (#460).
    for (final withNote in [false, true]) {
      for (final page in s.chapters.reversed.where(
        (c) => c.isSecondPage && c.isLineANote == withNote,
      )) {
        if (withNote && !pastLongest(s)) break;
        s = s.fitted(chapters: [...s.chapters]..remove(page));
        if (fits(s)) return s;
      }
    }
    if (s.carousel != null) {
      s = s.fitted(dropCarousel: true);
      if (fits(s)) return s;
    }
    if (s.hasPackingCard) {
      s = s.fitted(dropPacking: true);
      if (fits(s)) return s;
    }
    // Main pages without a note first, then the rest; the latest first.
    final order = [
      ...s.heroes.reversed.where((h) => h.note == null),
      ...s.heroes.reversed.where((h) => h.note != null),
    ];
    for (final hero in order) {
      if (s.heroes.length <= minHeroes) break;
      if (hero.note != null && !pastLongest(s)) continue;
      s = s.fitted(heroes: [...s.heroes]..remove(hero));
      if (fits(s)) return s;
    }
    for (
      var scale = s.chapterDwellScale - chapterScaleStep;
      scale >= minChapterScale - 1e-9;
      scale -= chapterScaleStep
    ) {
      s = s.fitted(chapterDwellScale: scale);
      if (fits(s)) return s;
    }
    return s;
  }
}
