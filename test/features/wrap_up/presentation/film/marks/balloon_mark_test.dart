import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_tokens.dart';
import 'package:traviato/features/wrap_up/presentation/film/marks/balloon_mark.dart';

/// Counts its paints, to check a swapped-in shape is what gets drawn.
class _BoxShape implements BalloonMarkShape {
  int paints = 0;

  @override
  Size get size => const Size(100, 100);

  @override
  void paint(Canvas canvas, BalloonMarkStyle style) {
    paints++;
    canvas.drawRect(Offset.zero & size, Paint()..color = style.basket);
  }
}

void main() {
  test("the spec's drawing is 200×292", () {
    const mark = BalloonMark(style: GoldenVowsColors.balloon);
    expect(mark.size, const Size(200, 292));
  });

  test('a swapped-in shape is what gets painted', () {
    final shape = _BoxShape();
    final recorder = ui.PictureRecorder();
    BalloonMark(style: GoldenVowsColors.balloon, shape: shape).paint(
      Canvas(recorder),
      topLeft: const Offset(10, 20),
      scale: 1.25,
      rotationDeg: 4,
      opacity: 0.5,
    );
    recorder.endRecording().dispose();
    expect(shape.paints, 1);
  });

  test('a mark at no opacity paints nothing', () {
    final shape = _BoxShape();
    final recorder = ui.PictureRecorder();
    BalloonMark(
      style: GoldenVowsColors.balloon,
      shape: shape,
    ).paint(Canvas(recorder), topLeft: Offset.zero, opacity: 0);
    recorder.endRecording().dispose();
    expect(shape.paints, 0);
  });

  testWidgets('the widget keeps the drawing proportions', (tester) async {
    await tester.pumpWidget(
      const Center(
        child: SizedBox(
          width: 100,
          child: BalloonMarkView(
            mark: BalloonMark(style: GoldenVowsColors.balloon),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(BalloonMarkView)), const Size(100, 146));
  });
}
