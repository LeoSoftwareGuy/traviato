import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_collage_layout.dart';
import 'package:traviato/features/wrap_up/presentation/film/frames/wrap_up_film_collage.dart';
import 'package:traviato/features/wrap_up/presentation/film/frames/wrap_up_film_collage_layouts.dart';

const _at = 40.0;
const _to = 45.0;

Future<void> _pumpAt(
  WidgetTester tester,
  double t,
  WrapUpCollageLayout layout, {
  String? note = 'A line of my own',
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: FittedBox(
        child: SizedBox(
          width: 1080,
          height: 1920,
          child: Stack(
            children: [
              WrapUpFilmCollage(
                t: t,
                at: _at,
                to: _to,
                layout: layout,
                imageUrls: List.filled(layout.tileCount, null),
                note: note,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Finder _tile(int i) => find.byKey(ValueKey('collage-tile-$i'));

Matrix4 _tileTransform(WidgetTester tester, int i) => tester
    .widget<Transform>(
      find.descendant(of: _tile(i), matching: find.byType(Transform)).first,
    )
    .transform;

double _tileOpacity(WidgetTester tester, int i) => tester
    .widget<Opacity>(
      find.descendant(of: _tile(i), matching: find.byType(Opacity)).first,
    )
    .opacity;

double _captionOpacity(WidgetTester tester) => tester
    .widget<Opacity>(
      find
          .ancestor(
            of: find.byKey(const Key('collage-caption')),
            matching: find.byType(Opacity),
          )
          .first,
    )
    .opacity;

void main() {
  group('tornOutline', () {
    test('is deterministic — same input, same outline, every time', () {
      Path build() => tornOutline(
        w: 572,
        h: 968,
        tornEdges: 'rb',
        seed: 17,
        amp: 7,
        pad: 11,
      );
      expect(build().getBounds(), build().getBounds());
      expect(identical(build(), build()), isTrue);
    });

    test('a different seed tears differently', () {
      final a = tornOutline(
        w: 572,
        h: 968,
        tornEdges: 'rb',
        seed: 3,
        amp: 5,
        pad: -2,
      );
      final b = tornOutline(
        w: 572,
        h: 968,
        tornEdges: 'rb',
        seed: 4,
        amp: 5,
        pad: -2,
      );
      expect(a.getBounds() == b.getBounds(), isFalse);
    });

    test('straight edges overhang the tile by 60px, torn edges hug it', () {
      final bounds = tornOutline(
        w: 500,
        h: 800,
        tornEdges: 'rb',
        seed: 3,
        amp: 5,
        pad: -2,
      ).getBounds();
      // Untorn top/left reach past the tile...
      expect(bounds.left, -tornEdgeOverhang);
      expect(bounds.top, -tornEdgeOverhang);
      // ...torn right/bottom stay within the tear amplitude of the edge.
      expect(bounds.right, closeTo(500, 10));
      expect(bounds.bottom, closeTo(800, 10));
    });
  });

  group('WrapUpFilmCollage', () {
    testWidgets('nothing renders before its window opens', (tester) async {
      await _pumpAt(tester, _at - 0.6, WrapUpCollageLayout.torn4);
      expect(_tile(0), findsNothing);
    });

    testWidgets('torn4 at M5 + 0.5: all four tiles present', (tester) async {
      await _pumpAt(tester, _at + 0.5, WrapUpCollageLayout.torn4);
      for (var i = 0; i < 4; i++) {
        expect(_tile(i), findsOneWidget);
      }
    });

    testWidgets('torn4 tiles are fully settled by at + 0.95', (tester) async {
      await _pumpAt(tester, _at + 0.95, WrapUpCollageLayout.torn4);
      for (var i = 0; i < 4; i++) {
        expect(_tileOpacity(tester, i), 1.0, reason: 'tile $i opacity');
        final translation = _tileTransform(tester, i).getTranslation();
        expect(translation.x, closeTo(0, 0.001), reason: 'tile $i x');
        expect(translation.y, closeTo(0, 0.001), reason: 'tile $i y');
      }
    });

    testWidgets('torn6 at M8 + 1.5: grayscale hero painted on top', (
      tester,
    ) async {
      await _pumpAt(tester, _at + 1.5, WrapUpCollageLayout.torn6);

      final tiles = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('collage-tile-'),
      );
      final order = tester
          .widgetList(tiles)
          .map((w) => (w.key! as ValueKey<String>).value)
          .toList();
      expect(order.last, 'collage-tile-5');
      expect(
        find.descendant(of: _tile(5), matching: find.byType(ColorFiltered)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: _tile(0), matching: find.byType(ColorFiltered)),
        findsNothing,
      );
      // The caption is well into its rise at +1.5...
      expect(_captionOpacity(tester), greaterThan(0.7));
    });

    testWidgets('the caption is fully visible once its rise completes', (
      tester,
    ) async {
      await _pumpAt(tester, _at + 2.3, WrapUpCollageLayout.torn6);
      expect(_captionOpacity(tester), 1.0);
    });

    testWidgets('no note means no caption, never a generated one', (
      tester,
    ) async {
      await _pumpAt(tester, _at + 2.3, WrapUpCollageLayout.stack3, note: null);
      expect(find.byKey(const Key('collage-caption')), findsNothing);
    });

    testWidgets('fully gone at `to`, leaving the next moment unobstructed', (
      tester,
    ) async {
      await _pumpAt(tester, _to, WrapUpCollageLayout.tilt6);
      expect(_tile(0), findsNothing);
      expect(find.byKey(const Key('collage-caption')), findsNothing);
    });

    testWidgets('a long caption fits a small (375×667) screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await _pumpAt(
        tester,
        _at + 2.3,
        WrapUpCollageLayout.torn4,
        note:
            'The morning the fog lifted off the lake and we finally saw '
            'how far we had actually walked the day before.',
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('collage-caption')), findsOneWidget);
    });
  });
}
