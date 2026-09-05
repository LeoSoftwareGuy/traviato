import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/features/journal/presentation/controllers/journal_controller.dart';
import 'package:traviato/features/journal/presentation/controllers/journal_state.dart';
import 'package:traviato/features/journal/presentation/providers/day_note_providers.dart';
import 'package:traviato/features/photo/presentation/providers/photo_providers.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';

import '../../../photo/fakes/fake_photo_repository.dart';
import '../../../trip/fakes/fake_trip_repository.dart';
import '../../fakes/fake_day_note_repository.dart';

ProviderContainer _buildContainer({
  required FakeTripRepository tripRepo,
  required FakePhotoRepository photoRepo,
  required FakeDayNoteRepository noteRepo,
}) {
  return ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      tripRepositoryProvider.overrideWithValue(tripRepo),
      photoRepositoryProvider.overrideWithValue(photoRepo),
      dayNoteRepositoryProvider.overrideWithValue(noteRepo),
    ],
  );
}

void main() {
  test('loads the trip, photos, and the current day note', () async {
    final today = DateTime.now();
    final tripRepo = FakeTripRepository()
      ..tripCardResult = Right(
        buildTripCard(
          id: 't1',
          startDate: today.subtract(const Duration(days: 1)),
          endDate: today.add(const Duration(days: 1)),
        ),
      );
    final photoRepo = FakePhotoRepository()
      ..photosResult = Right([buildPhotoEntity(id: 'p1')]);
    final noteRepo = FakeDayNoteRepository()
      ..getNoteResult = Right(buildDayNoteEntity(content: 'Great day.'));
    final container = _buildContainer(
      tripRepo: tripRepo,
      photoRepo: photoRepo,
      noteRepo: noteRepo,
    );
    addTearDown(container.dispose);

    final state = await container.read(journalControllerProvider('t1').future);

    expect(state.photos, hasLength(1));
    expect(state.currentNote?.content, 'Great day.');
    expect(noteRepo.getNoteCallCount, 1);
    expect(noteRepo.getNotesForTripCallCount, 1);
  });

  test(
    'applyNoteUpserted keeps the all-trip notes count in sync for wrap-up '
    'eligibility (#103)',
    () async {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      // Trip has already ended, with enough photos but only one note-day —
      // starts locked.
      final tripRepo = FakeTripRepository()
        ..tripCardResult = Right(
          buildTripCard(
            id: 't1',
            startDate: todayDate.subtract(const Duration(days: 2)),
            endDate: todayDate.subtract(const Duration(days: 1)),
          ),
        );
      final photoRepo = FakePhotoRepository()
        ..photosResult = Right([
          buildPhotoEntity(id: 'p1'),
          buildPhotoEntity(id: 'p2'),
          buildPhotoEntity(id: 'p3'),
        ]);
      final noteRepo = FakeDayNoteRepository()
        ..notesForTripResult = Right([
          buildDayNoteEntity(
            id: 'n1',
            dayDate: todayDate.subtract(const Duration(days: 2)),
          ),
        ]);
      final container = _buildContainer(
        tripRepo: tripRepo,
        photoRepo: photoRepo,
        noteRepo: noteRepo,
      );
      addTearDown(container.dispose);
      container.listen(journalControllerProvider('t1'), (_, _) {});

      await container.read(journalControllerProvider('t1').future);
      final notifier = container.read(journalControllerProvider('t1').notifier);

      var state = container.read(journalControllerProvider('t1')).value!;
      expect(state.wrapUpAvailability, WrapUpAvailability.locked);

      // Saving a second day's note — as if it happened before the trip
      // ended — should unlock wrap-up without needing a full reload.
      notifier.applyNoteUpserted(
        todayDate.subtract(const Duration(days: 1)),
        buildDayNoteEntity(
          id: 'n2',
          dayDate: todayDate.subtract(const Duration(days: 1)),
        ),
      );

      state = container.read(journalControllerProvider('t1')).value!;
      expect(state.notes, hasLength(2));
      expect(state.wrapUpAvailability, WrapUpAvailability.unlocked);
    },
  );

  test('selectDay switches the day and lazily fetches its note', () async {
    // A wide range so "today" (the initial day) lands strictly between
    // start and end — keeps this test's manual selectDay calls (to start
    // and to end) independent of the initial fetch build() already did.
    final today = DateTime.now();
    final start = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 10));
    final end = DateTime(
      today.year,
      today.month,
      today.day,
    ).add(const Duration(days: 10));
    final tripRepo = FakeTripRepository()
      ..tripCardResult = Right(
        buildTripCard(id: 't1', startDate: start, endDate: end),
      );
    final photoRepo = FakePhotoRepository();
    final noteRepo = FakeDayNoteRepository();
    final container = _buildContainer(
      tripRepo: tripRepo,
      photoRepo: photoRepo,
      noteRepo: noteRepo,
    );
    addTearDown(container.dispose);
    container.listen(journalControllerProvider('t1'), (_, _) {});

    await container.read(journalControllerProvider('t1').future);
    final notifier = container.read(journalControllerProvider('t1').notifier);
    final callsBeforeSwitch = noteRepo.getNoteCallCount;

    noteRepo.getNoteResult = Right(buildDayNoteEntity(content: 'Day two.'));
    await notifier.selectDay(end);

    final state = container.read(journalControllerProvider('t1')).value!;
    expect(state.currentDayDate, end);
    expect(state.currentNote?.content, 'Day two.');
    expect(noteRepo.getNoteCallCount, callsBeforeSwitch + 1);

    // Switching back to the already-cached end day doesn't refetch.
    await notifier.selectDay(end);
    expect(noteRepo.getNoteCallCount, callsBeforeSwitch + 1);
  });

  test('applyNoteUpserted updates the cached note for that day', () async {
    final start = DateTime(2026, 8, 18);
    final tripRepo = FakeTripRepository()
      ..tripCardResult = Right(
        buildTripCard(id: 't1', startDate: start, endDate: start),
      );
    final photoRepo = FakePhotoRepository();
    final noteRepo = FakeDayNoteRepository();
    final container = _buildContainer(
      tripRepo: tripRepo,
      photoRepo: photoRepo,
      noteRepo: noteRepo,
    );
    addTearDown(container.dispose);
    container.listen(journalControllerProvider('t1'), (_, _) {});

    await container.read(journalControllerProvider('t1').future);
    final notifier = container.read(journalControllerProvider('t1').notifier);

    final note = buildDayNoteEntity(dayDate: start, content: 'Updated.');
    notifier.applyNoteUpserted(start, note);

    final state = container.read(journalControllerProvider('t1')).value!;
    expect(state.currentNote?.content, 'Updated.');
  });
}
