import 'package:flutter/widgets.dart';

/// Paints [inner], but turns its first throw into [onError] instead of a
/// broken frame, leaving the canvas as it found it, and paints nothing
/// after (#345).
class GuardedPainter extends CustomPainter {
  GuardedPainter(
    this.inner, {
    required Listenable repaint,
    required this.onError,
  }) : super(repaint: repaint);

  final CustomPainter inner;
  final void Function(Object error, StackTrace stack) onError;
  bool _broken = false;

  @override
  void paint(Canvas canvas, Size size) {
    if (_broken) return;
    final saves = canvas.getSaveCount();
    try {
      inner.paint(canvas, size);
    } catch (error, stack) {
      canvas.restoreToCount(saves);
      _broken = true;
      onError(error, stack);
    }
  }

  @override
  bool shouldRepaint(GuardedPainter oldDelegate) =>
      inner.shouldRepaint(oldDelegate.inner);
}
