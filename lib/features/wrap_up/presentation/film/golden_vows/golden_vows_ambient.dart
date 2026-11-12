import 'dart:math' as math;
import 'dart:ui';

import '../film_eases.dart';
import 'golden_vows_timeline.dart';
import 'golden_vows_tokens.dart';
import 'gv_random.dart';

/// Golden Vows' ambient layer (golden-vows-spec.md §3, #346): the ivory
/// background, three drifting light leaks, 16 falling petals, the double
/// gold frame and the page-turn flare. Everything is a pure function of
/// the film time, and the petals come from the spec's seed, so a frame at
/// a given time is the same on every play and every render.
class GoldenVowsAmbient {
  GoldenVowsAmbient(this.timeline);

  final GoldenVowsTimeline timeline;

  static const double width = 1080;
  static const double height = 1920;

  // ---- Light leaks ----------------------------------------------------

  static const leaks = [
    GvLightLeak(
      centre: Offset(120, 260),
      radius: 420,
      color: GoldenVowsColors.peach,
      drift: Offset(260, 180),
    ),
    GvLightLeak(
      centre: Offset(960, 980),
      radius: 480,
      color: GoldenVowsColors.goldLight,
      drift: Offset(-300, 220),
    ),
    GvLightLeak(
      centre: Offset(300, 1700),
      radius: 380,
      color: GoldenVowsColors.blush,
      drift: Offset(220, -260),
    ),
  ];

  /// One leg of the leaks' back-and-forth.
  static const leakLeg = 17.5;
  static const leakOpacityFrom = 0.32;
  static const leakOpacityTo = 0.45;

  /// How far the leaks are along their drift at [t] (0 = home, 1 = out):
  /// sine.inOut legs back and forth, on for as long as the film runs.
  static double leakDrift(double t) {
    final legs = math.max(t, 0) / leakLeg;
    final leg = legs.floor();
    final p = FilmEases.sineInOut(legs - leg);
    return leg.isEven ? p : 1 - p;
  }

  static double leakOpacity(double t) =>
      leakOpacityFrom + (leakOpacityTo - leakOpacityFrom) * leakDrift(t);

  // ---- Petals ---------------------------------------------------------

  static const petalSeed = 11;
  static const petalCount = 16;

  /// Falls from [petalTop] to [petalBottom], then starts again.
  static const petalTop = -60.0;
  static const petalBottom = 2000.0;
  static const petalSwayLeg = 2.8;

  static const _petalColors = [
    GoldenVowsColors.blush,
    GoldenVowsColors.paper,
    GoldenVowsColors.goldLight,
    GoldenVowsColors.blush,
    GoldenVowsColors.peach,
  ];

  /// The petals, drawn from the seed in the spec's order.
  static final List<GvPetal> petals = () {
    final r = GvRandom(petalSeed).next;
    return [
      for (var i = 0; i < petalCount; i++)
        () {
          final big = r();
          final x = r() * width;
          final w = 22 + big * 22;
          final h = 13 + big * 12;
          final dur = 10 + r() * 7;
          final phase = r();
          final rot = r() * 360;
          final spin = (r() > .5 ? 1 : -1) * (200 + r() * 400);
          final sway = 40 + r() * 70;
          final alpha = 170 + (r() * 70).round();
          return GvPetal(
            x: x,
            width: w,
            height: h,
            fallDur: dur,
            phase: phase,
            rotation: rot,
            spin: spin,
            sway: sway,
            color: _petalColors[i % _petalColors.length].withAlpha(alpha),
          );
        }(),
    ];
  }();

  // ---- Gold frame -----------------------------------------------------

  static const outerInset = 52.0;
  static const innerInset = 68.0;
  static const outerStroke = 2.5;
  static const innerStroke = 1.2;

  /// Outer and inner frames start drawing on, then take [frameDrawDur].
  static const outerDrawAt = 0.2;
  static const innerDrawAt = 0.45;
  static const frameDrawDur = 2.6;
  static const frameHideAt = 5.2;
  static const frameHideDur = 0.8;

  /// After the ending starts, the frame fades back in.
  static const frameReturnAfter = 1.2;
  static const frameReturnDur = 1.6;

  /// How much of the outer frame has been drawn at [t] (0–1).
  static double outerDrawn(double t) =>
      FilmEases.at(t, outerDrawAt, frameDrawDur, FilmEases.power2InOut);

  static double innerDrawn(double t) =>
      FilmEases.at(t, innerDrawAt, frameDrawDur, FilmEases.power2InOut);

  /// The frame's opacity at [t]: on through the invitation, gone through
  /// the album, back for the ending, gone with everything at the end.
  double frameOpacity(double t) {
    if (t < timeline.endingStart) {
      return 1 - FilmEases.at(t, frameHideAt, frameHideDur);
    }
    final back = FilmEases.at(
      t,
      timeline.endingStart + frameReturnAfter,
      frameReturnDur,
    );
    return back * endFade(t);
  }

