import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/photo/domain/entities/photo_entity.dart';
import 'package:traviato/features/photo/presentation/pages/photo_viewer_page.dart';

import '../../fakes/fake_photo_repository.dart';

Future<void> _openViewer(
  WidgetTester tester, {
  required List<PhotoEntity> photos,
  required int initialIndex,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => PhotoViewerPage.show(
                context,
                photos: photos,
                initialIndex: initialIndex,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

List<PhotoEntity> _photos(int count) => [
  for (var i = 1; i <= count; i++) buildPhotoEntity(id: 'p$i'),
];

final _pager = find.byKey(const Key('photo-viewer-pager'));

void main() {
  group('wrappedPhotoIndex', () {
    test('is always 0 for a single-photo day', () {
      expect(wrappedPhotoIndex(0, 1), 0);
      expect(wrappedPhotoIndex(1000, 1), 0);
    });

    test('wraps a page number back into range in both directions', () {
      expect(wrappedPhotoIndex(0, 4), 0);
      expect(wrappedPhotoIndex(3, 4), 3);
      expect(wrappedPhotoIndex(4, 4), 0);
      expect(wrappedPhotoIndex(9, 4), 1);
      expect(wrappedPhotoIndex(-1, 4), 3);
      expect(wrappedPhotoIndex(-5, 4), 3);
    });
  });

  group('PhotoViewerPage', () {
    testWidgets('opens at the tapped index', (tester) async {
      await _openViewer(tester, photos: _photos(3), initialIndex: 1);

      expect(find.text('2 / 3'), findsOneWidget);
    });

    testWidgets('arrow buttons page forward and back, wrapping at both ends', (
      tester,
    ) async {
      await _openViewer(tester, photos: _photos(3), initialIndex: 0);
      expect(find.text('1 / 3'), findsOneWidget);

      await tester.tap(find.byKey(const Key('photo-viewer-next')));
      await tester.pumpAndSettle();
      expect(find.text('2 / 3'), findsOneWidget);

      await tester.tap(find.byKey(const Key('photo-viewer-next')));
      await tester.pumpAndSettle();
      expect(find.text('3 / 3'), findsOneWidget);

      // Wraps from the last photo back to the first.
      await tester.tap(find.byKey(const Key('photo-viewer-next')));
      await tester.pumpAndSettle();
      expect(find.text('1 / 3'), findsOneWidget);

      // Wraps from the first photo back to the last, the other direction.
      await tester.tap(find.byKey(const Key('photo-viewer-prev')));
      await tester.pumpAndSettle();
      expect(find.text('3 / 3'), findsOneWidget);
    });

    testWidgets('a drag past the threshold pages to the neighbour', (
      tester,
    ) async {
      await _openViewer(tester, photos: _photos(3), initialIndex: 0);

      await tester.drag(_pager, const Offset(-200, 0));
      await tester.pumpAndSettle();
      expect(find.text('2 / 3'), findsOneWidget);

      await tester.drag(_pager, const Offset(200, 0));
      await tester.pumpAndSettle();
      expect(find.text('1 / 3'), findsOneWidget);

      // Dragging right from the first photo wraps to the last.
      await tester.drag(_pager, const Offset(200, 0));
      await tester.pumpAndSettle();
      expect(find.text('3 / 3'), findsOneWidget);
    });

    testWidgets('a short, slow drag springs back to the same photo', (
      tester,
    ) async {
      await _openViewer(tester, photos: _photos(3), initialIndex: 1);

      await tester.timedDrag(
        _pager,
        const Offset(-40, 0),
        const Duration(milliseconds: 600),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 / 3'), findsOneWidget);
    });

    testWidgets('the photo follows the finger mid-drag', (tester) async {
      await _openViewer(tester, photos: _photos(2), initialIndex: 0);
      final slide = find.byKey(const ValueKey(0));
      final restingX = tester.getTopLeft(slide).dx;

      final gesture = await tester.startGesture(tester.getCenter(_pager));
      await gesture.moveBy(const Offset(-30, 0));
      await gesture.moveBy(const Offset(-30, 0));
      await tester.pump();

      expect(tester.getTopLeft(slide).dx, closeTo(restingX - 60, .5));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('arrows and the counter are hidden for a single-photo day', (
      tester,
    ) async {
      await _openViewer(tester, photos: _photos(1), initialIndex: 0);

      expect(find.byKey(const Key('photo-viewer-prev')), findsNothing);
      expect(find.byKey(const Key('photo-viewer-next')), findsNothing);
      expect(find.byKey(const Key('photo-viewer-counter')), findsNothing);
    });

    testWidgets('shows the caption and time of the current photo', (
      tester,
    ) async {
      final photos = [
        buildPhotoEntity(
          id: 'p1',
          caption: 'Sunset at the pier',
          takenAt: DateTime(2026, 5, 3, 19, 42),
        ),
        buildPhotoEntity(id: 'p2', caption: 'Breakfast'),
      ];

      await _openViewer(tester, photos: photos, initialIndex: 0);
      expect(find.text('Sunset at the pier'), findsOneWidget);
      expect(find.text('May 3, 7:42 PM'), findsOneWidget);

      await tester.tap(find.byKey(const Key('photo-viewer-next')));
      await tester.pumpAndSettle();
      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('May 3, 7:42 PM'), findsNothing);
    });

    testWidgets('tapping the close button dismisses the viewer', (
      tester,
    ) async {
      await _openViewer(tester, photos: _photos(2), initialIndex: 0);
      expect(find.byType(PhotoViewerPage), findsOneWidget);

      await tester.tap(find.byKey(const Key('photo-viewer-close')));
      await tester.pumpAndSettle();

      expect(find.byType(PhotoViewerPage), findsNothing);
    });

    testWidgets('tapping the bare backdrop dismisses the viewer', (
      tester,
    ) async {
      await _openViewer(tester, photos: _photos(2), initialIndex: 0);

      // The outer gutter, outside the track and caption.
      await tester.tapAt(const Offset(4, 596));
      await tester.pumpAndSettle();

      expect(find.byType(PhotoViewerPage), findsNothing);
    });

    testWidgets('tapping the photo or the counter does not dismiss', (
      tester,
    ) async {
      await _openViewer(tester, photos: _photos(2), initialIndex: 0);

      await tester.tap(_pager);
      await tester.tap(find.byKey(const Key('photo-viewer-counter')));
      await tester.pumpAndSettle();

      expect(find.byType(PhotoViewerPage), findsOneWidget);
    });

    testWidgets('dragging the photo does not dismiss the viewer', (
      tester,
    ) async {
      await _openViewer(tester, photos: _photos(2), initialIndex: 0);

      await tester.drag(_pager, const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.byType(PhotoViewerPage), findsOneWidget);
    });
  });
}
