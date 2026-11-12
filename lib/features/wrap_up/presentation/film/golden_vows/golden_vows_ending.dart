import '../film_eases.dart';
import 'golden_vows_ambient.dart';

typedef _E = FilmEases;

/// The Storyni ending (#346, spec §5.6) as pure functions of film time:
/// the balloon comes down and bobs, "Storyni" settles in, a rule grows and
/// the names and date rise, then everything fades with the frame. It
/// starts at the timeline's e (60.95 s in the reference).
class GoldenVowsEnding {
  GoldenVowsEnding(this.ambient) : start = ambient.timeline.endingStart;

  /// For the shared final fade.
  final GoldenVowsAmbient ambient;

  /// The spec's e.
  final double start;

  static const balloonX = 440.0;
  static const balloonScale = 1.25;
  static const balloonFrom = -420.0;
  static const balloonTo = 560.0;
  static const descentDur = 2.6;

  /// The bob, measured on the reference (the spec gives no speed): up to
  /// 530 and back, 3.0 s sine.inOut per leg.
  static const bobTop = 530.0;
  static const bobLeg = 3.0;

  static const wordmarkStart = 1.4;
  static const wordmarkDur = 2.0;
  static const wordmarkTop = 1000.0;
  static const spacingFrom = 40.0;
  static const spacingTo = 8.0;
  static const blurFrom = 10.0;

  static const ruleStart = 2.4;
  static const ruleDur = 1.4;
  static const rule = (x: 440.0, y: 1205.0, width: 200.0, height: 2.0);

  static const lineStart = 2.7;
  static const lineDur = 1.2;

  bool visibleAt(double t) => t >= start && fade(t) > 0;

  /// The balloon's drawing top at [t]: down, then bobbing.
  double balloonY(double t) {
    final local = t - start;
    if (local < descentDur) {
      return balloonFrom +
          (balloonTo - balloonFrom) * _E.at(local, 0, descentDur, _E.power3Out);
    }
    final legs = (local - descentDur) / bobLeg;
    final leg = legs.floor();
    final p = _E.sineInOut(legs - leg);
    final up = leg.isEven ? p : 1 - p;
    return balloonTo + (bobTop - balloonTo) * up;
  }

  /// The wordmark settling in: 0 → 1 (power3.out, as the invitation's
  /// names), driving its spacing, blur and opacity.
  double wordmark(double t) =>
      _E.at(t - start, wordmarkStart, wordmarkDur, _E.power3Out);

  double wordmarkSpacing(double t) =>
      spacingFrom + (spacingTo - spacingFrom) * wordmark(t);

  double wordmarkBlur(double t) => blurFrom * (1 - wordmark(t));

  /// How much of the rule has grown, from its centre.
  double ruleGrown(double t) => _E.at(t - start, ruleStart, ruleDur);

  /// The names-and-date line: its top and opacity.
  ({double top, double opacity}) lineAt(double t) {
    final p = _E.at(t - start, lineStart, lineDur);
    return (top: 1265 - 20 * p, opacity: p);
  }

  /// Everything fades with the frame over the film's last 1.4 s.
  double fade(double t) => ambient.endFade(t);
}
