import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/widgets/twinkle_dot.dart';

Widget _dot({required bool reduceMotion}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: const Center(
      child: TwinkleDot(size: 3, color: Colors.white, delayMs: 0),
    ),
  ),
);

({double opacity, double scale}) _pose(WidgetTester tester) {
  final opacity = tester.widget<Opacity>(
    find.descendant(
      of: find.byType(TwinkleDot),
      matching: find.byType(Opacity),
    ),
  );
  final transform = tester.widget<Transform>(
    find.descendant(
      of: find.byType(TwinkleDot),
      matching: find.byType(Transform),
    ),
  );
  return (
    opacity: opacity.opacity,
    scale: transform.transform.getMaxScaleOnAxis(),
  );
}

void main() {
  testWidgets('twinkles when motion is allowed', (tester) async {
    await tester.pumpWidget(_dot(reduceMotion: false));
    await tester.pump();
    final start = _pose(tester);

    // The first pump fires the delayed-start timer; the second advances the
    // loop it started.
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 700));

    expect(_pose(tester).opacity, isNot(start.opacity));
  });

  testWidgets('with reduce motion (#198) it holds still at the loop '
      'midpoint, visibly lit', (tester) async {
    await tester.pumpWidget(_dot(reduceMotion: true));
    final rest = _pose(tester);

    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 400));
      expect(_pose(tester), rest);
    }
    // Between the .12–.85 opacity and .7–1.15 scale extremes, not at the
    // near-invisible start.
    expect(rest.opacity, inExclusiveRange(.3, .7));
    expect(rest.scale, inExclusiveRange(.8, 1.05));
    // Nothing left requesting frames.
    await tester.pumpAndSettle();
  });

  testWidgets('turning reduce motion off while shown starts the twinkle', (
    tester,
  ) async {
    await tester.pumpWidget(_dot(reduceMotion: true));
    final rest = _pose(tester);

    await tester.pumpWidget(_dot(reduceMotion: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(_pose(tester).opacity, isNot(rest.opacity));
  });
}
