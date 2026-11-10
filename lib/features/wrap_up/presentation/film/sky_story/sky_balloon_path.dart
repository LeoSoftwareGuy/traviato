import 'package:flutter/animation.dart';

import '../timeline/film_timeline.dart';
import '../wrap_up_film_motion.dart';
import 'sky_scene_spec.dart';
import 'sky_story.dart';
import 'sky_world.dart';

/// Where the big balloon is (#345), camera-relative. One balloon for the
/// whole film, as in the reference (0.25 s frames):
/// - it rises out of the sunset and holds over the title;
/// - as the title falls away it flies up and shrinks into the page's top
///   right corner, and rides there through the page;
/// - when a page falls away it swoops down into the middle, then climbs
///   back to the corner of the next one;
/// - before a fly-out page it waits in the middle while the photos circle
///   it, and only then goes to the corner.
///
/// Built once per timeline as keyed moves; between moves it holds.
class SkyBalloonPath {
  SkyBalloonPath(FilmTimeline<SkySceneSpec> timeline)
    : _moves = _build(timeline);

  /// Over the title (spec §5).
  static const title = SkyBalloonPose(Offset(540, 700), 360);

  /// A page's corner (spec §4).
  static const corner = SkyBalloonPose(Offset(930, 145), 110);

  /// Between pages, as the old page falls past.
  static const dip = SkyBalloonPose(Offset(540, 800), 240);

  /// Where a fly-out page's photos circle it.
  static const hub = SkyBalloonPose(Offset(540, 660), 260);

  static const _start = SkyBalloonPose(Offset(540, 2150), 360);
  static const _gone = SkyBalloonPose(Offset(540, -420), 240);

  final List<_Move> _moves;

  /// When a page falls away: just before its end, or for the last page
  /// 1.5 s before, so it has fallen before the gather.
  static double exitStart(TimedScene<SkySceneSpec> chapter) {
    final spec = chapter.spec as SkyChapterSpec;
    return spec.isLast ? chapter.end - 1.5 : chapter.end - 0.25;
  }

  /// When a fly-out page's hero arrives and the balloon leaves the hub.
  static double flyOutRelease(double chapterStart) => chapterStart + 3.25;

  static List<_Move> _build(FilmTimeline<SkySceneSpec> timeline) {
    final opening = timeline.first<SkyOpeningSpec>()!;
    final gather = timeline.first<SkyGatherSpec>()!;
    final chapters = [
      for (final scene in timeline.scenes)
        if (scene.spec is SkyChapterSpec) scene,
    ];
    final moves = <_Move>[
      const _Move(0, 3.0, _start, title, Curves.easeOutQuad),
      _Move(opening.end, opening.end + 0.9, title, corner, Curves.easeInOut),
    ];
    for (final (i, chapter) in chapters.indexed) {
      final spec = chapter.spec as SkyChapterSpec;
      if (spec.layout == SkyPageLayout.flyOut) {
        final release = flyOutRelease(chapter.start);
        moves.add(_Move(release, release + 0.7, hub, corner, Curves.easeInOut));
      }
      final out = exitStart(chapter);
      moves.add(_Move(out, out + 0.85, corner, dip, Curves.easeInOut));
      if (spec.isLast) {
        moves.add(
          _Move(gather.start, gather.start + 2.0, dip, _gone, Curves.easeIn),
        );
        continue;
      }
      final next = chapters[i + 1];
      if ((next.spec as SkyChapterSpec).layout == SkyPageLayout.flyOut) {
        moves.add(
          _Move(out + 1.35, next.start - 0.5, dip, hub, Curves.easeInOut),
        );
      } else {
        moves.add(_Move(out + 1.35, out + 2.25, dip, corner, Curves.easeInOut));
      }
    }
    return moves;
  }

  /// The balloon at [t] (with its bob), or null once it has flown off.
  ({Offset center, double width})? at(double t) {
    var pose = _moves.first.from;
    for (final move in _moves) {
      if (t < move.start) break;
      pose = move.poseAt(t);
    }
    if (identical(pose, _gone) || pose.center.dy < -300) return null;
    return (
      center: pose.center.translate(0, SkyWorld.bob(t, 0)),
      width: pose.width,
    );
  }
}

class SkyBalloonPose {
  const SkyBalloonPose(this.center, this.width);

  final Offset center;
  final double width;
}

class _Move {
  const _Move(this.start, this.end, this.from, this.to, this.curve);

  final double start;
  final double end;
  final SkyBalloonPose from;
  final SkyBalloonPose to;
  final Curve curve;

  SkyBalloonPose poseAt(double t) {
    if (t >= end) return to;
    final u = curve.transform(((t - start) / (end - start)).clamp(0.0, 1.0));
    return SkyBalloonPose(
      Offset.lerp(from.center, to.center, u)!,
      mix(from.width, to.width, u),
    );
  }
}
