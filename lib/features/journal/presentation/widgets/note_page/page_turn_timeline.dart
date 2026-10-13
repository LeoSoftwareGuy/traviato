import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter/animation.dart';

import '../../../../../core/theme/app_motion.dart';

/// One frame of the note page's book turn: everything the page-turn layers
/// need, derived from a single controller value so the rotation and both
/// shades can never drift apart (docs/design/JOURNAL_NOTE_PAGETURN_SPEC.md
/// §3, §6).
class PageTurnFrame extends Equatable {
  const PageTurnFrame({
    required this.angle,
    required this.writingShade,
    required this.frontShade,
    this.opacity = 1,
  });

  /// Rotation of the turning page about the spine, in radians: 0 lies flat
  /// over the writing page, −π has turned fully away to the left.
  final double angle;

  /// Opacity of the dark shade over the writing page.
  final double writingShade;

  /// Opacity of the shade over the turning page's front face.
  final double frontShade;

  /// Opacity of the whole note page — fades the book out in the last
  /// moments of the close, so the pop back to the Journal isn't a hard cut.
  final double opacity;

  /// Front face until the page passes 90°, the back face after.
  bool get showsFront => angle > -math.pi / 2;

  @override
  List<Object?> get props => [angle, writingShade, frontShade, opacity];
}

abstract class PageTurnTimeline {
  static double _ms(Duration d) => d.inMicroseconds / 1000;

  static double _progress(double ms, double start, double length) =>
      ((ms - start) / length).clamp(0.0, 1.0);

  /// [t] is the controller value over [AppMotion.pageTurnOpenDuration]:
  /// a 120ms hold, then the 1050ms sweep 0 → −π with both shades on their
  /// own intervals.
  static PageTurnFrame open(double t) {
    final ms = t * _ms(AppMotion.pageTurnOpenDuration);
    final hold = _ms(AppMotion.pageTurnOpenHold);
    final sweep = AppMotion.pageTurnCurve.transform(
      _progress(ms, hold, _ms(AppMotion.pageTurnOpenSweep)),
    );
    final writing = Curves.easeOut.transform(
      _progress(ms, hold, _ms(AppMotion.pageTurnWritingShadeFade)),
    );
    final front = Curves.easeIn.transform(
      _progress(ms, hold, _ms(AppMotion.pageTurnFrontShadeFade)),
    );
    return PageTurnFrame(
      angle: -math.pi * sweep,
      writingShade: 1 - writing,
      frontShade: front,
    );
  }

  /// [t] is the controller value over [AppMotion.pageTurnCloseDuration]:
  /// the 850ms sweep −π → 0 with no hold, shades reversed, then a short
  /// fade until the route pops.
  static PageTurnFrame close(double t) {
    final ms = t * _ms(AppMotion.pageTurnCloseDuration);
    final sweepLength = _ms(AppMotion.pageTurnCloseSweep);
    final linear = _progress(ms, 0, sweepLength);
    final sweep = AppMotion.pageTurnCurve.transform(linear);
    final fadeLength = _ms(AppMotion.pageTurnCloseDuration) - sweepLength;
    return PageTurnFrame(
      angle: -math.pi * (1 - sweep),
      writingShade: Curves.easeIn.transform(linear),
      frontShade: 1 - Curves.easeOut.transform(linear),
      opacity: 1 - _progress(ms, sweepLength, fadeLength),
    );
  }
}
