import 'package:flutter/rendering.dart';

/// Notebook rules: a 1px line at the bottom of every [lineHeight] band.
/// Painted *inside* the scroll view, under the text, so the rules scroll
/// with the content and stay on the text's line grid.
class RuledLinesPainter extends CustomPainter {
  const RuledLinesPainter({required this.lineHeight, required this.color});

  final double lineHeight;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var y = lineHeight - 0.5; y <= size.height; y += lineHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(RuledLinesPainter oldDelegate) =>
      oldDelegate.lineHeight != lineHeight || oldDelegate.color != color;
}
