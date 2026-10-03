import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/frames/wrap_up_film_plate.dart';
import 'package:traviato/features/wrap_up/presentation/film/wrap_up_film_photo.dart';

// The front face's "no photo" placeholder is the only ColoredBox in this
// widget painted with this exact color — a reliable, non-fragile signal
// that the front face (not the back's gradient) is currently chosen.
final _photoPlaceholder = find.byWidgetPredicate(
  (w) => w is ColoredBox && w.color == const Color(0xFFD9D3C4),
);

Widget _plate(double flip, {double opacity = 1, String? imageUrl}) {
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
            imageUrl: imageUrl,
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

  group('flip lands on a ready photo (#178)', () {
    const url = 'https://example.com/moment.jpg';

    /// Seeds the image cache with a decoded test image under the exact key
    /// [WrapUpFilmPhoto.providerFor] resolves to — what WrapUpPage's
    /// pinning leaves behind before playback. No network involved.
    Future<void> seedDecodedPhoto(WidgetTester tester) async {
      final image = await tester.runAsync(() => createTestImage());
      final key = await WrapUpFilmPhoto.providerFor(
        url,
      ).obtainKey(ImageConfiguration.empty);
      imageCache.putIfAbsent(
        key,
        () => OneFrameImageStreamCompleter(
          SynchronousFuture(ImageInfo(image: image!)),
        ),
      );
      addTearDown(imageCache.clear);
    }

    RawImage rawImage(WidgetTester tester) =>
        tester.widget<RawImage>(find.byType(RawImage));

    testWidgets('the photo paints in the same frame the flip crosses 0.5, '
        'with no placeholder', (tester) async {
      await seedDecodedPhoto(tester);

      await tester.pumpWidget(_plate(0.49, imageUrl: url));
      expect(find.byType(RawImage), findsNothing, reason: 'still the back');

      // One frame, no extra pumps: the threshold frame itself.
      await tester.pumpWidget(_plate(0.5, imageUrl: url));
      expect(rawImage(tester).image, isNotNull);
      expect(_photoPlaceholder, findsNothing);
      expect(find.byType(AnimatedOpacity), findsNothing, reason: 'no fade');

      await tester.pumpWidget(_plate(0.51, imageUrl: url));
      expect(rawImage(tester).image, isNotNull);
      expect(_photoPlaceholder, findsNothing);
    });

    testWidgets('a photo not yet decoded shows the placeholder until it '
        'arrives (the pre-fix flash, now only for a failed precache)', (
      tester,
    ) async {
      await tester.pumpWidget(_plate(1, imageUrl: url));

      expect(_photoPlaceholder, findsOneWidget);
      expect(rawImage(tester).image, isNull);
    });
  });
}
