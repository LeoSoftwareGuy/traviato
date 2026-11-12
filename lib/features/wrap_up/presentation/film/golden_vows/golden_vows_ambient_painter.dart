import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'golden_vows_ambient.dart';
import 'golden_vows_tokens.dart';

/// Under everything (#346, spec §1 layer order): the ivory background and
/// the light leaks.
class GoldenVowsBackPainter extends CustomPainter {
  GoldenVowsBackPainter({required this.ambient, required this.time})
    : super(repaint: time);

  final GoldenVowsAmbient ambient;
  final ValueListenable<double> time;

  static final _background = Paint()
    ..shader = ui.Gradient.linear(
      Offset.zero,
      const Offset(0, GoldenVowsAmbient.height),
      const [GoldenVowsColors.ivory, GoldenVowsColors.ivoryDeep],
    );

  /// Gradient stops across a leak's reach, following its blurred falloff.
  static const _leakStops = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    canvas.drawRect(Offset.zero & size, _background);
    final opacity = GoldenVowsAmbient.leakOpacity(t);
    for (final leak in GoldenVowsAmbient.leaks) {
      final centre = leak.centreAt(t);
      final stops = [
        for (var i = 0; i < _leakStops; i++) i / (_leakStops - 1),
      ];
      canvas.drawCircle(
        centre,
        leak.reach,
        Paint()
          ..shader = ui.Gradient.radial(centre, leak.reach, [
            for (final s in stops)
              leak.color.withValues(
                alpha: opacity * leak.falloff(s * leak.reach),
              ),
          ], stops),
      );
    }
  }

  @override
  bool shouldRepaint(GoldenVowsBackPainter oldDelegate) =>
      oldDelegate.ambient != ambient || oldDelegate.time != time;
}

/// Over everything (#346, spec §1 layer order): the gold frame, the
/// page-turn flare and the falling petals.
class GoldenVowsFrontPainter extends CustomPainter {
  GoldenVowsFrontPainter({required this.ambient, required this.time})
    : super(repaint: time);

  final GoldenVowsAmbient ambient;
  final ValueListenable<double> time;

  static final _outer = GoldenVowsAmbient.framePath(
    GoldenVowsAmbient.outerInset,
  ).computeMetrics().first;
  static final _inner = GoldenVowsAmbient.framePath(
    GoldenVowsAmbient.innerInset,
  ).computeMetrics().first;

  /// The flare blurred by 90 px reaches this far either side of its strip.
  static const _flareBlur = 90.0;
  static const _flareHalf = GoldenVowsAmbient.flareWidth / 2 + 2 * _flareBlur;

  /// The flare's brightness across its width: a peak in the middle fading
  /// to nothing at both edges, blurred (computed once, never per frame).
  static final List<double> _flareStops = [
    for (var i = 0; i <= 12; i++) i / 12,
  ];
  static final List<double> _flareProfile = () {
    double triangle(double x) =>
        math.max(0, 1 - x.abs() / (GoldenVowsAmbient.flareWidth / 2));
    double blurred(double x) {
      var sum = 0.0;
      var weights = 0.0;
      for (var k = -30; k <= 30; k++) {
        final dx = k * _flareBlur / 10;
        final w = math.exp(-dx * dx / (2 * _flareBlur * _flareBlur));
        sum += triangle(x + dx) * w;
        weights += w;
      }
      return sum / weights;
    }

    final peak = blurred(0);
    return [
      for (final s in _flareStops) blurred((s * 2 - 1) * _flareHalf) / peak,
    ];
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    _paintFrame(canvas, t);
    _paintFlare(canvas, t);
    _paintPetals(canvas, t);
  }

  void _paintFrame(Canvas canvas, double t) {
    final opacity = ambient.frameOpacity(t);
    if (opacity <= 0) return;
    // Once hidden after the invitation, it comes back already drawn.
    final drawn = t < ambient.timeline.endingStart;
    void stroke(ui.PathMetric frame, double done, Color color, double width) {
      if (done <= 0) return;
      canvas.drawPath(
        frame.extractPath(0, frame.length * done),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..color = color.withValues(alpha: color.a * opacity),
      );
    }

    stroke(
      _outer,
      drawn ? GoldenVowsAmbient.outerDrawn(t) : 1,
      GoldenVowsColors.gold,
      GoldenVowsAmbient.outerStroke,
    );
    stroke(
      _inner,
      drawn ? GoldenVowsAmbient.innerDrawn(t) : 1,
      GoldenVowsColors.gold.withAlpha(140),
      GoldenVowsAmbient.innerStroke,
    );
  }

  void _paintFlare(Canvas canvas, double t) {
    final flare = ambient.flareAt(t);
    if (flare == null || flare.opacity <= 0) return;
    const peakAlpha = 200 / 255;
    canvas
      ..save()
      ..translate(
        flare.left + GoldenVowsAmbient.flareWidth / 2,
        GoldenVowsAmbient.flareTop + GoldenVowsAmbient.flareLength / 2,
      )
      ..rotate(GoldenVowsAmbient.flareAngleDeg * math.pi / 180)
      ..drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: _flareHalf * 2,
          height: GoldenVowsAmbient.flareLength,
        ),
        Paint()
          ..shader = ui.Gradient.linear(
            const Offset(-_flareHalf, 0),
            const Offset(_flareHalf, 0),
            [
              for (final v in _flareProfile)
                GoldenVowsColors.flare.withValues(
                  alpha: peakAlpha * flare.opacity * v,
                ),
            ],
            _flareStops,
          ),
      )
      ..restore();
  }

  /// A soft shadow under each petal: the same shape, a little lower, faint.
  static const _petalShadowOffset = Offset(0, 4);
  static const _petalShadow = Color(0x1A423222);

  void _paintPetals(Canvas canvas, double t) {
    for (final petal in GoldenVowsAmbient.petals) {
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: petal.width,
        height: petal.height,
      );
      final pill = RRect.fromRectAndRadius(
        rect,
        Radius.circular(petal.height / 2),
      );
      canvas
        ..save()
        ..translate(petal.positionAt(t).dx, petal.positionAt(t).dy)
        ..rotate(petal.angleAt(t) * math.pi / 180)
        ..drawRRect(
          pill.shift(_petalShadowOffset),
          Paint()..color = _petalShadow,
        )
        ..drawRRect(pill, Paint()..color = petal.color)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(GoldenVowsFrontPainter oldDelegate) =>
      oldDelegate.ambient != ambient || oldDelegate.time != time;
}
