import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The title page's ink-sketch doodles, exported from the reference design
/// (docs/design/JOURNAL_NOTE_PAGETURN_SPEC.md §3). Each balloon SVG carries
/// its own off-register colour wash and band colour.
abstract class JournalDoodleAssets {
  static const _dir = 'assets/images/journal/balloons';
  static const balloonLarge = '$_dir/balloon_large_orange.svg';
  static const balloonSmall = '$_dir/balloon_small_pink.svg';
  static const balloonTiny = '$_dir/balloon_tiny_purple.svg';
  static const cloud = '$_dir/cloud.svg';
  static const flightTrail = '$_dir/flight_trail.svg';
}

/// Balloon SVG viewBox is 60 × 84.
const _balloonAspect = 84 / 60;

/// One hand-drawn hot-air balloon, [width] wide, tilted by
/// [rotationDegrees].
class HandDrawnBalloon extends StatelessWidget {
  const HandDrawnBalloon({
    required this.asset,
    required this.width,
    this.rotationDegrees = 0,
    super.key,
  });

  final String asset;
  final double width;
  final double rotationDegrees;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotationDegrees * math.pi / 180,
      child: SvgPicture.asset(
        asset,
        width: width,
        height: width * _balloonAspect,
        excludeFromSemantics: true,
      ),
    );
  }
}

/// A non-balloon doodle (cloud, flight trail) at [width], keeping its own
/// aspect ratio.
class JournalDoodle extends StatelessWidget {
  const JournalDoodle({required this.asset, required this.width, super.key});

  final String asset;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(asset, width: width, excludeFromSemantics: true);
  }
}
