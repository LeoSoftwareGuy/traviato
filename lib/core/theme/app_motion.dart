import 'package:flutter/animation.dart';

/// Named motion tokens from `docs/design/README.md` § Motion. `riseIn`,
/// `awardPop` and `progress` back widgets in this PR (bottom-sheet chrome,
/// star toast, progress/checklist bars); the rest are consts for the
/// screen-restyle issues that use them.
abstract class AppMotion {
  /// Bottom sheets, comparison table appearing, wrap-up hero text (staggered
  /// via [riseInStagger]).
  static const riseInDuration = Duration(milliseconds: 325);
  static const riseInCurve = Cubic(.2, .8, .2, 1);
  static const riseInOffset = 16.0;
  static const riseInStagger = Duration(milliseconds: 150);

  /// Star award toast.
  static const awardPopDuration = Duration(milliseconds: 1650);
  static const awardPopCurve = Curves.easeOut;

  /// Wrap-up stat bars.
  static const barFillDuration = Duration(milliseconds: 1600);
  static const barFillCurve = Curves.easeOut;

  /// Checklist / expense bars when values change.
  static const progressDuration = Duration(milliseconds: 425);
  static const progressCurve = Cubic(.2, .8, .2, 1);

  /// Wrap-up photo beats, hero.
  static const kenBurnsDuration = Duration(seconds: 17);
  static const kenBurnsCurve = Curves.easeOut;

  /// Wrap-up map route.
  static const drawRouteDuration = Duration(milliseconds: 4500);
  static const drawRouteCurve = Curves.easeOut;

  /// Star specks on Landing / wrap-up map.
  static const twinkleMinDuration = Duration(milliseconds: 2600);
  static const twinkleMaxDuration = Duration(milliseconds: 4200);
  static const twinkleCurve = Curves.easeInOut;

  /// Polaroids, empty-state ✦.
  static const floatYMinDuration = Duration(seconds: 5);
  static const floatYMaxDuration = Duration(seconds: 7);
  static const floatYCurve = Curves.easeInOut;

  /// Landing CTA only.
  static const pulseGlowDuration = Duration(milliseconds: 3600);
  static const pulseGlowCurve = Curves.easeInOut;
}
