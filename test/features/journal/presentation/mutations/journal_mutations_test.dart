import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/core/events/global_event.dart';
import 'package:traviato/core/events/global_event_bus.dart';
import 'package:traviato/features/journal/presentation/controllers/journal_controller.dart';
import 'package:traviato/features/journal/presentation/mutations/journal_mutations.dart';
import 'package:traviato/features/journal/presentation/providers/journal_note_providers.dart';
import 'package:traviato/features/photo/presentation/providers/photo_providers.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';

import '../../../photo/fakes/fake_photo_repository.dart';
import '../../../trip/fakes/fake_trip_repository.dart';
import '../../fakes/fake_journal_note_repository.dart';

const _tripId = 't1';

class _Harness extends ConsumerWidget {
  const _Harness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(journalControllerProvider(_tripId));
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                try {
                  await runCreateNote(
                    ref: ref,
                    tripId: _tripId,
                    dayDate: DateTime(2026, 8, 18),
                    takenAt: DateTime(2026, 8, 19, 1, 10),
                    content: 'Great day.',
                    dictated: true,
                  );
                } catch (_) {}
              },
              child: const Text('Save'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await runUpdateNote(
                    ref: ref,
                    tripId: _tripId,
                    noteId: 'n1',
                    content: 'Better day.',
                    dictated: false,
                  );
                } catch (_) {}
              },
              child: const Text('Edit'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await runDeleteNote(
                    ref: ref,
                    tripId: _tripId,
                    noteId: 'n1',
                  );
                } catch (_) {}
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  testWidgets('saving a note fires StarsAwardedDispatched', (tester) async {
    final bus = GlobalEventBus();
    addTearDown(bus.dispose);
    final events = <GlobalEvent>[];
    final sub = bus.stream.listen(events.add);
    addTearDown(sub.cancel);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tripRepositoryProvider.overrideWithValue(FakeTripRepository()),
          photoRepositoryProvider.overrideWithValue(FakePhotoRepository()),
          journalNoteRepositoryProvider.overrideWithValue(
            FakeJournalNoteRepository(),
          ),
          globalEventBusProvider.overrideWithValue(bus),
        ],
        child: const _Harness(),
      ),
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(events, hasLength(1));
    expect(events.single, isA<StarsAwardedDispatched>());
  });

  Future<List<GlobalEvent>> pumpAndTap(
    WidgetTester tester,
    String button,
    FakeJournalNoteRepository noteRepo,
  ) async {
    final bus = GlobalEventBus();
    addTearDown(bus.dispose);
    final events = <GlobalEvent>[];
    final sub = bus.stream.listen(events.add);
    addTearDown(sub.cancel);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tripRepositoryProvider.overrideWithValue(FakeTripRepository()),
          photoRepositoryProvider.overrideWithValue(FakePhotoRepository()),
          journalNoteRepositoryProvider.overrideWithValue(noteRepo),
          globalEventBusProvider.overrideWithValue(bus),
        ],
        child: const _Harness(),
      ),
    );
    await tester.tap(find.text(button));
    await tester.pumpAndSettle();
    return events;
  }

  testWidgets('a new note keeps the time, day and dictated flag given', (
    tester,
  ) async {
    final noteRepo = FakeJournalNoteRepository();
    await pumpAndTap(tester, 'Save', noteRepo);

    expect(noteRepo.createNoteCallCount, 1);
    expect(noteRepo.updateNoteCallCount, 0);
    // 01:10 the next morning, still on the evening's day (#397).
    expect(noteRepo.lastCreatedTakenAt, DateTime(2026, 8, 19, 1, 10));
    expect(noteRepo.lastCreatedDay, DateTime(2026, 8, 18));
    expect(noteRepo.lastCreatedDictated, isTrue);
  });

  testWidgets('editing a note updates it and fires nothing (#397)', (
    tester,
  ) async {
    final noteRepo = FakeJournalNoteRepository();
    final events = await pumpAndTap(tester, 'Edit', noteRepo);

    expect(noteRepo.createNoteCallCount, 0);
    expect(noteRepo.lastUpdatedNoteId, 'n1');
    expect(noteRepo.lastUpsertedContent, 'Better day.');
    expect(events, isEmpty);
  });

  testWidgets('deleting a note keeps its star: no stars event (#397)', (
    tester,
  ) async {
    final noteRepo = FakeJournalNoteRepository();
    final events = await pumpAndTap(tester, 'Delete', noteRepo);

    expect(noteRepo.lastDeletedNoteId, 'n1');
    expect(events, isEmpty);
  });

  testWidgets('a failed delete fires nothing', (tester) async {
    final noteRepo = FakeJournalNoteRepository()
      ..deleteNoteResult = const Left(NetworkFailure());
    final events = await pumpAndTap(tester, 'Delete', noteRepo);

    expect(noteRepo.deleteNoteCallCount, 1);
    expect(events, isEmpty);
  });
}
