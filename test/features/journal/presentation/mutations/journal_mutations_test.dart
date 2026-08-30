import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
        body: ElevatedButton(
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
}
