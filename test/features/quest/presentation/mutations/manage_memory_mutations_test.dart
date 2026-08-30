import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/events/global_event.dart';
import 'package:traviato/core/events/global_event_bus.dart';
import 'package:traviato/features/quest/presentation/controllers/plan_controller.dart';
import 'package:traviato/features/quest/presentation/mutations/manage_memory_mutations.dart';
import 'package:traviato/features/quest/presentation/providers/quest_providers.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';

import '../../../trip/fakes/fake_trip_repository.dart';
import '../../fakes/fake_quest_repository.dart';

// Mutation.run needs a WidgetRef, so these are exercised through a minimal
// widget harness rather than a bare ProviderContainer — matches
// trip_mutations_test.dart's pattern.
class _Harness extends ConsumerWidget {
  const _Harness({required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keeps planControllerProvider(tripId) alive and loaded for the
    // duration of the test, same as the real Plan screen would.
    ref.watch(planControllerProvider(tripId));
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                try {
                  await runRenameMemory(
                    ref: ref,
                    tripId: tripId,
                    name: 'New name',
                  );
                } catch (_) {
                  // Surfaced via the mutation's MutationError state instead.
                }
              },
              child: const Text('Rename'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await runShiftMemoryDates(
                    ref: ref,
                    tripId: tripId,
                    deltaDays: 1,
                  );
                } catch (_) {
                  // Surfaced via the mutation's MutationError state instead.
                }
              },
              child: const Text('Shift'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await runChangeCover(
                    ref: ref,
                    tripId: tripId,
                    coverImagePath: 'asset:hero',
                  );
                } catch (_) {
                  // Surfaced via the mutation's MutationError state instead.
                }
              },
              child: const Text('Cover'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await runUploadCover(
                    ref: ref,
                    tripId: tripId,
                    bytes: Uint8List.fromList([1, 2, 3]),
                  );
                } catch (_) {
                  // Surfaced via the mutation's MutationError state instead.
                }
              },
              child: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<ProviderContainer> _pumpHarness(
  WidgetTester tester, {
  required FakeTripRepository tripRepo,
  required FakeQuestRepository questRepo,
  required String tripId,
  GlobalEventBus? bus,
}) async {
  late final ProviderContainer container;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tripRepositoryProvider.overrideWithValue(tripRepo),
        questRepositoryProvider.overrideWithValue(questRepo),
        if (bus != null) globalEventBusProvider.overrideWithValue(bus),
      ],
      child: Builder(
        builder: (context) {
          container = ProviderScope.containerOf(context);
          return _Harness(tripId: tripId);
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets(
    'runRenameMemory updates the plan state and fires TripUpdatedDispatched',
    (tester) async {
      final tripRepo = FakeTripRepository()
        ..tripCardResult = Right(buildTripCard(id: 't1', name: 'Old name'))
        ..updateTripResult = Right(
          buildTripEntity(id: 't1', name: 'New name'),
        );
      final questRepo = FakeQuestRepository();
      final bus = GlobalEventBus();
      addTearDown(bus.dispose);
      final events = <GlobalEvent>[];
      final sub = bus.stream.listen(events.add);
      addTearDown(sub.cancel);

      final container = await _pumpHarness(
        tester,
        tripRepo: tripRepo,
        questRepo: questRepo,
        tripId: 't1',
        bus: bus,
      );

      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      expect(tripRepo.updateTripCallCount, 1);
      expect(tripRepo.lastUpdateName, 'New name');
      expect(
        container.read(planControllerProvider('t1')).value?.trip.name,
        'New name',
      );
      expect(events, hasLength(1));
      expect(events.single, isA<TripUpdatedDispatched>());
    },
  );

  testWidgets('runShiftMemoryDates moves the trip and every quest together', (
    tester,
  ) async {
    final tripRepo = FakeTripRepository()
      ..tripCardResult = Right(
        buildTripCard(
          id: 't1',
          startDate: DateTime(2026, 8, 18),
          endDate: DateTime(2026, 8, 19),
        ),
      )
      ..shiftTripDatesResult = Right(
        buildTripEntity(
          id: 't1',
          startDate: DateTime(2026, 8, 19),
          endDate: DateTime(2026, 8, 20),
        ),
      );
    final quest = buildQuestEntity(id: 'q1', dayDate: DateTime(2026, 8, 18));
    final questRepo = FakeQuestRepository()..questsResult = Right([quest]);

    final container = await _pumpHarness(
      tester,
      tripRepo: tripRepo,
      questRepo: questRepo,
      tripId: 't1',
    );

    await tester.tap(find.text('Shift'));
    await tester.pumpAndSettle();

    expect(tripRepo.shiftTripDatesCallCount, 1);
    expect(tripRepo.lastShiftDeltaDays, 1);
    final state = container.read(planControllerProvider('t1')).value!;
    expect(state.trip.startDate, DateTime(2026, 8, 19));
    expect(state.trip.endDate, DateTime(2026, 8, 20));
    expect(state.quests.single.dayDate, DateTime(2026, 8, 19));
  });

  testWidgets('runChangeCover updates the plan state', (tester) async {
    final tripRepo = FakeTripRepository()
      ..tripCardResult = Right(buildTripCard(id: 't1'))
      ..updateTripResult = Right(
        buildTripEntity(id: 't1', coverImagePath: 'asset:hero'),
      );
    final questRepo = FakeQuestRepository();

    final container = await _pumpHarness(
      tester,
      tripRepo: tripRepo,
      questRepo: questRepo,
      tripId: 't1',
    );

    await tester.tap(find.text('Cover'));
    await tester.pumpAndSettle();

    expect(tripRepo.lastUpdateCoverImagePath, 'asset:hero');
    expect(
      container.read(planControllerProvider('t1')).value?.trip.coverImagePath,
      'asset:hero',
    );
  });

  testWidgets(
    'runChangeCover deletes a previous custom cover when switching to a '
    'bundled one',
    (tester) async {
      final tripRepo = FakeTripRepository()
        ..tripCardResult = Right(
          buildTripCard(id: 't1', coverImagePath: 'u1/t1/cover.jpg'),
        )
        ..updateTripResult = Right(
          buildTripEntity(id: 't1', coverImagePath: 'asset:hero'),
        );
      final questRepo = FakeQuestRepository();

      await _pumpHarness(
        tester,
        tripRepo: tripRepo,
        questRepo: questRepo,
        tripId: 't1',
      );

      await tester.tap(find.text('Cover'));
      await tester.pumpAndSettle();

      expect(tripRepo.deleteCoverImageCallCount, 1);
      expect(tripRepo.lastDeleteCoverTripId, 't1');
    },
  );

  testWidgets(
    'runChangeCover does not delete anything when switching between two '
    'bundled covers',
    (tester) async {
      final tripRepo = FakeTripRepository()
        ..tripCardResult = Right(
          buildTripCard(id: 't1', coverImagePath: 'asset:solo_getaway'),
        )
        ..updateTripResult = Right(
          buildTripEntity(id: 't1', coverImagePath: 'asset:hero'),
        );
      final questRepo = FakeQuestRepository();

      await _pumpHarness(
        tester,
        tripRepo: tripRepo,
        questRepo: questRepo,
        tripId: 't1',
      );

      await tester.tap(find.text('Cover'));
      await tester.pumpAndSettle();

      expect(tripRepo.deleteCoverImageCallCount, 0);
    },
  );

  testWidgets('runUploadCover uploads bytes and updates the cover path', (
    tester,
  ) async {
    final tripRepo = FakeTripRepository()
      ..tripCardResult = Right(buildTripCard(id: 't1'))
      ..uploadCoverImageResult = const Right('u1/t1/cover.jpg')
      ..updateTripResult = Right(
        buildTripEntity(id: 't1', coverImagePath: 'u1/t1/cover.jpg'),
      );
    final questRepo = FakeQuestRepository();

    final container = await _pumpHarness(
      tester,
      tripRepo: tripRepo,
      questRepo: questRepo,
      tripId: 't1',
    );

    await tester.tap(find.text('Upload'));
    await tester.pumpAndSettle();

    expect(tripRepo.uploadCoverImageCallCount, 1);
    expect(tripRepo.lastUploadCoverTripId, 't1');
    expect(tripRepo.lastUpdateCoverImagePath, 'u1/t1/cover.jpg');
    expect(
      container.read(planControllerProvider('t1')).value?.trip.coverImagePath,
      'u1/t1/cover.jpg',
    );
  });
}
