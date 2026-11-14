import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'neon_ambient.dart';
import 'neon_balloon.dart';
import 'neon_tokens.dart';

/// Layers 1–2 (#363, NEON_NIGHT_SPEC.md §4): the black fill and the three
/// drifting haze blobs.
class NeonBackPainter extends CustomPainter {
  NeonBackPainter({required this.ambient, required this.time})
    : super(repaint: time);

  final NeonAmbient ambient;
  final ValueListenable<double> time;

  static final _black = Paint()..color = NeonColors.black;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    canvas.drawRect(Offset.zero & size, _black);
    final alpha = (NeonAmbient.hazeAlpha * ambient.hazeLevel(t)).clamp(
      0.0,
      1.0,
    );
    if (alpha <= 0) return;
    const radii = NeonAmbient.hazeRadii;
    final paint = Paint()
      ..shader = ui.Gradient.radial(Offset.zero, radii.width, [
        NeonColors.haze.withValues(alpha: alpha),
        NeonColors.haze.withValues(alpha: 0),
      ]);
    for (var i = 0; i < 3; i++) {
      final centre = NeonAmbient.hazeCentre(i, t);
      canvas
        ..save()
        ..translate(centre.dx, centre.dy)
        ..scale(1, radii.height / radii.width)
        ..drawCircle(Offset.zero, radii.width, paint)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(NeonBackPainter oldDelegate) =>
      oldDelegate.ambient != ambient || oldDelegate.time != time;
}

/// Layer 4 (§4): the six laser beams, screen-blended, with a two-step
/// glow (CSS `0 0 8px c, 0 0 22px c`: Gaussian σ 4 and 11).
class NeonLaserPainter extends CustomPainter {
  NeonLaserPainter({required this.ambient, required this.time})
    : super(repaint: time);

  final NeonAmbient ambient;
  final ValueListenable<double> time;

  static const _glows = [11.0, 4.0];

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final opacity = ambient.laserOpacity(t).clamp(0.0, 1.0);
    if (opacity <= 0) return;
    for (final laser in NeonAmbient.lasers) {
      final color = ambient.laserColor(laser, t).withValues(alpha: opacity);
      final end = ambient.laserEnd(laser, t);
      for (final sigma in _glows) {
        canvas.drawLine(
          laser.pivot,
          end,
          Paint()
            ..blendMode = BlendMode.screen
            ..color = color
            ..strokeWidth = laser.width
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma),
        );
      }
      canvas.drawLine(
        laser.pivot,
        end,
        Paint()
          ..blendMode = BlendMode.screen
          ..color = color
          ..strokeWidth = laser.width,
      );
    }
  }

  @override
  bool shouldRepaint(NeonLaserPainter oldDelegate) =>
      oldDelegate.ambient != ambient || oldDelegate.time != time;
}

/// Layer 5 (§4.1): the neon balloon sign. Each tube is glass when unlit;
/// lit, it is two blurred copies of its stroke (σ 7g and 21g on screen)
/// under the colour stroke, with a white core on top.
class NeonBalloonPainter extends CustomPainter {
  NeonBalloonPainter({required this.balloon, required this.time})
    : super(repaint: time);

  final NeonBalloon balloon;
  final ValueListenable<double> time;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final pose = balloon.poseAt(t);
    final g = balloon.glowAt(t);
    final width = NeonBalloon.tubeWidth(pose.width);
    // Tubes are stroked in screen pixels, so the blur and the stroke
    // width don't scale with the sign.
    final toScreen = Float64List(16)
      ..[0] = pose.scale
      ..[5] = pose.scale
      ..[10] = 1
      ..[12] = pose.x
      ..[13] = pose.y
      ..[15] = 1;
    for (final tube in NeonTube.values) {
      final path = tube.path.transform(toScreen);
      Paint stroke(Color color, double strokeWidth) => Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = strokeWidth
        ..color = color;

      canvas.drawPath(
        path,
        stroke(
          tube.color.withValues(alpha: NeonBalloon.glassAlpha),
          width,
        ),
      );
      final level = balloon.tubeLevel(tube, t);
      if (level <= 0) continue;
      final lit = tube.color.withValues(alpha: level);
      for (final sigma in [NeonBalloon.glowWideSigma, NeonBalloon.glowSigma]) {
        canvas.drawPath(
          path,
          stroke(lit, width)
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              math.max(sigma * g, 0.1),
            ),
        );
      }
      canvas
        ..drawPath(path, stroke(lit, width))
        ..drawPath(
          path,
          stroke(
            NeonColors.white.withValues(
              alpha: NeonBalloon.coreAlpha * level,
            ),
            width * NeonBalloon.coreWidth,
          ),
        );
    }
  }

  @override
  bool shouldRepaint(NeonBalloonPainter oldDelegate) =>
      oldDelegate.balloon != balloon || oldDelegate.time != time;
}

/// Layers 8–10 (§4): the grain (overlay 0.08, re-placed every frame), the
/// vignette, and the black the film ends on.
class NeonFrontPainter extends CustomPainter {
  NeonFrontPainter({
    required this.ambient,
    required this.grain,
    required this.time,
  }) : super(repaint: time);

  final NeonAmbient ambient;
  final ui.Image grain;
  final ValueListenable<double> time;

  /// The vignette: an ellipse centred at (50 %, 45 %) reaching the
  /// farthest corner (CSS `farthest-corner`), clear to 55 %, black at
  /// α 0.55 at its edge.
  static const _vignetteCentre = Offset(
    NeonAmbient.width / 2,
    NeonAmbient.height * 0.45,
  );
  static final double _vignetteRx = NeonAmbient.width / 2 * math.sqrt2;
  static final double _vignetteRy =
      (NeonAmbient.height - _vignetteCentre.dy) * math.sqrt2;
  static final _vignette = Paint()
    ..shader = ui.Gradient.radial(
      Offset.zero,
      _vignetteRx,
      const [Color(0x00000000), Color(0x00000000), Color(0x8C000000)],
      const [0, 0.55, 1],
    );

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final offset = NeonAmbient.grainOffset(t);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..blendMode = BlendMode.overlay
        ..color = const Color.fromRGBO(0, 0, 0, NeonAmbient.grainOpacity)
        ..shader = ImageShader(
          grain,
          TileMode.repeated,
          TileMode.repeated,
          Matrix4.translationValues(-offset.dx, -offset.dy, 0).storage,
        ),
    );
    canvas
      ..save()
      ..translate(_vignetteCentre.dx, _vignetteCentre.dy)
      ..scale(1, _vignetteRy / _vignetteRx)
      ..drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: size.width * 2,
          height: size.height * 2 * _vignetteRx / _vignetteRy,
        ),
        _vignette,
      )
      ..restore();
    final black = ambient.outroBlack(t);
    if (black > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = NeonColors.black.withValues(alpha: black),
      );
    }
  }

  @override
  bool shouldRepaint(NeonFrontPainter oldDelegate) =>
      oldDelegate.ambient != ambient ||
      oldDelegate.grain != grain ||
      oldDelegate.time != time;
}
