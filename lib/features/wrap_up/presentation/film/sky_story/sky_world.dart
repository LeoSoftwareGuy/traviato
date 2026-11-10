import 'dart:math' as math;

import 'package:flutter/animation.dart';

import '../timeline/film_timeline.dart';
import '../wrap_up_film_motion.dart';
import 'sky_balloon_path.dart';
import 'sky_scene_spec.dart';
import 'sky_story_tokens.dart';

/// Sky Story's world (#345, phase 1): one tall sky, sunset at the bottom
/// and night at the top, that a single camera climbs for the whole film.
/// There are no cuts, only a continuous rise.
///
/// Measured from the reference stills: the camera climbs about 65 px/s
/// after an easy start, and night is reached by the last chapter. Longer
/// or shorter films climb the same height at a different speed, so every
/// film goes dusk → night by its gather. Everything here is a pure
/// function of the film time; seeded layers never change between plays.
class SkyWorld {
  SkyWorld(this.timeline)
    : gatherStart = timeline.first<SkyGatherSpec>()!.start,
      balloon = SkyBalloonPath(timeline),
      _speed =
          climbToGather /
          _climbIntegral(timeline.first<SkyGatherSpec>()!.start);

  static const double width = 1080;
  static const double height = 1920;

  /// How high the camera has climbed when the gather starts.
  static const double climbToGather = 2700;

  /// The camera eases from still to full speed over this long.
  static const double rampDur = 4.0;

  /// The gather flattens the sky to the outro night over this long.
  static const double flattenDur = 3.0;

  final FilmTimeline<SkySceneSpec> timeline;
  final double gatherStart;

  /// The big balloon, which rides with the camera (painted over the pages).
  final SkyBalloonPath balloon;
  final double _speed;

  /// ∫ of the camera's speed profile (smoothstep ramp, then flat), in
  /// "full-speed seconds".
  static double _climbIntegral(double t) {
    if (t <= 0) return 0;
    if (t >= rampDur) return t - rampDur / 2;
    final x = t / rampDur;
    return rampDur * (x * x * x - x * x * x * x / 2);
  }

  /// The altitude of the bottom edge of the frame at [t]: 0 at the start,
  /// rising forever, never jumping.
  double camera(double t) => _speed * _climbIntegral(t);

  /// Camera speed at full climb, px/s.
  double get speed => _speed;

  /// The altitude shown at frame row [screenY] at [t].
  double altitudeAt(double screenY, double t) => camera(t) + (height - screenY);

  /// Where world [altitude] sits on the frame at [t].
  double screenYOf(double altitude, double t) =>
      height - (altitude - camera(t));

  /// The sky's colour at [altitude], before the outro flattens it.
  static Color skyAt(double altitude) {
    const stops = SkyStoryColors.skyStops;
    if (altitude <= stops.first.$1) return stops.first.$2;
    for (var i = 1; i < stops.length; i++) {
      final (a1, c1) = stops[i];
      if (altitude <= a1) {
        final (a0, c0) = stops[i - 1];
        return Color.lerp(c0, c1, (altitude - a0) / (a1 - a0))!;
      }
    }
    return stops.last.$2;
  }

  /// 0 before the gather, easing to 1 as the sky goes flat night.
  double outroBlend(double t) => Curves.easeInOut.transform(
    ((t - gatherStart) / flattenDur).clamp(0.0, 1.0),
  );

  /// The colour of frame row [screenY] at [t].
  Color skyColor(double screenY, double t) {
    final sky = skyAt(altitudeAt(screenY, t));
    final blend = outroBlend(t);
    if (blend == 0) return sky;
    final outro = Color.lerp(
      SkyStoryColors.outroTop,
      SkyStoryColors.outroBottom,
      screenY / height,
    )!;
    return Color.lerp(sky, outro, blend)!;
  }

  /// How much of the night's stars show at [altitude] (0 in the dusk).
  static double starVisibility(double altitude) =>
      ((altitude - 1700) / 1000).clamp(0.0, 1.0);

