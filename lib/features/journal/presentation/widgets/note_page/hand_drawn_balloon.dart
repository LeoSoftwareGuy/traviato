import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Envelope + basket height for a balloon of width 1.
const _aspect = 1.4;

/// An ink-sketch hot-air balloon with an off-register colour wash — the
/// title page's doodles (docs/design/JOURNAL_NOTE_PAGETURN_SPEC.md §3).
/// Drawn in code rather than shipped as an SVG: the reference design's
/// source isn't in the repo, and a painter needs no new dependency.
class HandDrawnBalloon extends StatelessWidget {
  const HandDrawnBalloon({
    required this.width,
    required this.wash,
    required this.band,
    this.rotationDegrees = 0,
    super.key,
  });

  final double width;
  final Color wash;
  final Color band;
  final double rotationDegrees;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotationDegrees * math.pi / 180,
      child: CustomPaint(
        size: Size(width, width * _aspect),
        painter: _BalloonPainter(wash: wash, band: band),
      ),
    );
  }
}

class _BalloonPainter extends CustomPainter {
  const _BalloonPainter({required this.wash, required this.band});

  final Color wash;
  final Color band;

  /// Envelope outline in unit space (width 1, envelope height 1).
  static Path _envelope(double w, double h) => Path()
    ..moveTo(.5 * w, 0)
    ..cubicTo(.80 * w, 0, .98 * w, .22 * h, .98 * w, .46 * h)
    ..cubicTo(.98 * w, .72 * h, .70 * w, .86 * h, .62 * w, h)
    ..lineTo(.38 * w, h)
    ..cubicTo(.30 * w, .86 * h, .02 * w, .72 * h, .02 * w, .46 * h)
    ..cubicTo(.02 * w, .22 * h, .20 * w, 0, .5 * w, 0)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = w; // envelope is as tall as it is wide
    final envelope = _envelope(w, h);
    final basket = RRect.fromLTRBR(
      .40 * w,
      1.18 * h,
      .60 * w,
      1.32 * h,
      Radius.circular(.03 * w),
    );

    // Wash first, offset from the outline for the hand-painted look.
    canvas
      ..save()
      ..translate(2.5, 2)
      ..drawPath(envelope, Paint()..color = wash)
      ..drawRRect(basket, Paint()..color = wash)
      ..restore();

    // Coloured band across the envelope.
    canvas
      ..save()
      ..clipPath(envelope)
      ..drawRect(
        Rect.fromLTRB(0, .56 * h, w, .68 * h),
        Paint()..color = band.withValues(alpha: .8),
      )
      ..restore();

    final ink = Paint()
      ..color = AppColors.paperSketch
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final gores = Path()
      ..moveTo(.5 * w, 0)
      ..quadraticBezierTo(.16 * w, .5 * h, .42 * w, h)
      ..moveTo(.5 * w, 0)
      ..quadraticBezierTo(.84 * w, .5 * h, .58 * w, h)
      ..moveTo(.5 * w, 0)
      ..lineTo(.5 * w, h);
    final ropes = Path()
      ..moveTo(.39 * w, h)
      ..lineTo(.42 * w, 1.18 * h)
      ..moveTo(.61 * w, h)
      ..lineTo(.58 * w, 1.18 * h);

    canvas
      ..drawPath(envelope, ink)
      ..drawPath(gores, ink..strokeWidth = 1)
      ..drawPath(ropes, ink)
      ..drawRRect(basket, ink..strokeWidth = 1.4);
  }

  @override
  bool shouldRepaint(_BalloonPainter oldDelegate) =>
      oldDelegate.wash != wash || oldDelegate.band != band;
}

/// The dotted flight trail between the balloons and a small cloud, painted
/// over the whole title page. Points are fractions of the page size.
class TitlePageDoodlesPainter extends CustomPainter {
  const TitlePageDoodlesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final ink = Paint()
      ..color = AppColors.paperSketch.withValues(alpha: .45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final trail = Path()
      ..moveTo(.20 * w, .22 * h)
      ..cubicTo(.40 * w, .10 * h, .55 * w, .20 * h, .74 * w, .13 * h);
    for (final metric in trail.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 7) {
        canvas.drawPath(metric.extractPath(d, d + 2), ink);
      }
    }

    final cloudInk = Paint()
      ..color = AppColors.paperSketch.withValues(alpha: .55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final cx = .14 * w;
    final cy = .78 * h;
    final cloud = Path()
      ..moveTo(cx, cy)
      ..arcToPoint(Offset(cx + 14, cy - 6), radius: const Radius.circular(8))
      ..arcToPoint(Offset(cx + 32, cy - 4), radius: const Radius.circular(10))
      ..arcToPoint(Offset(cx + 40, cy + 4), radius: const Radius.circular(6))
      ..lineTo(cx, cy + 4)
      ..arcToPoint(Offset(cx, cy), radius: const Radius.circular(3));
    canvas.drawPath(cloud, cloudInk);
  }

  @override
  bool shouldRepaint(TitlePageDoodlesPainter oldDelegate) => false;
}
