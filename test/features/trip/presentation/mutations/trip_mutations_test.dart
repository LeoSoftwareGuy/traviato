import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/core/errors/presentation_failure_exception.dart';
import 'package:traviato/core/events/global_event.dart';
import 'package:traviato/core/events/global_event_bus.dart';
import 'package:traviato/features/trip/domain/entities/trip_card_entity.dart';
import 'package:traviato/features/trip/presentation/mutations/trip_mutations.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';

import '../../../trip/fakes/fake_trip_repository.dart';

// Mutation.run needs a WidgetRef, so runCreateMemory is exercised through a
// minimal widget harness rather than a bare ProviderContainer.
class _Harness extends ConsumerWidget {
  const _Harness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      home: Scaffold(
        body: ElevatedButton(
          onPressed: () async {
            try {
              await runCreateMemory(ref: ref, name: 'Summer in Tokyo');
            } catch (_) {
              // Surfaced via the mutation's MutationError state instead.
            }
          },
          child: const Text('Create'),
        ),
      ),
    );
  }
}

class _DeleteHarness extends ConsumerWidget {
  const _DeleteHarness({required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      home: Scaffold(
        body: ElevatedButton(
          onPressed: () async {
            try {
              await runDeleteMemory(ref: ref, tripId: tripId);
            } catch (_) {
              // Surfaced via the mutation's MutationError state instead.
            }
          },
          child: const Text('Delete'),
        ),
      ),
    );
  }
}

Future<ProviderContainer> _pumpHarness(
  WidgetTester tester,
  FakeTripRepository tripRepo, {
  GlobalEventBus? bus,
  Widget Function()? harness,
}) async {
  late final ProviderContainer container;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tripRepositoryProvider.overrideWithValue(tripRepo),
        if (bus != null) globalEventBusProvider.overrideWithValue(bus),
      ],
      child: Builder(
        builder: (context) {
          container = ProviderScope.containerOf(context);
          return harness?.call() ?? const _Harness();
        },
      ),
    ),
  );
  return container;
}

void main() {
  testWidgets('creates a trip and fires TripCreatedDispatched', (
    tester,
  ) async {
    final tripRepo = FakeTripRepository()..tripsResult = const Right([]);
    final bus = GlobalEventBus();
    addTearDown(bus.dispose);
    final events = <GlobalEvent>[];
    final sub = bus.stream.listen(events.add);
    addTearDown(sub.cancel);

    await _pumpHarness(tester, tripRepo, bus: bus);
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(tripRepo.createTripCallCount, 1);
    expect(events, hasLength(1));
    expect(events.single, isA<TripCreatedDispatched>());
  });

  testWidgets('blocks creation once the free-tier limit is reached', (
    tester,
  ) async {
    final tripRepo = FakeTripRepository()
      ..tripsResult = Right([
        buildTripCard(id: 't1'),
        buildTripCard(id: 't2'),
        buildTripCard(id: 't3'),
      ]);

    final container = await _pumpHarness(tester, tripRepo);
    // Keep the mutation's state alive for the test, mirroring how the real
    // page's `ref.watch(createMemoryMutation)` keeps it alive in the app.
    container.listen(createMemoryMutation, (_, _) {});
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(tripRepo.createTripCallCount, 0);
    final state = container.read(createMemoryMutation);
    expect(state, isA<MutationError<TripCardEntity>>());
    final error = (state as MutationError<TripCardEntity>).error;
    expect(error, isA<PresentationFailureException>());
    expect(
      (error as PresentationFailureException).failure,
      isA<FreeTierLimitFailure>(),
    );
  });

  testWidgets('deletes a trip and fires TripDeletedDispatched', (
    tester,
  ) async {
    final tripRepo = FakeTripRepository();
    final bus = GlobalEventBus();
    addTearDown(bus.dispose);
    final events = <GlobalEvent>[];
    final sub = bus.stream.listen(events.add);
    addTearDown(sub.cancel);

    await _pumpHarness(
      tester,
      tripRepo,
      bus: bus,
      harness: () => const _DeleteHarness(tripId: 't1'),
    );
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(tripRepo.deleteTripCallCount, 1);
    expect(tripRepo.lastDeletedTripId, 't1');
    expect(events, hasLength(1));
    expect(events.single, isA<TripDeletedDispatched>());
    expect((events.single as TripDeletedDispatched).tripId, 't1');
  });
}
