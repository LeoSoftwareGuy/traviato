import 'dart:ui';

import 'neon_beat.dart';
import 'neon_eases.dart';
import 'neon_night_scene_spec.dart';
import 'neon_night_timeline.dart';
import 'neon_svg_path.dart';
import 'neon_tokens.dart';

/// The neon balloon sign (#363, NEON_NIGHT_SPEC.md §4.1): one persistent
/// element for the whole film. It lights up tube by tube in Ignition, moves
/// to the top-right corner, and comes back to the middle for the end card.
class NeonBalloon {
  NeonBalloon(this.timeline, {this.reducedFlashing = false});

  final NeonNightTimeline timeline;

  /// §6: tube flicker becomes a plain fade; the Finale glow-up is smaller.
  final bool reducedFlashing;

  NeonBeat get beat => timeline.beat;

  /// The sign's viewBox: 200 × 300.
  static const viewBox = Size(200, 300);

  static const ignition = NeonPose(240, 170, 600);
  static const corner = NeonPose(884, 64, 130);
  static const end = NeonPose(375, 330, 330);

  /// Where the chapter cards' pointer laser starts: the corner sign's
  /// basket.
  static const emitter = Offset(949, 252);

  /// Where the sign is at [t]: Ignition pose until its last beat, moving
  /// to the corner over that beat, there until Ending lb 1, then to the
  /// end pose by lb 2.5 (enter ease).
  NeonPose poseAt(double t) {
    final (fromCorner, toCorner) = timeline.ignitionToCorner;
    final (leaveCorner, atEnd) = timeline.cornerToEnd;
    if (t < leaveCorner) {
      final p = _progress(t, fromCorner, toCorner);
      return NeonPose.lerp(ignition, corner, NeonEases.enter(p));
    }
    final p = _progress(t, leaveCorner, atEnd);
    return NeonPose.lerp(corner, end, NeonEases.enter(p));
  }

  static double _progress(double t, double from, double to) =>
      ((t - from) / (to - from)).clamp(0.0, 1.0);

  /// How lit [tube] is at [t] (0 = glass only, 1 = fully on).
  double tubeLevel(NeonTube tube, double t) {
    final dt = t - beat.beatToSec(tube.lightBeat);
    return reducedFlashing ? fadeOn(dt) : flicker(dt);
  }

  /// The tube-on flicker (§3.5), [dt] s after the tube lights: one dip,
  /// then a ramp up.
  static double flicker(double dt) {
    if (dt < 0) return 0;
    if (dt < 0.07) return 0.75;
    if (dt < 0.17) return 0.12;
    if (dt < 0.32) return 0.12 + (1 - 0.12) * (dt - 0.17) / 0.15;
    return 1;
  }

  /// The reduced-flashing tube-on (§6): a 0.3 s linear fade.
  static double fadeOn(double dt) => (dt / 0.3).clamp(0.0, 1.0);

  /// The glow strength g at [t]: `0.9 + 0.4 × beatEnv`; in Finale plus the
  /// glow-up flare at lb 8 (0.9, or 0.3 reduced, τ 0.5 s); 1.2 in Ending.
  double glowAt(double t) {
    final scene = timeline.sceneAt(t).scene;
    if (scene.spec is NnEndingSpec) return 1.2;
    var g = 0.9 + 0.4 * beat.beatEnv(t);
    if (scene.spec is NnFinaleSpec) {
      final glowUp = scene.start + beat.beatToSec(8);
      g += (reducedFlashing ? 0.3 : 0.9) * NeonBeat.flare(t, glowUp, 0.5);
    }
    return g;
  }

  /// A tube's stroke on screen, px, for a sign [width] px wide: 4.5 in the
  /// corner, 11 at full size.
  static double tubeWidth(double width) =>
      4.5 + 6.5 * ((width - 130) / 470).clamp(0.0, 1.0);

  /// Unlit tubes show faintly, like glass.
  static const glassAlpha = 0.07;

  /// The white core over each tube: this share of its width, at α 0.8.
  static const coreWidth = 0.35;
  static const coreAlpha = 0.8;

  /// The glow's two blurs, as Gaussian σ on screen per unit of g.
  static const glowSigma = 7.0;
  static const glowWideSigma = 21.0;
}

/// Where the sign sits: its top-left corner and width (height = 1.5 ×
/// width).
class NeonPose {
  const NeonPose(this.x, this.y, this.width);

  final double x;
  final double y;
  final double width;

  double get scale => width / NeonBalloon.viewBox.width;

  static NeonPose lerp(NeonPose a, NeonPose b, double p) => NeonPose(
    a.x + (b.x - a.x) * p,
    a.y + (b.y - a.y) * p,
    a.width + (b.width - a.width) * p,
  );

  @override
  bool operator ==(Object other) =>
      other is NeonPose && other.x == x && other.y == y && other.width == width;

  @override
  int get hashCode => Object.hash(x, y, width);

  @override
  String toString() => 'NeonPose($x, $y, $width)';
}

/// The sign's tubes, in lighting order (§4.1, §5.1).
enum NeonTube {
  envelope(NeonColors.pink, 0, [
    'M100 12 C44 12 12 58 12 112 C12 160 46 192 74 226 L126 226 '
        'C154 192 188 160 188 112 C188 58 156 12 100 12 Z',
  ]),
  gores(NeonColors.pink, 1, [
    'M100 12 C72 40 66 160 88 226',
    'M100 12 C128 40 134 160 112 226',
    'M100 12 C52 30 38 150 78 224',
    'M100 12 C148 30 162 150 122 224',
  ]),
  bands(NeonColors.cyan, 2, [
    'M24 78 Q100 96 176 78',
    'M14 132 Q100 152 186 132',
    'M30 180 Q100 198 170 180',
  ]),
  neckAndRopes(NeonColors.pink, 2.5, [
    'M76 226 L124 226 L120 244 L80 244 Z',
    'M82 244 L88 262 M118 244 L112 262',
  ]),
  basket(NeonColors.green, 3, ['M84 262 L116 262 L113 292 L87 292 Z']),
  flame(NeonColors.green, 3.5, [
    'M100 260 C94 253 95 246 100 240 C105 246 106 253 100 260 Z',
  ]);

  const NeonTube(this.color, this.lightBeat, this.paths);

  final Color color;

  /// When it lights, in Ignition's local beats (Ignition starts at 0).
  final double lightBeat;

  /// Its shapes in the 200 × 300 viewBox, as SVG path data.
  final List<String> paths;

  /// All of its shapes as one path in viewBox units, parsed once.
  Path get path => _paths[index];

  static final List<Path> _paths = [
    for (final tube in NeonTube.values)
      () {
        final path = Path();
        for (final data in tube.paths) {
          path.addPath(parseNeonSvgPath(data), Offset.zero);
        }
        return path;
      }(),
  ];
}
