// The Wrap-Up Film's five motion primitives (docs/design/WRAP_UP_FILM_FLUTTER_SPEC.md
// §3), ported 1:1 from the reference prototype (`docs/design/wrap-film.jsx`)
// as pure functions of the film's single clock `T` (seconds). Every frame
// widget reads these instead of running its own `AnimationController` — the
// whole film is driven by one clock (#126 AC).

import 'dart:math' as math;

import 'package:flutter/animation.dart';

double _clamp01(double x) => x.clamp(0.0, 1.0);

double _progress(double t, double start, double dur) {
  if (dur <= 0) return t >= start ? 1.0 : 0.0;
  return _clamp01((t - start) / dur);
}

/// `mix(a, b, p)` — plain linear interpolation, matching the prototype's
/// helper of the same name.
double mix(double a, double b, double p) => a + (b - a) * p;

/// A `rise` result: [opacity] (0→1, easeOutCubic) and [translateY] (the
/// remaining upward travel in canvas px, `(1-opacity)*lift`).
class WrapUpFilmRise {
  const WrapUpFilmRise({required this.opacity, required this.translateY});

  final double opacity;
  final double translateY;
}

/// Fades an element in (opacity 0→1, easeOutCubic) while it rises by [lift]
/// canvas px. The default `lift` (38) matches the spec's default.
WrapUpFilmRise rise(double t, double start, double dur, {double lift = 38}) {
  final e = Curves.easeOutCubic.transform(_progress(t, start, dur));
  return WrapUpFilmRise(opacity: e, translateY: (1 - e) * lift);
}

/// Eases a value from [from] to [to] over `[start, start+dur]` with
/// easeInOutSine — used for both fades and text-style crossfades.
double fade(double t, double start, double dur, double from, double to) {
  final e = Curves.easeInOutSine.transform(_progress(t, start, dur));
  return from + (to - from) * e;
}

/// Linearly eases a value from [from] to [to] — deliberately NOT curved
/// (slow, steady pushes: cover-image zooms, growing hairlines/letterbox).
double swell(double t, double start, double dur, double from, double to) {
  return from + (to - from) * _progress(t, start, dur);
}

/// A 0→1 "thrown in" progress via easeOutBack — momentarily overshoots past
/// 1.0 before settling, by design. Callers feeding this into an `Opacity`
/// must clamp to `[0,1]` first.
double toss(double t, double start, double dur) {
  return Curves.easeOutBack.transform(_progress(t, start, dur));
}

/// A visible window with soft edges: fades in over `[inAt, inAt+inDur]`,
/// plateaus at 1, fades out over `[outAt, outAt+outDur]`. The workhorse that
/// lets one element span several scenes.
double band(
  double t,
  double inAt,
  double inDur,
  double outAt,
  double outDur,
) {
  return fade(t, inAt, inDur, 0, 1) * fade(t, outAt, outDur, 1, 0);
}

/// Deterministic per-(index, salt) jitter in `[0,1)` — same seed, same
/// playback every time.
double rnd(int i, int salt) {
  final x = math.sin(i * 12.9898 + salt * 78.233) * 43758.5453;
  return x - x.floorToDouble();
}
