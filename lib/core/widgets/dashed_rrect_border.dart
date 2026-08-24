import 'package:flutter/material.dart';

/// Dashed rounded-rect border used for "not filled in yet" affordances —
/// the auth reward-tease card, and later the New memory cover slot, the
/// Plan add-quest row, and Checklist's add row.
class DashedRRectBorder extends StatelessWidget {
  const DashedRRectBorder({
    required this.child,
    required this.color,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.strokeWidth = 1,
    this.dashWidth = 5,
    this.gapWidth = 4,
    super.key,
  });

  final Widget child;
  final Color color;
  final BorderRadius borderRadius;
  final double strokeWidth;
  final double dashWidth;
  final double gapWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRRectPainter(
        color: color,
        borderRadius: borderRadius,
        strokeWidth: strokeWidth,
        dashWidth: dashWidth,
        gapWidth: gapWidth,
      ),
      child: child,
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({
    required this.color,
    required this.borderRadius,
    required this.strokeWidth,
    required this.dashWidth,
    required this.gapWidth,
  });

  final Color color;
  final BorderRadius borderRadius;
  final double strokeWidth;
  final double dashWidth;
  final double gapWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = borderRadius.toRRect(Offset.zero & size);
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gapWidth;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) {
    return color != oldDelegate.color ||
        borderRadius != oldDelegate.borderRadius ||
        strokeWidth != oldDelegate.strokeWidth ||
        dashWidth != oldDelegate.dashWidth ||
        gapWidth != oldDelegate.gapWidth;
  }
}
