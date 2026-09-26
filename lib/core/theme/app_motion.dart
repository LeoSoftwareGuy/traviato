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

  // --- Notification display times (#153) -------------------------------
  // The one rule every snackbar follows (via `showAppSnackbar`); nothing
  // stays on screen until tapped. Calibrated against Android's built-in
  // lengths (1.5s / 2.75s), Material 3's 4–10s snackbar guidance, and how
  // long short confirmations stay up in apps like Instagram and Spotify.
  // The star toast above is its own celebratory 1.65s motion.

  /// Info / confirmation — a glance is enough.
  static const snackbarInfoDuration = Duration(seconds: 3);

  /// Errors — slightly longer, they need reading.
  static const snackbarErrorDuration = Duration(seconds: 4);

  /// Anything with an action button (Upgrade, Retry) — time to reach it.
  /// Still auto-dismisses, except under a screen reader (see
  /// `showAppSnackbar`).
  static const snackbarActionDuration = Duration(seconds: 5);

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

  /// Landing CTA; paywall's "Start 7-day free trial" (the only glowing
  /// element on that screen).
  static const pulseGlowDuration = Duration(milliseconds: 3600);
  static const pulseGlowCurve = Curves.easeInOut;
}
