import 'dart:math' as math;

/// The eases film specs are written with (#346), named as in GSAP so a
/// spec's timings port line for line: `power1` is quadratic, `power2`
/// cubic, `power3` quartic. Each maps progress `p` in 0–1 to 0–1 (`backOut`
/// overshoots on the way). Where a spec names no ease, GSAP's default is
/// `power1.out`.
abstract final class FilmEases {
  static double linear(double p) => p;

  static double power1In(double p) => _in(p, 2);
  static double power1Out(double p) => _out(p, 2);
  static double power1InOut(double p) => _inOut(p, 2);
  static double power2In(double p) => _in(p, 3);
  static double power2Out(double p) => _out(p, 3);
  static double power2InOut(double p) => _inOut(p, 3);
  static double power3In(double p) => _in(p, 4);
  static double power3Out(double p) => _out(p, 4);
  static double power3InOut(double p) => _inOut(p, 4);

  static double sineInOut(double p) => -(math.cos(math.pi * p) - 1) / 2;
  static double sineOut(double p) => math.sin(p * math.pi / 2);

  /// `back.out(overshoot)`; GSAP's default overshoot is 1.70158.
  static double backOut(double p, [double overshoot = 1.70158]) {
    final q = p - 1;
    return q * q * ((overshoot + 1) * q + overshoot) + 1;
  }

  static double _in(double p, int n) => math.pow(p, n).toDouble();
  static double _out(double p, int n) => 1 - math.pow(1 - p, n).toDouble();
  static double _inOut(double p, int n) =>
      p < 0.5 ? math.pow(2 * p, n) / 2 : 1 - math.pow(2 * (1 - p), n) / 2;

  /// Progress of a tween starting at [start] and lasting [dur] at film
  /// time [t], clamped to 0–1 and eased.
  static double at(
    double t,
    double start,
    double dur, [
    double Function(double) ease = power1Out,
  ]) => ease(((t - start) / dur).clamp(0.0, 1.0));
}
