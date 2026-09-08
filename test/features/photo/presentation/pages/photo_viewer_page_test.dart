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

void main() {
  group('wrappedPhotoIndex', () {
    test('is always 0 for a single-photo day', () {
      expect(wrappedPhotoIndex(0, 1), 0);
      expect(wrappedPhotoIndex(1000, 1), 0);
    });

    test('wraps a page number back into range via modulo', () {
      expect(wrappedPhotoIndex(0, 4), 0);
      expect(wrappedPhotoIndex(3, 4), 3);
      expect(wrappedPhotoIndex(4, 4), 0);
      expect(wrappedPhotoIndex(9, 4), 1);
    });
  });

  group('PhotoViewerPage', () {
    testWidgets('opens at the tapped index', (tester) async {
      final photos = [
        buildPhotoEntity(id: 'p1'),
        buildPhotoEntity(id: 'p2'),
        buildPhotoEntity(id: 'p3'),
      ];

      await _openViewer(tester, photos: photos, initialIndex: 1);

      expect(find.text('2 / 3'), findsOneWidget);
    });

    testWidgets(
      'arrow buttons page identically to swipe, and wrap at both ends',
      (tester) async {
        final photos = [
          buildPhotoEntity(id: 'p1'),
          buildPhotoEntity(id: 'p2'),
          buildPhotoEntity(id: 'p3'),
        ];

        await _openViewer(tester, photos: photos, initialIndex: 0);
        expect(find.text('1 / 3'), findsOneWidget);

        await tester.tap(find.byKey(const Key('photo-viewer-next')));
        await tester.pumpAndSettle();
        expect(find.text('2 / 3'), findsOneWidget);

        // Wraps from the last photo back to the first.
        await tester.tap(find.byKey(const Key('photo-viewer-next')));
        await tester.pumpAndSettle();
        expect(find.text('3 / 3'), findsOneWidget);
        await tester.tap(find.byKey(const Key('photo-viewer-next')));
        await tester.pumpAndSettle();
        expect(find.text('1 / 3'), findsOneWidget);

        // Wraps from the first photo back to the last, the other direction.
        await tester.tap(find.byKey(const Key('photo-viewer-prev')));
        await tester.pumpAndSettle();
        expect(find.text('3 / 3'), findsOneWidget);
      },
    );

    testWidgets('swiping the pager pages to the neighboring photo', (
      tester,
    ) async {
      final photos = [buildPhotoEntity(id: 'p1'), buildPhotoEntity(id: 'p2')];

      await _openViewer(tester, photos: photos, initialIndex: 0);
      expect(find.text('1 / 2'), findsOneWidget);

      await tester.drag(
        find.byKey(const Key('photo-viewer-pager')),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 / 2'), findsOneWidget);
    });

    testWidgets('arrows and the counter are hidden for a single-photo day', (
      tester,
    ) async {
      final photos = [buildPhotoEntity(id: 'p1')];

      await _openViewer(tester, photos: photos, initialIndex: 0);

      expect(find.byKey(const Key('photo-viewer-prev')), findsNothing);
      expect(find.byKey(const Key('photo-viewer-next')), findsNothing);
      expect(
        find.byKey(const Key('photo-viewer-backdrop-bottom')),
        findsNothing,
      );
    });

    testWidgets('tapping the close button dismisses the viewer', (
      tester,
    ) async {
      final photos = [buildPhotoEntity(id: 'p1'), buildPhotoEntity(id: 'p2')];

      await _openViewer(tester, photos: photos, initialIndex: 0);
      expect(find.text('Open'), findsNothing);

      await tester.tap(find.byKey(const Key('photo-viewer-close')));
      await tester.pumpAndSettle();

      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('tapping the backdrop dismisses the viewer', (tester) async {
      final photos = [buildPhotoEntity(id: 'p1'), buildPhotoEntity(id: 'p2')];

      await _openViewer(tester, photos: photos, initialIndex: 0);

      await tester.tap(find.byKey(const Key('photo-viewer-backdrop-top')));
      await tester.pumpAndSettle();

      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets(
      'tapping the caption/counter backdrop below the image dismisses too',
      (tester) async {
        final photos = [
          buildPhotoEntity(id: 'p1'),
          buildPhotoEntity(id: 'p2'),
        ];

        await _openViewer(tester, photos: photos, initialIndex: 0);

        await tester.tap(find.byKey(const Key('photo-viewer-backdrop-bottom')));
        await tester.pumpAndSettle();

        expect(find.text('Open'), findsOneWidget);
      },
    );

    testWidgets('dragging the photo does not dismiss the viewer', (
      tester,
    ) async {
      final photos = [buildPhotoEntity(id: 'p1'), buildPhotoEntity(id: 'p2')];

      await _openViewer(tester, photos: photos, initialIndex: 0);

      await tester.drag(
        find.byKey(const Key('photo-viewer-pager')),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      expect(find.text('Open'), findsNothing);
    });
  });
}
