import 'dart:math' as math;

import '../timeline/film_timeline.dart';
import 'sky_balloon_path.dart';
import 'sky_scene_spec.dart';
import 'sky_story.dart';

/// When each part of a page moves (#345), from the reference's 0.25 s
/// frames, relative to the chapter's start `c`:
/// - the eyebrow and headline fade up ~1.3 s before `c`;
/// - fan: four photos dealt 0.25 s apart from `c − 0.9`, the hero dropped
///   on top at `c + 0.35`, the note card (text and all) at `c + 1.2`, the
///   signature at `c + 2.8`;
/// - taped: four photos dealt into a grid from `c − 0.75`, the hero taped
///   over them at `c + 0.75`, an empty card at `c + 1.25`, the badge at
///   `c + 1.5`, the note written on from `c + 1.95`;
/// - fly-out: photos come out of the balloon from `c − 0.5` and circle it;
///   the hero spins in at `c + 3.25`; the quote's words settle from
///   `c + 4.4`.
/// Every page falls away under gravity at its exit (`SkyBalloonPath`).
class SkyPageBeats {
  SkyPageBeats(TimedScene<SkySceneSpec> chapter, {required this.previousEnd})
    : start = chapter.start,
      end = chapter.end,
      spec = chapter.spec as SkyChapterSpec,
      exitStart = SkyBalloonPath.exitStart(chapter);

  /// Every chapter page's beats, in order.
  static List<SkyPageBeats> all(FilmTimeline<SkySceneSpec> timeline) {
    final beats = <SkyPageBeats>[];
    var previousEnd = timeline.first<SkyOpeningSpec>()!.end;
    for (final scene in timeline.scenes) {
      if (scene.spec is! SkyChapterSpec) continue;
      final page = SkyPageBeats(scene, previousEnd: previousEnd);
      beats.add(page);
      previousEnd = scene.end;
    }
    return beats;
  }

  final double start;
  final double end;
  final SkyChapterSpec spec;

  /// When the page before this one (or the title) ended.
  final double previousEnd;

  /// When this page starts to fall away.
  final double exitStart;

  SkyPageLayout get layout => spec.layout;
  int get index => spec.index;

  /// Fall acceleration, px/s²: the reference's pages and title clear the
  /// frame in about a second.
  static const gravity = 1700.0;

  static const fanDealGap = 0.25;
  static const orbitStagger = 0.15;

  double get headerIn => layout == SkyPageLayout.flyOut
      ? start - 0.75
      : math.max(start - 1.3, previousEnd + 0.6);

  /// When dealt photo [i] arrives (or, fly-out, leaves the balloon).
  double dealAt(int i) => switch (layout) {
    SkyPageLayout.fan => start - 0.9 + fanDealGap * i,
    SkyPageLayout.taped => start - 0.75 + fanDealGap * i,
    SkyPageLayout.flyOut => start - 0.5 + orbitStagger * i,
  };

  double get heroAt => switch (layout) {
    SkyPageLayout.fan => start + 0.35,
    SkyPageLayout.taped => start + 0.75,
    SkyPageLayout.flyOut => SkyBalloonPath.flyOutRelease(start),
  };

  /// The note card rises (fan, taped); the fly-out writes on the sky.
  double get cardAt => switch (layout) {
    SkyPageLayout.fan => start + 1.2,
    SkyPageLayout.taped => start + 1.25,
    SkyPageLayout.flyOut => start + 4.4,
  };

  double get badgeAt => start + 1.5;

  /// The taped page's write-on starts here.
  double get writeAt => start + 1.95;

  /// The fan's signature; the others sign after their last line or word.
  double get fanSignatureAt => start + 2.8;

  /// How far the page has fallen at [t].
  double fallAt(double t) {
    if (t <= exitStart) return 0;
    final dt = t - exitStart;
    return gravity * dt * dt;
  }

  bool isVisibleAt(double t) => t >= headerIn && fallAt(t) < 2400;
}

/// The title page's beats: its three lines fade up one after another,
/// then it falls away as the balloon flies to the first page's corner.
abstract final class SkyTitleBeats {
  static const eyebrowAt = 1.5;
  static const titleAt = 1.75;
  static const subtitleAt = 2.25;

  static double fallAt(double t, double openingEnd) {
    if (t <= openingEnd) return 0;
    final dt = t - openingEnd;
    return SkyPageBeats.gravity * dt * dt;
  }
}
