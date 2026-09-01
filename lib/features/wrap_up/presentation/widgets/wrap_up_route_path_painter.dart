import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Deterministic, illustrative (non-geographic) layout for N stops inside
/// [size] — a gentle wave rather than a straight line, so it doesn't read as
/// a flat progress bar. Shared by [WrapUpRoutePathPainter] and the section
/// widget that overlays place labels at the same points.
List<Offset> layoutRoutePoints(int count, Size size) {
  if (count <= 0) return const [];
  const paddingX = 24.0;
  const amplitude = 34.0;
  final usableWidth = (size.width - paddingX * 2).clamp(0.0, size.width);
  final midY = size.height / 2;

  if (count == 1) {
    return [Offset(size.width / 2, midY)];
  }

  return [
    for (var i = 0; i < count; i++)
      Offset(
        paddingX + usableWidth * (i / (count - 1)),
        midY + amplitude * (i.isEven ? -1 : 1) * ((i % 3 == 0) ? 0.4 : 1),
      ),
  ];
}

Path _smoothPathThrough(List<Offset> points) {
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (var i = 0; i < points.length - 1; i++) {
    final p0 = points[i];
    final p1 = points[i + 1];
    final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
    path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
  }
  path.lineTo(points.last.dx, points.last.dy);
  return path;
}

/// The `drawRoute` motion token: a soft casing beneath a stroke that reveals
/// itself over [progress] (0→1), plus node dots — start (primary), waypoints
/// (coral), end (white). A single stop renders as one dot, no line.
class WrapUpRoutePathPainter extends CustomPainter {
  const WrapUpRoutePathPainter({required this.points, required this.progress});

  final List<Offset> points;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    if (points.length == 1) {
      _paintDot(canvas, points.first, AppColors.primary, 5.5);
      return;
    }

    final path = _smoothPathThrough(points);

    final casingPaint = Paint()
      ..color = AppColors.tint(AppColors.primary, .22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, casingPaint);

    final strokePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final metrics = path.computeMetrics().toList();
    final totalLength = metrics.fold<double>(0, (sum, m) => sum + m.length);
    var remaining = totalLength * progress.clamp(0.0, 1.0);
    for (final metric in metrics) {
      if (remaining <= 0) break;
      final extractLength = remaining.clamp(0.0, metric.length);
      canvas.drawPath(metric.extractPath(0, extractLength), strokePaint);
      remaining -= metric.length;
    }

    for (var i = 0; i < points.length; i++) {
      final isStart = i == 0;
      final isEnd = i == points.length - 1;
      final color = isStart
          ? AppColors.primary
          : isEnd
          ? AppColors.textOnPhoto
          : AppColors.accentCoral;
      _paintDot(canvas, points[i], color, isStart || isEnd ? 5.5 : 4);
    }
  }

  void _paintDot(ui.Canvas canvas, Offset center, Color color, double radius) {
    canvas.drawCircle(center, radius, Paint()..color = color);
  }

  @override
  bool shouldRepaint(WrapUpRoutePathPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.progress != progress;
}