  /// 1, then fading to 0 over the film's last [GoldenVowsTimeline.fadeOutDur]
  /// (68.6 → 70 in the reference). Only the background stays.
  double endFade(double t) =>
      1 -
      FilmEases.at(
        t,
        timeline.total - GoldenVowsTimeline.fadeOutDur,
        GoldenVowsTimeline.fadeOutDur,
      );

  /// The frame at [inset], as one path that starts at the top-centre and
  /// runs clockwise, so drawing a fraction of it draws the frame on.
  static Path framePath(double inset) => Path()
    ..moveTo(width / 2, inset)
    ..lineTo(width - inset, inset)
    ..lineTo(width - inset, height - inset)
    ..lineTo(inset, height - inset)
    ..lineTo(inset, inset)
    ..close();

  // ---- Flare ----------------------------------------------------------

  static const flareWidth = 520.0;
  static const flareLength = 2800.0;
  static const flareTop = -400.0;
  static const flareFromX = -900.0;
  static const flareToX = 1500.0;
  static const flareAngleDeg = 18.0;

  /// The flare starts this long into each page turn and sweeps for
  /// [flareDur].
  static const flareDelay = 0.3;
  static const flareDur = 1.6;
  static const flarePeakOpacity = 0.6;

  /// The flare at [t], or null when no page is turning.
  GvFlare? flareAt(double t) {
    for (final turn in timeline.turnStarts) {
      final start = turn + flareDelay;
      if (t < start || t > start + flareDur) continue;
      final p = FilmEases.at(t, start, flareDur, FilmEases.power1InOut);
      return GvFlare(
        left: flareFromX + (flareToX - flareFromX) * p,
        opacity: flarePeakOpacity * p,
      );
    }
    return null;
  }
}

/// A soft circle of coloured light (spec: blur 170).
class GvLightLeak {
  const GvLightLeak({
    required this.centre,
    required this.radius,
    required this.color,
    required this.drift,
  });

  final Offset centre;
  final double radius;
  final Color color;

  /// Where it drifts to, from [centre].
  final Offset drift;

  /// The spec's blur, as a Gaussian's standard deviation.
  static const blur = 170.0;

  /// The blurred disc's reach: past this it's invisible.
  double get reach => radius + 3 * blur;

  /// The blurred disc's brightness at [distance] from its centre (0–1).
  /// A disc blurred by a Gaussian falls off like the error function across
  /// its edge, so a radial gradient with these stops paints the blur
  /// without blurring anything at frame time.
  double falloff(double distance) =>
      0.5 * (1 - _erf((distance - radius) / (blur * math.sqrt2)));

  Offset centreAt(double t) => centre + drift * GoldenVowsAmbient.leakDrift(t);
}

/// Abramowitz–Stegun 7.1.26: |error| < 1.5e-7.
double _erf(double x) {
  final sign = x < 0 ? -1.0 : 1.0;
  final a = x.abs();
  final t = 1 / (1 + 0.3275911 * a);
  final y =
      1 -
      (((((1.061405429 * t - 1.453152027) * t) + 1.421413741) * t -
                      0.284496736) *
                  t +
              0.254829592) *
          t *
          math.exp(-a * a);
  return sign * y;
}

/// One falling petal (spec §3), as drawn from the seed.
class GvPetal {
  const GvPetal({
    required this.x,
    required this.width,
    required this.height,
    required this.fallDur,
    required this.phase,
    required this.rotation,
    required this.spin,
    required this.sway,
    required this.color,
  });

  final double x;
  final double width;
  final double height;

  /// One fall from top to bottom, s.
  final double fallDur;

  /// Where along its first fall it starts (0–1).
  final double phase;

  /// Its starting angle and how far it turns over 10 s, degrees.
  final double rotation;
  final double spin;
  final double sway;
  final Color color;

  static const _span =
      GoldenVowsAmbient.petalBottom - GoldenVowsAmbient.petalTop;

  /// Its centre at [t].
  Offset positionAt(double t) {
    final fallen = (phase * _span + t * _span / fallDur) % _span;
    final swayed =
        -sway * math.cos(math.pi * t / GoldenVowsAmbient.petalSwayLeg);
    return Offset(x + swayed, GoldenVowsAmbient.petalTop + fallen);
  }

  /// Its angle at [t], degrees: it turns by `spin × 7` over the
  /// reference's 70 s.
  double angleAt(double t) => rotation + spin * 7 * t / 70;
}

/// The flare's place and strength at one moment.
class GvFlare {
  const GvFlare({required this.left, required this.opacity});

  /// The strip's left edge, before its rotation.
  final double left;
  final double opacity;
}
