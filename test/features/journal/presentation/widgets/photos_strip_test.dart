import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/journal/presentation/widgets/photos_strip.dart';
import 'package:traviato/features/photo/domain/entities/film_pick.dart';
import 'package:traviato/features/photo/domain/entities/photo_entity.dart';

import '../../../photo/fakes/fake_photo_repository.dart';

Future<void> _pumpStrip(
  WidgetTester tester, {
  required List<PhotoEntity> photos,
  VoidCallback? onAddTap,
  ValueChanged<int>? onPhotoTap,
  Set<String> filmMomentIds = const {},
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PhotosStrip(
          photos: photos,
          onAddTap: onAddTap ?? () {},
          onPhotoTap: onPhotoTap ?? (_) {},
          filmMomentIds: filmMomentIds,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('tapping a photo tile reports its index', (tester) async {
    int? tappedIndex;

    await _pumpStrip(
      tester,
      photos: [
        buildPhotoEntity(id: 'p1'),
        buildPhotoEntity(id: 'p2'),
        buildPhotoEntity(id: 'p3'),
      ],
      onPhotoTap: (index) => tappedIndex = index,
    );

    await tester.tap(find.byKey(const Key('journal-photo-tile-p2')));
    await tester.pump();

    expect(tappedIndex, 1);
  });

  testWidgets('the Add tile still calls onAddTap, not onPhotoTap', (
    tester,
  ) async {
    var addTapped = false;

    await _pumpStrip(
      tester,
      photos: const [],
      onAddTap: () => addTapped = true,
      onPhotoTap: (_) => fail('onPhotoTap should not be called'),
    );

    await tester.tap(find.byKey(const Key('journal-add-photo')));
    await tester.pump();

    expect(addTapped, isTrue);
  });

  testWidgets('lays out one fixed-size row, led by the Add tile', (
    tester,
  ) async {
    await _pumpStrip(
      tester,
      photos: [for (var i = 1; i <= 12; i++) buildPhotoEntity(id: 'p$i')],
    );

    final add = tester.getRect(find.byKey(const Key('journal-add-photo')));
    final first = tester.getRect(
      find.byKey(const Key('journal-photo-tile-p1')),
    );
    final second = tester.getRect(
      find.byKey(const Key('journal-photo-tile-p2')),
    );

    expect(first.size, const Size(80, 100));
    expect(add.left, lessThan(first.left));
    expect(first.top, second.top);
    expect(second.left - first.right, 10);
  });

  testWidgets('scrolling the row snaps a tile to the leading edge', (
    tester,
  ) async {
    await _pumpStrip(
      tester,
      photos: [for (var i = 1; i <= 20; i++) buildPhotoEntity(id: 'p$i')],
    );
    final strip = find.byKey(const Key('journal-photo-strip'));

    await tester.timedDrag(
      strip,
      const Offset(-130, 0),
      const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();

    // Settles on a whole 90px step (80 tile + 10 gap), never mid-tile.
    final offset = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position
        .pixels;
    expect(offset, greaterThan(0));
    expect(offset % 90, 0);
  });

  testWidgets('shows a time pill only on photos with a taken-at time', (
    tester,
  ) async {
    await _pumpStrip(
      tester,
      photos: [
        buildPhotoEntity(id: 'p1', takenAt: DateTime(2026, 5, 3, 9, 5)),
        buildPhotoEntity(id: 'p2'),
      ],
    );

    expect(find.text('9:05 AM'), findsOneWidget);
    expect(find.byKey(const Key('journal-photo-time-pill')), findsOneWidget);
  });

  testWidgets('a newly added photo scrolls into view (#291)', (tester) async {
    final photos = [
      for (var i = 0; i < 8; i++) buildPhotoEntity(id: 'p$i'),
    ];
    await _pumpStrip(tester, photos: photos);
    final strip = find.byKey(const Key('journal-photo-strip'));
    expect(find.byKey(const Key('journal-photo-tile-p8')), findsNothing);

    await _pumpStrip(
      tester,
      photos: [
        ...photos,
        buildPhotoEntity(id: 'p8'),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('journal-photo-tile-p8')), findsOneWidget);
    final scrollable = tester.state<ScrollableState>(
      find.descendant(of: strip, matching: find.byType(Scrollable)),
    );
    expect(scrollable.position.pixels, greaterThan(0));
  });

  testWidgets('a rebuild without new photos leaves the scroll alone', (
    tester,
  ) async {
    final photos = [
      for (var i = 0; i < 8; i++) buildPhotoEntity(id: 'p$i'),
    ];
    await _pumpStrip(tester, photos: photos);
    await _pumpStrip(tester, photos: [...photos]);
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byKey(const Key('journal-photo-strip')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scrollable.position.pixels, 0);
  });

  group('film markers (#294)', () {
    final photos = [
      buildPhotoEntity(id: 'picked'),
      buildPhotoEntity(id: 'skipped'),
      buildPhotoEntity(id: 'mine', filmPick: FilmPick.always),
      buildPhotoEntity(id: 'out', filmPick: FilmPick.never),
    ];

    Finder badge(String photoId, String kind) => find.descendant(
      of: find.byKey(Key('journal-photo-tile-$photoId')),
      matching: find.byKey(Key('journal-photo-film-badge-$kind')),
    );

    testWidgets('each thumb shows its film state', (tester) async {
      await _pumpStrip(
        tester,
        photos: photos,
        // The generator never picks a left-out photo, but even if the set
        // said so, Leave out wins.
        filmMomentIds: {'picked', 'out'},
      );

      expect(badge('picked', 'autoPicked'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('journal-photo-tile-skipped')),
          matching: find.byKey(
            const Key('journal-photo-film-badge-autoPicked'),
          ),
        ),
        findsNothing,
      );
      expect(badge('mine', 'yourPick'), findsOneWidget);
      expect(find.text('▸ Your pick'), findsOneWidget);
      expect(badge('out', 'leftOut'), findsOneWidget);
      expect(find.text('Left out'), findsOneWidget);

      final outOpacity = tester.widget<Opacity>(
        find
            .descendant(
              of: find.byKey(const Key('journal-photo-tile-out')),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(outOpacity.opacity, .45);
    });

    testWidgets('the header counts Always plus Auto-and-picked', (
      tester,
    ) async {
      await _pumpStrip(tester, photos: photos, filmMomentIds: {'picked'});

      expect(find.text('▸ 2 IN THE FILM'), findsOneWidget);
    });

    testWidgets('the header count hides at zero', (tester) async {
      await _pumpStrip(tester, photos: [buildPhotoEntity(id: 'a')]);

      expect(
        find.byKey(const Key('journal-photo-strip-film-count')),
        findsNothing,
      );
    });
  });
}
