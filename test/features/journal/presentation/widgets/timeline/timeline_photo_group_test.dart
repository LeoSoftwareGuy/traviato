import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/journal/presentation/widgets/timeline/timeline_photo_group.dart';
import 'package:traviato/features/photo/domain/entities/film_pick.dart';
import 'package:traviato/features/photo/domain/entities/photo_entity.dart';

import '../../../../../helpers/localized_app.dart';
import '../../../../photo/fakes/fake_photo_repository.dart';

Future<void> _pump(
  WidgetTester tester, {
  required List<PhotoEntity> photos,
  ValueChanged<PhotoEntity>? onPhotoTap,
  Set<String> notedPhotoIds = const {},
  Set<String> filmMomentIds = const {},
}) {
  return tester.pumpWidget(
    localizedApp(
      locale: const Locale('en'),
      home: Scaffold(
        body: SizedBox(
          width: 320,
          child: TimelinePhotoGroup(
            photos: photos,
            use24h: true,
            onPhotoTap: onPhotoTap ?? (_) {},
            notedPhotoIds: notedPhotoIds,
            filmMomentIds: filmMomentIds,
          ),
        ),
      ),
    ),
  );
}

Finder _badge(String photoId, String kind) => find.descendant(
  of: find.byKey(Key('timeline-photo-$photoId')),
  matching: find.byKey(Key('journal-photo-film-badge-$kind')),
);

void main() {
  testWidgets('tapping a photo reports that photo', (tester) async {
    PhotoEntity? tapped;
    await _pump(
      tester,
      photos: [
        buildPhotoEntity(id: 'p1'),
        buildPhotoEntity(id: 'p2'),
      ],
      onPhotoTap: (p) => tapped = p,
    );

    await tester.tap(find.byKey(const Key('timeline-photo-p2')));
    expect(tapped?.id, 'p2');
  });

  testWidgets('a single photo has no time pill; a group has one each', (
    tester,
  ) async {
    final at = DateTime(2026, 10, 23, 21, 5);
    await _pump(
      tester,
      photos: [buildPhotoEntity(id: 'p1', takenAt: at)],
    );
    expect(find.byKey(const Key('journal-photo-time-pill')), findsNothing);

    await _pump(
      tester,
      photos: [
        buildPhotoEntity(id: 'p1', takenAt: at),
        buildPhotoEntity(id: 'p2', takenAt: at),
      ],
    );
    expect(find.byKey(const Key('journal-photo-time-pill')), findsNWidgets(2));
    expect(find.text('21:05'), findsNWidgets(2));
  });

  testWidgets('each tile shows its film state (#294)', (tester) async {
    await _pump(
      tester,
      photos: [
        buildPhotoEntity(id: 'picked'),
        buildPhotoEntity(id: 'mine', filmPick: FilmPick.always),
        buildPhotoEntity(id: 'out', filmPick: FilmPick.never),
      ],
      filmMomentIds: {'picked'},
    );

    expect(_badge('picked', 'autoPicked'), findsOneWidget);
    expect(_badge('mine', 'yourPick'), findsOneWidget);
    expect(_badge('out', 'leftOut'), findsOneWidget);
  });

  testWidgets('an Auto photo the film skips has no badge', (tester) async {
    await _pump(tester, photos: [buildPhotoEntity(id: 'p1')]);

    expect(
      find.byKey(const Key('journal-photo-film-badge-autoPicked')),
      findsNothing,
    );
  });

  testWidgets('a photo with notes gets the ✎ badge', (tester) async {
    await _pump(
      tester,
      photos: [
        buildPhotoEntity(id: 'p1'),
        buildPhotoEntity(id: 'p2'),
      ],
      notedPhotoIds: {'p2'},
    );

    expect(
      find.descendant(
        of: find.byKey(const Key('timeline-photo-p2')),
        matching: find.byKey(const Key('timeline-photo-noted')),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('timeline-photo-noted')), findsOneWidget);
  });

  testWidgets('a caption shows under its tile', (tester) async {
    await _pump(
      tester,
      photos: [buildPhotoEntity(id: 'p1', caption: '  Canal at dusk ')],
    );

    expect(find.text('Canal at dusk'), findsOneWidget);
  });
}