  /// How much the clouds show at [t]: gone early in the gather.
  double cloudVisibility(double t) => (1 - outroBlend(t) * 2).clamp(0.0, 1.0);

  // ---- Seeded world layers -------------------------------------------

  /// Clouds: low in the sky, alternating sides, drifting sideways.
  static final List<SkyCloud> clouds = [
    for (var i = 0; i < 7; i++)
      SkyCloud(
        altitude: 220 + i * 300 + rnd(i, 3) * 120,
        x: i.isEven ? -60 + rnd(i, 5) * 260 : 700 + rnd(i, 5) * 300,
        width: 400 + rnd(i, 7) * 300,
        variant: i % SkyCloud.variants,
        drift: (i.isEven ? 1 : -1) * (6 + rnd(i, 11) * 6),
      ),
  ];

  /// Floating lanterns/embers, about 20 in any frame, thinning at night.
  static final List<SkyEmber> embers = [
    for (var i = 0; i < 150; i++)
      if (rnd(i, 23) > _emberThinning(i * 70.0))
        SkyEmber(
          altitude: i * 70.0 + rnd(i, 29) * 70,
          x: 40 + rnd(i, 31) * 1000,
          radius: 3.5 + rnd(i, 37) * 3.5,
          phase: rnd(i, 41) * math.pi * 2,
        ),
  ];

  static double _emberThinning(double altitude) => altitude < 4200 ? 0.25 : 0.7;

  /// Stars: night only, so they start where the dusk ends.
  static final List<SkyStar> stars = [
    for (var i = 0; i < 360; i++)
      SkyStar(
        altitude: 1500 + i * 32.0 + rnd(i, 43) * 32,
        x: rnd(i, 47) * 1080,
        radius: 1.2 + rnd(i, 53) * 1.3,
        brightness: 0.5 + rnd(i, 59) * 0.4,
        phase: rnd(i, 61) * math.pi * 2,
      ),
  ];

  /// Small balloons far off, riding the world (not the camera).
  static final List<SkySmallBalloon> smallBalloons = [
    for (var i = 0; i < 14; i++)
      SkySmallBalloon(
        altitude: 400 + i * 680 + rnd(i, 67) * 200,
        x: i.isEven ? 120 + rnd(i, 71) * 140 : 760 + rnd(i, 71) * 160,
        width: 32 + rnd(i, 73) * 24,
        phase: rnd(i, 79) * math.pi * 2,
      ),
  ];

  /// The ±8 px, ~3 s bob every balloon floats on.
  static double bob(double t, double phase) =>
      math.sin(t * 2 * math.pi / 3.0 + phase) * 8;
}

class SkyCloud {
  const SkyCloud({
    required this.altitude,
    required this.x,
    required this.width,
    required this.variant,
    required this.drift,
  });

  static const variants = 3;

  /// Altitude of the cloud's centre, and its left edge on the frame.
  final double altitude;
  final double x;
  final double width;
  final int variant;

  /// Sideways drift, px/s.
  final double drift;
}

class SkyEmber {
  const SkyEmber({
    required this.altitude,
    required this.x,
    required this.radius,
    required this.phase,
  });

  final double altitude;
  final double x;
  final double radius;
  final double phase;

  /// Embers rise a little on their own, on top of the camera's climb.
  static const double rise = 8;
}

class SkyStar {
  const SkyStar({
    required this.altitude,
    required this.x,
    required this.radius,
    required this.brightness,
    required this.phase,
  });

  final double altitude;
  final double x;
  final double radius;
  final double brightness;
  final double phase;
}

class SkySmallBalloon {
  const SkySmallBalloon({
    required this.altitude,
    required this.x,
    required this.width,
    required this.phase,
  });

  final double altitude;
  final double x;
  final double width;
  final double phase;

  /// They drift up a touch faster than the world.
  static const double rise = 6;
}
