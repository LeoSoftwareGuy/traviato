import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/guarded_painter.dart';

/// Saves twice, then throws mid-paint.
class _ThrowingPainter extends CustomPainter {
  int paints = 0;

  @override
  void paint(Canvas canvas, Size size) {
    paints++;
    canvas
      ..save()
      ..save();
    throw StateError('broken page');
  }

  @override
  bool shouldRepaint(_ThrowingPainter oldDelegate) => false;
}

void main() {
  test('a throw becomes one onError, the canvas restored, then nothing', () {
    final inner = _ThrowingPainter();
    final errors = <Object>[];
    final painter = GuardedPainter(
      inner,
      repaint: ValueNotifier(0),
      onError: (error, _) => errors.add(error),
    );
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    painter.paint(canvas, const Size(10, 10));
    expect(errors.single, isA<StateError>());
    expect(canvas.getSaveCount(), 1);

    painter.paint(canvas, const Size(10, 10));
    expect(inner.paints, 1);
    expect(errors, hasLength(1));
    recorder.endRecording().dispose();
  });
}
