import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/features/journal/presentation/controllers/journal_controller.dart';
import 'package:traviato/features/journal/presentation/controllers/journal_state.dart';
import 'package:traviato/features/journal/presentation/providers/journal_note_providers.dart';
import 'package:traviato/features/photo/presentation/providers/photo_providers.dart';
import 'package:traviato/features/quest/presentation/providers/quest_providers.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';

import '../../../photo/fakes/fake_photo_repository.dart';
import '../../../quest/fakes/fake_quest_repository.dart';
import '../../../trip/fakes/fake_trip_repository.dart';
import '../../fakes/fake_journal_note_repository.dart';

ProviderContainer _buildContainer({
  required FakeTripRepository tripRepo,
  required FakePhotoRepository photoRepo,
  required FakeJournalNoteRepository noteRepo,
  FakeQuestRepository? questRepo,
}) {
  return ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      tripRepositoryProvider.overrideWithValue(tripRepo),
      photoRepositoryProvider.overrideWithValue(photoRepo),
      journalNoteRepositoryProvider.overrideWithValue(noteRepo),
      questRepositoryProvider.overrideWithValue(
        questRepo ?? FakeQuestRepository(),
      ),
    ],
  );
}

void main() {
  test("loads the trip, photos and the whole trip's notes", () async {
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
    final todayDate = DateTime(today.year, today.month, today.day);
    final noteRepo = FakeJournalNoteRepository()
      ..notesForTripResult = Right([
        buildJournalNoteEntity(
          id: 'n2',
          dayDate: todayDate,
          content: 'Later.',
          createdAt: todayDate.add(const Duration(hours: 9)),
        ),
        buildJournalNoteEntity(
          dayDate: todayDate,
          content: 'Great day.',
          createdAt: todayDate.add(const Duration(hours: 8)),
        ),
      ]);
    final container = _buildContainer(
      tripRepo: tripRepo,
      photoRepo: photoRepo,
      noteRepo: noteRepo,
    );
    addTearDown(container.dispose);

    final state = await container.read(journalControllerProvider('t1').future);

    expect(state.photos, hasLength(1));
    expect(state.notesForCurrentDay.map((n) => n.content), [
      'Great day.',
      'Later.',
    ]);
    expect(noteRepo.getNoteCallCount, 0);
    expect(noteRepo.getNotesForTripCallCount, 1);
  });

  test('a finished memory opens on Day 1, not the last day (#163)', () async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final start = todayDate.subtract(const Duration(days: 10));
    final tripRepo = FakeTripRepository()
      ..tripCardResult = Right(
        buildTripCard(
          id: 't1',
          startDate: start,
          endDate: todayDate.subtract(const Duration(days: 6)),
        ),
      );
    final container = _buildContainer(
      tripRepo: tripRepo,
      photoRepo: FakePhotoRepository(),
      noteRepo: FakeJournalNoteRepository(),
    );
    addTearDown(container.dispose);

    final state = await container.read(journalControllerProvider('t1').future);

    expect(state.currentDayDate, start);
  });

  test(
    'applyNoteSaved keeps the all-trip notes count in sync for wrap-up '
    'eligibility (#103/#140)',
    () async {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      // Trip has already ended, with enough photos (>= the 15-photo
      // wrapReady minimum, #432) but zero notes yet — starts locked on the
      // notes requirement alone.
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
          for (var i = 0; i < 15; i++) buildPhotoEntity(id: 'p$i'),
        ]);
      final noteRepo = FakeJournalNoteRepository();
      final container = _buildContainer(
        tripRepo: tripRepo,
        photoRepo: photoRepo,
        noteRepo: noteRepo,
      );
      addTearDown(container.dispose);
      container.listen(journalControllerProvider('t1'), (_, _) {});

      await container.read(journalControllerProvider('t1').future);
      final notifier = container.read(journalControllerProvider('t1').notifier);
      // A finished memory opens on Day 1 (#163); the wrap-up CTA lives on
      // the last day (#107).
      notifier.selectDay(todayDate.subtract(const Duration(days: 1)));

      var state = container.read(journalControllerProvider('t1')).value!;
      expect(state.wrapUpAvailability, WrapUpAvailability.locked);

      // Saving a note — as if it happened before the trip ended — should
      // unlock wrap-up without needing a full reload.
      notifier.applyNoteSaved(
        buildJournalNoteEntity(
          id: 'n1',
          dayDate: todayDate.subtract(const Duration(days: 1)),
        ),
      );

      state = container.read(journalControllerProvider('t1')).value!;
      expect(state.notes, hasLength(1));
      expect(state.wrapUpAvailability, WrapUpAvailability.unlocked);

      // Deleting it (#276) clears the day and locks wrap-up again.
      expect(notifier.applyNoteDeleted('n1')?.id, 'n1');
      state = container.read(journalControllerProvider('t1')).value!;
      expect(state.notes, isEmpty);
      expect(state.notesForCurrentDay, isEmpty);
      expect(state.wrapUpAvailability, WrapUpAvailability.locked);
    },
  );

  test('selectDay switches the day without fetching', () async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final start = todayDate.subtract(const Duration(days: 10));
    final end = todayDate.add(const Duration(days: 10));
    final tripRepo = FakeTripRepository()
      ..tripCardResult = Right(
        buildTripCard(id: 't1', startDate: start, endDate: end),
      );
    final noteRepo = FakeJournalNoteRepository()
      ..notesForTripResult = Right([
        buildJournalNoteEntity(dayDate: start, content: 'Day one.'),
      ]);
    final container = _buildContainer(
      tripRepo: tripRepo,
      photoRepo: FakePhotoRepository(),
      noteRepo: noteRepo,
    );
    addTearDown(container.dispose);
    container.listen(journalControllerProvider('t1'), (_, _) {});

    await container.read(journalControllerProvider('t1').future);
    container.read(journalControllerProvider('t1').notifier).selectDay(start);

    final state = container.read(journalControllerProvider('t1')).value!;
    expect(state.currentDayDate, start);
    expect(state.notesForCurrentDay.single.content, 'Day one.');
    expect(noteRepo.getNotesForTripCallCount, 1);
  });

  test('opens on the evening before after midnight (#397)', () async {
    // Built around the real clock: the evening before `now` has a photo
    // 30 min ago only if that's before midnight — so check the rule by its
    // own helper instead of a wall-clock assertion.
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final yesterday = todayDate.subtract(const Duration(days: 1));
    final tripRepo = FakeTripRepository()
      ..tripCardResult = Right(
        buildTripCard(
          id: 't1',
          startDate: yesterday,
          endDate: todayDate.add(const Duration(days: 1)),
        ),
      );
    final recent = now.subtract(const Duration(minutes: 30));
    final noteRepo = FakeJournalNoteRepository()
      ..notesForTripResult = Right([
        buildJournalNoteEntity(dayDate: yesterday, createdAt: recent),
      ]);
    final container = _buildContainer(
      tripRepo: tripRepo,
      photoRepo: FakePhotoRepository(),
      noteRepo: noteRepo,
    );
    addTearDown(container.dispose);

    final state = await container.read(journalControllerProvider('t1').future);

    final expected = now.hour < 8 ? yesterday : todayDate;
    expect(state.currentDayDate, expected);
  });

  test('selectDay ignores a future day — locked per #118', () async {
    final today = DateTime.now();
    final start = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 1));
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
    final noteRepo = FakeJournalNoteRepository();
    final container = _buildContainer(
      tripRepo: tripRepo,
      photoRepo: photoRepo,
      noteRepo: noteRepo,
    );
    addTearDown(container.dispose);
    container.listen(journalControllerProvider('t1'), (_, _) {});

    final initial = await container.read(
      journalControllerProvider('t1').future,
    );
    container.read(journalControllerProvider('t1').notifier).selectDay(end);

    final state = container.read(journalControllerProvider('t1')).value!;
    expect(state.currentDayDate, initial.currentDayDate);
  });

  test('applyNoteSaved adds a new note and replaces an edited one', () async {
    final start = DateTime(2026, 8, 18);
    final tripRepo = FakeTripRepository()
      ..tripCardResult = Right(
        buildTripCard(id: 't1', startDate: start, endDate: start),
      );
    final photoRepo = FakePhotoRepository();
    final noteRepo = FakeJournalNoteRepository();
    final container = _buildContainer(
      tripRepo: tripRepo,
      photoRepo: photoRepo,
      noteRepo: noteRepo,
    );
    addTearDown(container.dispose);
    container.listen(journalControllerProvider('t1'), (_, _) {});

    await container.read(journalControllerProvider('t1').future);
    final notifier = container.read(journalControllerProvider('t1').notifier);

    notifier
      ..applyNoteSaved(buildJournalNoteEntity(dayDate: start, content: 'A.'))
      ..applyNoteSaved(
        buildJournalNoteEntity(id: 'n2', dayDate: start, content: 'B.'),
      )
      ..applyNoteSaved(
        buildJournalNoteEntity(dayDate: start, content: 'A, edited.'),
      );

    final state = container.read(journalControllerProvider('t1')).value!;
    expect(state.notesForDay(start).map((n) => n.content).toSet(), {
      'A, edited.',
      'B.',
    });
  });

  group('photo delete/restore (#165)', () {
    Future<ProviderContainer> loaded() async {
      final today = DateTime.now();
      final container = _buildContainer(
        tripRepo: FakeTripRepository()
          ..tripCardResult = Right(
            buildTripCard(
              id: 't1',
              startDate: today.subtract(const Duration(days: 1)),
              endDate: today.add(const Duration(days: 1)),
            ),
          ),
        photoRepo: FakePhotoRepository()
          ..photosResult = Right([
            buildPhotoEntity(id: 'p1'),
            buildPhotoEntity(id: 'p2'),
            buildPhotoEntity(id: 'p3'),
          ]),
        noteRepo: FakeJournalNoteRepository(),
      );
      await container.read(journalControllerProvider('t1').future);
      return container;
    }

    List<String> ids(ProviderContainer c) => [
      for (final p in c.read(journalControllerProvider('t1')).value!.photos)
        p.id,
    ];

    test('applyPhotoDeleted drops the photo and returns its index', () async {
      final container = await loaded();
      addTearDown(container.dispose);
      final controller = container.read(
        journalControllerProvider('t1').notifier,
      );

      expect(controller.applyPhotoDeleted('p2'), 1);
      expect(ids(container), ['p1', 'p3']);
      expect(controller.applyPhotoDeleted('missing'), -1);
    });

    test('applyPhotoRestored puts it back where it was', () async {
      final container = await loaded();
      addTearDown(container.dispose);
      final controller = container.read(
        journalControllerProvider('t1').notifier,
      );

      final index = controller.applyPhotoDeleted('p2');
      controller.applyPhotoRestored(buildPhotoEntity(id: 'p2'), index);

      expect(ids(container), ['p1', 'p2', 'p3']);
    });
  });
}
