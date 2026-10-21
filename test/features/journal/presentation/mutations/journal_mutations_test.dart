import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/core/events/global_event.dart';
import 'package:traviato/core/events/global_event_bus.dart';
import 'package:traviato/features/journal/presentation/controllers/journal_controller.dart';
import 'package:traviato/features/journal/presentation/mutations/journal_mutations.dart';
import 'package:traviato/features/journal/presentation/providers/day_note_providers.dart';
import 'package:traviato/features/photo/presentation/providers/photo_providers.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';

import '../../../photo/fakes/fake_photo_repository.dart';
import '../../../trip/fakes/fake_trip_repository.dart';
import '../../fakes/fake_day_note_repository.dart';

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
                  await runUpsertNote(
                    ref: ref,
                    tripId: _tripId,
                    dayDate: DateTime(2026, 8, 18),
                    content: 'Great day.',
                  );
                } catch (_) {}
              },
              child: const Text('Save'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await runDeleteNote(
                    ref: ref,
                    tripId: _tripId,
                    dayDate: DateTime(2026, 8, 18),
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
          dayNoteRepositoryProvider.overrideWithValue(FakeDayNoteRepository()),
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
    FakeDayNoteRepository noteRepo,
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
          dayNoteRepositoryProvider.overrideWithValue(noteRepo),
          globalEventBusProvider.overrideWithValue(bus),
        ],
        child: const _Harness(),
      ),
    );
    await tester.tap(find.text(button));
    await tester.pumpAndSettle();
    return events;
  }

  testWidgets('deleting a note fires StarsAwardedDispatched (#276)', (
    tester,
  ) async {
    final noteRepo = FakeDayNoteRepository();
    final events = await pumpAndTap(tester, 'Delete', noteRepo);

    expect(noteRepo.lastDeletedNoteId, 'n1');
    expect(events.single, isA<StarsAwardedDispatched>());
  });

  testWidgets('a failed delete fires nothing', (tester) async {
    final noteRepo = FakeDayNoteRepository()
      ..deleteNoteResult = const Left(NetworkFailure());
    final events = await pumpAndTap(tester, 'Delete', noteRepo);

    expect(noteRepo.deleteNoteCallCount, 1);
    expect(events, isEmpty);
  });
}
