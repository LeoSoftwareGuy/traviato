import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// The colours a balloon mark is drawn in: each film template has its own
/// (#346). The envelope is a horizontal gradient from left to right.
class BalloonMarkStyle {
  const BalloonMarkStyle({
    required this.envelope,
    required this.envelopeStops,
    required this.gores,
    required this.band,
    required this.ropes,
    required this.basket,
  });

  final List<Color> envelope;

  /// One per [envelope] colour, 0–1.
  final List<double> envelopeStops;

  /// The seams down the envelope.
  final Color gores;
  final Color band;
  final Color ropes;
  final Color basket;
}

/// The balloon's drawing, in its own coordinates ([size]). Swapping this
/// for an official vector logo later changes every film that draws a
/// [BalloonMark], without touching where or how they move it.
abstract interface class BalloonMarkShape {
  Size get size;

  /// Paints the balloon at the origin, in [style].
  void paint(Canvas canvas, BalloonMarkStyle style);
}

/// The flat balloon from the Golden Vows spec (golden-vows-spec.md §4,
/// #346): an envelope with two seams, a band, two ropes and a basket, on a
/// 200×292 drawing.
class SpecBalloonMarkShape implements BalloonMarkShape {
  const SpecBalloonMarkShape();

  @override
  Size get size => const Size(200, 292);

  static final Path _envelope = Path()
    ..moveTo(100, 4)
    ..cubicTo(158, 4, 196, 48, 196, 104)
    ..cubicTo(196, 156, 160, 190, 132, 222)
    ..lineTo(68, 222)
    ..cubicTo(40, 190, 4, 156, 4, 104)
    ..cubicTo(4, 48, 42, 4, 100, 4)
    ..close();

  static final Path _gores = Path()
    ..moveTo(100, 6)
    ..cubicTo(66, 42, 62, 160, 84, 222)
    ..moveTo(100, 6)
    ..cubicTo(134, 42, 138, 160, 116, 222);

  static final Path _ropes = Path()
    ..moveTo(70, 229)
    ..lineTo(85, 262)
    ..moveTo(130, 229)
    ..lineTo(115, 262);

  @override
  void paint(Canvas canvas, BalloonMarkStyle style) {
    canvas
      ..drawPath(
        _envelope,
        Paint()
          ..shader = ui.Gradient.linear(
            const Offset(4, 0),
            const Offset(196, 0),
            style.envelope,
            style.envelopeStops,
          ),
      )
      ..drawPath(
        _gores,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = style.gores,
      )
      ..drawRect(
        const Rect.fromLTWH(66, 220, 68, 9),
        Paint()..color = style.band,
      )
      ..drawPath(
        _ropes,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = style.ropes,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(82, 260, 36, 30),
          const Radius.circular(5),
        ),
        Paint()..color = style.basket,
      );
  }
}

/// The Storyni balloon as a mark, drawn on a film's canvas (#346). Films
/// place and move it; the [shape] and [style] say what it looks like.
class BalloonMark {
  const BalloonMark({
    required this.style,
    this.shape = const SpecBalloonMarkShape(),
  });

  final BalloonMarkStyle style;
  final BalloonMarkShape shape;

  Size get size => shape.size;

  /// Paints the mark with its drawing's top-left at [topLeft], scaled by
  /// [scale] and turned by [rotationDeg] around its centre (GSAP's default
  /// origin), at [opacity].
  void paint(
    Canvas canvas, {
    required Offset topLeft,
    double scale = 1,
    double rotationDeg = 0,
    double opacity = 1,
  }) {
    if (opacity <= 0) return;
    final size = shape.size;
    final centre = topLeft + Offset(size.width / 2, size.height / 2);
    canvas
      ..save()
      ..translate(centre.dx, centre.dy)
      ..rotate(rotationDeg * math.pi / 180)
      ..scale(scale)
      ..translate(-size.width / 2, -size.height / 2);
    if (opacity < 1) {
      canvas.saveLayer(
        Offset.zero & size,
        Paint()..color = Color.fromRGBO(0, 0, 0, opacity),
      );
    }
    shape.paint(canvas, style);
    if (opacity < 1) canvas.restore();
    canvas.restore();
  }
}

/// A [BalloonMark] as a widget, fitted into its box (for screens outside
/// the film canvas).
class BalloonMarkView extends StatelessWidget {
  const BalloonMarkView({required this.mark, super.key});

  final BalloonMark mark;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: mark.size.width / mark.size.height,
    child: CustomPaint(painter: _BalloonMarkPainter(mark)),
  );
}

class _BalloonMarkPainter extends CustomPainter {
  _BalloonMarkPainter(this.mark);

  final BalloonMark mark;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / mark.size.width;
    mark.paint(
      canvas,
      topLeft: Offset(
        (size.width - mark.size.width) / 2,
        (size.height - mark.size.height) / 2,
      ),
      scale: scale,
    );
  }

  @override
  bool shouldRepaint(_BalloonMarkPainter oldDelegate) =>
      oldDelegate.mark != mark;
}
