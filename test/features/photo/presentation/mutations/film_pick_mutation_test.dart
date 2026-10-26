import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/core/events/global_event.dart';
import 'package:traviato/core/events/global_event_bus.dart';
import 'package:traviato/features/journal/presentation/controllers/journal_controller.dart';
import 'package:traviato/features/journal/presentation/providers/day_note_providers.dart';
import 'package:traviato/features/photo/domain/entities/film_pick.dart';
import 'package:traviato/features/photo/domain/entities/photo_entity.dart';
import 'package:traviato/features/photo/presentation/mutations/photo_mutations.dart';
import 'package:traviato/features/photo/presentation/providers/photo_providers.dart';
import 'package:traviato/features/quest/presentation/providers/quest_providers.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';

import '../../../journal/fakes/fake_day_note_repository.dart';
import '../../../quest/fakes/fake_quest_repository.dart';
import '../../../trip/fakes/fake_trip_repository.dart';
import '../../fakes/fake_photo_repository.dart';

const _tripId = 't1';

class _Harness extends ConsumerWidget {
  const _Harness({required this.pick});

  final FilmPick pick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos =
        ref.watch(journalControllerProvider(_tripId)).value?.photos ?? [];
    return MaterialApp(
      home: Scaffold(
        body: ElevatedButton(
          onPressed: () async {
            try {
              await runSetFilmPick(
                ref: ref,
                tripId: _tripId,
                photo: photos.first,
                pick: pick,
              );
            } catch (_) {
              // Surfaced via the mutation's MutationError state instead.
            }
          },
          child: const Text('Pick'),
        ),
      ),
    );
  }
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required FakePhotoRepository photoRepo,
  required FilmPick pick,
}) async {
  late final ProviderContainer container;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tripRepositoryProvider.overrideWithValue(FakeTripRepository()),
        photoRepositoryProvider.overrideWithValue(photoRepo),
        dayNoteRepositoryProvider.overrideWithValue(FakeDayNoteRepository()),
        questRepositoryProvider.overrideWithValue(FakeQuestRepository()),
      ],
      child: Builder(
        builder: (context) {
          container = ProviderScope.containerOf(context);
          return _Harness(pick: pick);
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

FakePhotoRepository _repo() =>
    FakePhotoRepository()
      ..photosResult = Right([buildPhotoEntity(id: 'p0', tripId: _tripId)]);

PhotoEntity _photo(ProviderContainer container) =>
    container.read(journalControllerProvider(_tripId)).value!.photos.single;

void main() {
  group('runSetFilmPick (#294)', () {
    testWidgets('saves the pick, stamps it, and tells open films', (
      tester,
    ) async {
      final repo = _repo()..setFilmPickResult = Right(DateTime.utc(2026, 7, 2));
      final container = await _pump(
        tester,
        photoRepo: repo,
        pick: FilmPick.never,
      );
      final events = <GlobalEvent>[];
      final sub = container
          .read(globalEventBusProvider)
          .stream
          .listen(events.add);
      addTearDown(sub.cancel);

      await tester.tap(find.text('Pick'));
      await tester.pumpAndSettle();

      expect(repo.filmPickCalls, [('p0', FilmPick.never)]);
      expect(_photo(container).filmPick, FilmPick.never);
      expect(_photo(container).filmPickSetAt, DateTime.utc(2026, 7, 2));
      expect(events, [const FilmPhotosChangedDispatched(tripId: _tripId)]);
    });

    testWidgets('puts the pick back when the save fails', (tester) async {
      final repo = _repo()
        ..setFilmPickResult = const Left<Failure, DateTime?>(NetworkFailure());
      final container = await _pump(
        tester,
        photoRepo: repo,
        pick: FilmPick.always,
      );
      container.listen(setFilmPickMutation, (_, _) {});

      await tester.tap(find.text('Pick'));
      await tester.pumpAndSettle();

      expect(_photo(container).filmPick, FilmPick.auto);
      expect(container.read(setFilmPickMutation), isA<MutationError<void>>());
    });

    testWidgets('a settle for an older tap never overwrites a newer one', (
      tester,
    ) async {
      final container = await _pump(
        tester,
        photoRepo: _repo(),
        pick: FilmPick.always,
      );
      final controller = container.read(
        journalControllerProvider(_tripId).notifier,
      );

      final original = controller.applyPhotoFilmPick('p0', FilmPick.always);
      controller.applyPhotoFilmPick('p0', FilmPick.never);
      // The Always save fails late — the newer Leave out must stand.
      controller.applyPhotoFilmPickSettled(
        'p0',
        FilmPick.always,
        previous: original,
      );

      expect(_photo(container).filmPick, FilmPick.never);
    });
  });
}
