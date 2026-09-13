import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/frames/wrap_up_film_plate.dart';

// The front face's "no photo" placeholder is the only ColoredBox in this
// widget painted with this exact color — a reliable, non-fragile signal
// that the front face (not the back's gradient) is currently chosen.
final _photoPlaceholder = find.byWidgetPredicate(
  (w) => w is ColoredBox && w.color == const Color(0xFFD9D3C4),
);

Widget _plate(double flip, {double opacity = 1}) {
  return MaterialApp(
    home: Scaffold(
      body: Stack(
        children: [
          WrapUpFilmPlate(
            cx: 540,
            cy: 960,
            scale: 1,
            rotationDeg: 0,
            opacity: opacity,
            lift: 1,
            flip: flip,
            imageUrl: null,
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('at flip 0 (back), no photo placeholder is rendered', (
    tester,
  ) async {
    await tester.pumpWidget(_plate(0));

    expect(_photoPlaceholder, findsNothing);
  });

  testWidgets('at flip 0.5 (mid-flip), the front face is already chosen', (
    tester,
  ) async {
    await tester.pumpWidget(_plate(0.5));

    // `isFront` is `flip >= 0.5` — the photo placeholder (front face, no
    // imageUrl) should be present.
    expect(_photoPlaceholder, findsOneWidget);
  });

  testWidgets('at flip 1 (front), the photo placeholder is rendered', (
    tester,
  ) async {
    await tester.pumpWidget(_plate(1));

    expect(_photoPlaceholder, findsOneWidget);
  });

  testWidgets('opacity at/under the visibility threshold renders nothing', (
    tester,
  ) async {
    await tester.pumpWidget(_plate(1, opacity: 0.001));

    expect(_photoPlaceholder, findsNothing);
    expect(tester.takeException(), isNull);
  });
}
