import 'dart:math' as math;
import 'dart:ui';

import 'neon_beat.dart';
import 'neon_night_scene_spec.dart';
import 'neon_night_timeline.dart';
import 'neon_random.dart';
import 'neon_tokens.dart';

/// Neon Night's ambient layers (#363, NEON_NIGHT_SPEC.md §4): the haze,
/// the six lasers, the grain's drift and the fade to black. Everything is a
/// pure function of the film time T, so a frame renders the same on every
/// play and every export.
class NeonAmbient {
  NeonAmbient(this.timeline, {this.reducedFlashing = false});

  final NeonNightTimeline timeline;

  /// The §6 reduced-flashing version: the lasers' beat punch × 0.4.
  final bool reducedFlashing;

  static const double width = 1080;
  static const double height = 1920;

  NeonBeat get beat => timeline.beat;

  // ---- Haze -----------------------------------------------------------

  /// Each blob's alpha at its centre, before [hazeLevel].
  static const hazeAlpha = 0.55;

  /// Each blob is a 1440 × 1240 ellipse, fading out to its edge.
  static const hazeRadii = Size(720, 620);

  static const hazeOnCards = 1.1;
  static const hazeElsewhere = 0.8;

  /// Blob [i]'s centre (0–2) at [t]: slow circles at 0.21 / 0.17 rad/s.
  static Offset hazeCentre(int i, double t) {
    const homes = [Offset(300, 520), Offset(820, 1080), Offset(520, 1560)];
    return homes[i] +
        Offset(90 * math.sin(0.21 * t + 2 * i), 70 * math.cos(0.17 * t + i));
  }

  /// The haze's level at [t], multiplied into [hazeAlpha]: 1.1 during
  /// chapter cards, 0.8 elsewhere, fading out over the last 2 beats.
  double hazeLevel(double t) =>
      (timeline.isChapterCard(t) ? hazeOnCards : hazeElsewhere) * endFade(t);

  // ---- Lasers ---------------------------------------------------------

  static const lasers = [
    NeonLaser(Offset(-40, 300), -18, 10, 4, 0, NeonColors.green, 3),
    NeonLaser(Offset(1120, 520), 200, 8, 6, 1, NeonColors.cyan, 3),
    NeonLaser(Offset(-40, 1380), -24, 12, 5, 2, NeonColors.pink, 3),
    NeonLaser(Offset(1120, 1200), 192, 9, 3, 0.5, NeonColors.violet, 2),
    NeonLaser(Offset(300, -40), 62, 14, 7, 3, NeonColors.cyan, 2),
    NeonLaser(Offset(900, 1960), -115, 10, 5, 1.7, NeonColors.green, 2),
  ];

  static const laserLength = 2600.0;

  /// Beam [laser]'s angle at [t], in degrees (clockwise, y down).
  double laserAngle(NeonLaser laser, double t) =>
      laser.angle +
      laser.swing *
          math.sin(
            2 * math.pi * t / (laser.periodBars * beat.bar) + laser.phase,
          );

  /// Where beam [laser] ends at [t].
  Offset laserEnd(NeonLaser laser, double t) {
    final a = laserAngle(laser, t) * math.pi / 180;
    return laser.pivot + Offset(math.cos(a), math.sin(a)) * laserLength;
  }

  /// The beams' opacity at [t]: `amt × (0.45 + punch × 0.5 × beatEnv)`.
  /// amt is 0.6 in Note, falls to 0 over Ending's first 3 beats, else 1;
  /// punch is 1 in Finale, else 0.6, × 0.4 when reduced.
  double laserOpacity(double t) {
    final (:scene, :lb) = timeline.sceneAt(t);
    final amt = switch (scene.spec) {
      NnNoteSpec() => 0.6,
      NnEndingSpec() => 1 - (lb / 3).clamp(0.0, 1.0),
      _ => 1.0,
    };
    var punch = scene.spec is NnFinaleSpec ? 1.0 : 0.6;
    if (reducedFlashing) punch *= 0.4;
    return amt * (0.45 + punch * 0.5 * beat.beatEnv(t));
  }

  /// Beam [laser]'s colour at [t]: during a chapter card every beam takes
  /// the chapter's accent.
  Color laserColor(NeonLaser laser, double t) =>
      switch (timeline.sceneAt(t).scene.spec) {
        NnChapterCardSpec(:final chapter) => NeonColors.chapterAccent(chapter),
        _ => laser.color,
      };

  // ---- Grain ----------------------------------------------------------

  static const grainTile = 240;
  static const grainOpacity = 0.08;

  /// The grain tile's offset at [t]: re-rolled every frame from
  /// `rng(frame × 7 + 3)`.
  static Offset grainOffset(double t) {
    final r = NeonRandom(NeonSeeds.grain(NeonBeat.frameAt(t)));
    return Offset(r.next() * grainTile, r.next() * grainTile);
  }

  // ---- The end --------------------------------------------------------

  /// 1, falling linearly to 0 over the film's last 2 beats.
  double endFade(double t) {
    final fade = beat.beatToSec(2);
    return 1 - ((t - (timeline.total - fade)) / fade).clamp(0.0, 1.0);
  }

  /// The black over everything at the very end (0 → 1, last 2 beats).
  double outroBlack(double t) => 1 - endFade(t);
}

/// One laser beam (§4): it rotates about its [pivot], its left end.
class NeonLaser {
  const NeonLaser(
    this.pivot,
    this.angle,
    this.swing,
    this.periodBars,
    this.phase,
    this.color,
    this.width,
  );

  final Offset pivot;

  /// Rest angle and swing either side, degrees.
  final double angle;
  final double swing;

  /// One full swing, in bars.
  final double periodBars;

  /// Phase, radians.
  final double phase;
  final Color color;
  final double width;
}
