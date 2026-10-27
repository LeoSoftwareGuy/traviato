import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/features/bonus/presentation/providers/bonus_task_providers.dart';
import 'package:traviato/features/journal/presentation/controllers/journal_controller.dart';
import 'package:traviato/features/journal/presentation/providers/day_note_providers.dart';
import 'package:traviato/features/photo/domain/entities/film_pick.dart';
import 'package:traviato/features/photo/domain/entities/photo_entity.dart';
import 'package:traviato/features/photo/presentation/pages/photo_viewer_page.dart';
import 'package:traviato/features/photo/presentation/providers/photo_providers.dart';
import 'package:traviato/features/quest/presentation/providers/quest_providers.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';

import '../../../bonus/fakes/fake_bonus_task_repository.dart';
import '../../../journal/fakes/fake_day_note_repository.dart';
import '../../../quest/fakes/fake_quest_repository.dart';
import '../../../trip/fakes/fake_trip_repository.dart';
import '../../fakes/fake_photo_repository.dart';

const _tripId = 't1';

/// 10 Auto photos on one day: the film picks 8 of them, so two are "Not
/// picked right now".
final _photos = [
  for (var i = 0; i < 10; i++)
    buildPhotoEntity(
      id: 'p$i',
      tripId: _tripId,
      dayDate: DateTime(2026, 6, 1),
      takenAt: DateTime.utc(2026, 6, 1, 8 + i),
    ),
];

class _Opener extends ConsumerWidget {
  const _Opener({required this.initialIndex});

  final int initialIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(journalControllerProvider(_tripId)).value?.photos;
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: photos == null
              ? null
              : () => PhotoViewerPage.show(
                  context,
                  photos: photos,
                  initialIndex: initialIndex,
                  filmTripId: _tripId,
                ),
          child: const Text('Open'),
        ),
      ),
    );
  }
}

Future<ProviderContainer> _open(
  WidgetTester tester, {
  required FakePhotoRepository photoRepo,
  int initialIndex = 0,
}) async {
  late final ProviderContainer container;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tripRepositoryProvider.overrideWithValue(FakeTripRepository()),
        photoRepositoryProvider.overrideWithValue(photoRepo),
        dayNoteRepositoryProvider.overrideWithValue(FakeDayNoteRepository()),
        questRepositoryProvider.overrideWithValue(FakeQuestRepository()),
        bonusTaskRepositoryProvider.overrideWithValue(
          FakeBonusTaskRepository(),
        ),
      ],
      child: Builder(
        builder: (context) {
          container = ProviderScope.containerOf(context);
          return MaterialApp(home: _Opener(initialIndex: initialIndex));
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return container;
}

String _hint(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('film-pick-hint'))).data!;

void main() {
  group('photo viewer film pick (#294)', () {
    testWidgets('shows whether the film chose the current photo', (
      tester,
    ) async {
      final repo = FakePhotoRepository()..photosResult = Right(_photos);
      // Spread over 10, the film picks p0, p1, p3, p4, p5, p6, p8, p9.
      await _open(tester, photoRepo: repo);
      expect(find.byKey(const Key('film-pick-panel')), findsOneWidget);
      expect(_hint(tester), 'Film chose this one');

      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byKey(const Key('photo-viewer-next')));
        await tester.pumpAndSettle();
      }
      expect(_hint(tester), 'Not picked right now'); // p2
    });

    testWidgets('Leave out saves at once and dims the photo, no snackbar', (
      tester,
    ) async {
      final repo = FakePhotoRepository()..photosResult = Right(_photos);
      final container = await _open(tester, photoRepo: repo);

      await tester.tap(find.byKey(const Key('film-pick-never')));
      await tester.pump();

      expect(repo.filmPickCalls, [('p0', FilmPick.never)]);
      // Only the pill says it — no confirmation snackbar (#300).
      expect(find.text('Left out of the film'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(
        find.byKey(const Key('photo-viewer-left-out-pill')),
        findsOneWidget,
      );
      expect(_hint(tester), "Won't appear anywhere");
      await tester.pumpAndSettle();

      final journalPhoto = container
          .read(journalControllerProvider(_tripId))
          .value!
          .photos
          .firstWhere((PhotoEntity p) => p.id == 'p0');
      expect(journalPhoto.filmPick, FilmPick.never);
    });

    testWidgets('Always shows its own hint, no snackbar', (tester) async {
      final repo = FakePhotoRepository()..photosResult = Right(_photos);
      await _open(tester, photoRepo: repo, initialIndex: 7);

      await tester.tap(find.byKey(const Key('film-pick-always')));
      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);
      expect(_hint(tester), 'Your pick · gets a main moment');
      expect(find.byKey(const Key('photo-viewer-left-out-pill')), findsNothing);
      await tester.pumpAndSettle();
    });
  });
}
