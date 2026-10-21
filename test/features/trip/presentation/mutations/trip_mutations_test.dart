import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/core/errors/presentation_failure_exception.dart';
import 'package:traviato/core/events/global_event.dart';
import 'package:traviato/core/events/global_event_bus.dart';
import 'package:traviato/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:traviato/features/trip/domain/entities/trip_card_entity.dart';
import 'package:traviato/features/trip/presentation/mutations/trip_mutations.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';

import '../../../subscription/fakes/fake_subscription_repository.dart';
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
              await runCreateMemory(
                ref: ref,
                name: 'Summer in Tokyo',
                startDate: DateTime(2026, 7, 1),
                endDate: DateTime(2026, 7, 7),
              );
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

class _CreateWithCoverHarness extends ConsumerWidget {
  const _CreateWithCoverHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      home: Scaffold(
        body: ElevatedButton(
          onPressed: () async {
            try {
              await runCreateMemory(
                ref: ref,
                name: 'Summer in Tokyo',
                startDate: DateTime(2026, 7, 1),
                endDate: DateTime(2026, 7, 7),
                coverImagePath: 'asset:hero',
                coverImageBytes: Uint8List.fromList([1, 2, 3]),
              );
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
  FakeSubscriptionRepository? subscriptionRepo,
}) async {
  late final ProviderContainer container;
  await tester.pumpWidget(
    ProviderScope(
      // Same as main.dart: no silent auto-retry, so a failed entitlement
      // load surfaces as an error instead of staying in loading.
      retry: (_, _) => null,
      overrides: [
        tripRepositoryProvider.overrideWithValue(tripRepo),
        subscriptionRepositoryProvider.overrideWithValue(
          subscriptionRepo ?? FakeSubscriptionRepository(),
        ),
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

  testWidgets('blocks a free user once the free-tier limit is reached', (
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

  group('memory limit for Pro users (#267)', () {
    List<TripCardEntity> threeTrips() => [
      buildTripCard(id: 't1'),
      buildTripCard(id: 't2'),
      buildTripCard(id: 't3'),
    ];

    testWidgets('a Pro user with 3 memories can create a 4th', (
      tester,
    ) async {
      final tripRepo = FakeTripRepository()..tripsResult = Right(threeTrips());
      final subscriptionRepo = FakeSubscriptionRepository()
        ..entitlementResult = Right(buildProEntitlement());

      final container = await _pumpHarness(
        tester,
        tripRepo,
        subscriptionRepo: subscriptionRepo,
      );
      container.listen(createMemoryMutation, (_, _) {});
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(tripRepo.createTripCallCount, 1);
      expect(
        container.read(createMemoryMutation),
        isA<MutationSuccess<TripCardEntity>>(),
      );
    });

    testWidgets(
      'an expired Pro entitlement is treated as free and blocked at 3',
      (tester) async {
        final tripRepo = FakeTripRepository()
          ..tripsResult = Right(threeTrips());
        final subscriptionRepo = FakeSubscriptionRepository()
          ..entitlementResult = Right(
            buildProEntitlement(
              expiresAt: DateTime.now().subtract(const Duration(minutes: 5)),
            ),
          );

        final container = await _pumpHarness(
          tester,
          tripRepo,
          subscriptionRepo: subscriptionRepo,
        );
        container.listen(createMemoryMutation, (_, _) {});
        await tester.tap(find.text('Create'));
        await tester.pumpAndSettle();

        expect(tripRepo.createTripCallCount, 0);
        expect(
          container.read(createMemoryMutation),
          isA<MutationError<TripCardEntity>>(),
        );
      },
    );

    testWidgets(
      'skips the pre-check when the entitlement fails to load and lets the '
      'server decide',
      (tester) async {
        final tripRepo = FakeTripRepository()
          ..tripsResult = Right(threeTrips());
        final subscriptionRepo = FakeSubscriptionRepository()
          ..entitlementResult = const Left(NetworkFailure());

        final container = await _pumpHarness(
          tester,
          tripRepo,
          subscriptionRepo: subscriptionRepo,
        );
        container.listen(createMemoryMutation, (_, _) {});
        await tester.tap(find.text('Create'));
        await tester.pumpAndSettle();

        expect(tripRepo.createTripCallCount, 1);
      },
    );

    testWidgets(
      'a server TRV01 for a stale row resyncs and retries once when the '
      'sync confirms Pro',
      (tester) async {
        final tripRepo = FakeTripRepository()
          ..tripsResult = const Right([])
          ..createTripResultQueue = [const Left(FreeTierLimitFailure())];
        final pro = buildProEntitlement();
        final subscriptionRepo = FakeSubscriptionRepository()
          ..refreshEntitlementResult = Right(pro);
        final bus = GlobalEventBus();
        addTearDown(bus.dispose);
        final events = <GlobalEvent>[];
        final sub = bus.stream.listen(events.add);
        addTearDown(sub.cancel);

        final container = await _pumpHarness(
          tester,
          tripRepo,
          bus: bus,
          subscriptionRepo: subscriptionRepo,
        );
        container.listen(createMemoryMutation, (_, _) {});
        await tester.tap(find.text('Create'));
        await tester.pumpAndSettle();

        expect(subscriptionRepo.refreshEntitlementCallCount, 1);
        expect(tripRepo.createTripCallCount, 2);
        expect(
          container.read(createMemoryMutation),
          isA<MutationSuccess<TripCardEntity>>(),
        );
        expect(
          events.whereType<EntitlementUpdatedDispatched>().single.entitlement,
          pro,
        );
      },
    );

    testWidgets(
      'a server TRV01 that the resync confirms as free shows the upsell '
      'without retrying',
      (tester) async {
        final tripRepo = FakeTripRepository()
          ..tripsResult = const Right([])
          ..createTripResultQueue = [const Left(FreeTierLimitFailure())];
        final subscriptionRepo = FakeSubscriptionRepository();

        final container = await _pumpHarness(
          tester,
          tripRepo,
          subscriptionRepo: subscriptionRepo,
        );
        container.listen(createMemoryMutation, (_, _) {});
        await tester.tap(find.text('Create'));
        await tester.pumpAndSettle();

        expect(subscriptionRepo.refreshEntitlementCallCount, 1);
        expect(tripRepo.createTripCallCount, 1);
        final state = container.read(createMemoryMutation);
        final error = (state as MutationError<TripCardEntity>).error;
        expect(
          (error as PresentationFailureException).failure,
          isA<FreeTierLimitFailure>(),
        );
      },
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

  testWidgets(
    'a custom cover upload overrides the bundled fallback on success',
    (tester) async {
      final tripRepo = FakeTripRepository()
        ..tripsResult = const Right([])
        ..uploadCoverImageResult = const Right('u1/t1/cover.jpg');

      await _pumpHarness(
        tester,
        tripRepo,
        harness: () => const _CreateWithCoverHarness(),
      );
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(tripRepo.createTripCallCount, 1);
      expect(tripRepo.uploadCoverImageCallCount, 1);
      expect(tripRepo.lastUpdateCoverImagePath, 'u1/t1/cover.jpg');
    },
  );

  testWidgets(
    'a failed cover upload still creates the trip, keeping the bundled '
    'fallback (quiet degrade — see issue #81)',
    (tester) async {
      final tripRepo = FakeTripRepository()
        ..tripsResult = const Right([])
        ..uploadCoverImageResult = const Left(NetworkFailure());
      final bus = GlobalEventBus();
      addTearDown(bus.dispose);
      final events = <GlobalEvent>[];
      final sub = bus.stream.listen(events.add);
      addTearDown(sub.cancel);

      await _pumpHarness(
        tester,
        tripRepo,
        bus: bus,
        harness: () => const _CreateWithCoverHarness(),
      );
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Created despite the upload failure — no error surfaced, and
      // updateTrip is never even called since there was no path to set.
      expect(tripRepo.createTripCallCount, 1);
      expect(tripRepo.uploadCoverImageCallCount, 1);
      expect(tripRepo.updateTripCallCount, 0);
      expect(events, hasLength(1));
      final dispatched = events.single as TripCreatedDispatched;
      expect(dispatched.trip.coverImagePath, 'asset:hero');
    },
  );
}
