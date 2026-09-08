import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/journal/presentation/widgets/photos_strip.dart';

import '../../../photo/fakes/fake_photo_repository.dart';

void main() {
  testWidgets('tapping a photo tile reports its index', (tester) async {
    final photos = [
      buildPhotoEntity(id: 'p1'),
      buildPhotoEntity(id: 'p2'),
      buildPhotoEntity(id: 'p3'),
    ];
    int? tappedIndex;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PhotosStrip(
            photos: photos,
            onAddTap: () {},
            onPhotoTap: (index) => tappedIndex = index,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('journal-photo-tile-p2')));
    await tester.pump();

    expect(tappedIndex, 1);
  });

  testWidgets('the Add tile still calls onAddTap, not onPhotoTap', (
    tester,
  ) async {
    var addTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PhotosStrip(
            photos: const [],
            onAddTap: () => addTapped = true,
            onPhotoTap: (_) => fail('onPhotoTap should not be called'),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('journal-add-photo')));
    await tester.pump();

    expect(addTapped, isTrue);
  });
}
