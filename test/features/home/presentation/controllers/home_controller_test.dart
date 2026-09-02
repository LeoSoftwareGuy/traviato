import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/core/events/global_event.dart';
import 'package:traviato/core/events/global_event_bus.dart';
import 'package:traviato/features/home/presentation/controllers/home_controller.dart';
import 'package:traviato/features/home/presentation/controllers/home_state.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';

import '../../../trip/fakes/fake_trip_repository.dart';

void main() {
  test('loads trips from the repository', () async {
    final fakeRepo = FakeTripRepository()
      ..tripsResult = Right([buildTripCard(id: 't1')]);
    final container = ProviderContainer(
      overrides: [tripRepositoryProvider.overrideWithValue(fakeRepo)],
    );
    addTearDown(container.dispose);

    final state = await container.read(homeControllerProvider.future);
    expect(state.trips, hasLength(1));
    expect(fakeRepo.callCount, 1);
  });

  test('surfaces a repository failure as an AsyncError', () async {
    final fakeRepo = FakeTripRepository()
      ..tripsResult = const Left(NetworkFailure());
    final container = ProviderContainer(
      // Matches the app's runApp(ProviderScope(retry: ...)) — without this,
      // a bare ProviderContainer retries the failing build indefinitely
      // instead of settling into AsyncError (guidelines doc 02).
      retry: (_, _) => null,
      overrides: [tripRepositoryProvider.overrideWithValue(fakeRepo)],
    );
    addTearDown(container.dispose);

    AsyncValue<HomeState>? latest;
    container.listen(
      homeControllerProvider,
      (_, next) => latest = next,
      fireImmediately: true,
    );
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(latest, isA<AsyncError<HomeState>>());
    expect((latest! as AsyncError<HomeState>).error, isA<Exception>());
  });

  test('prepends a trip created elsewhere via the event bus', () async {
    final fakeRepo = FakeTripRepository()..tripsResult = const Right([]);
    final bus = GlobalEventBus();
    addTearDown(bus.dispose);
    final container = ProviderContainer(
      overrides: [
        tripRepositoryProvider.overrideWithValue(fakeRepo),
        globalEventBusProvider.overrideWithValue(bus),
      ],
    );
    addTearDown(container.dispose);
    container.listen(homeControllerProvider, (_, _) {});

    await container.read(homeControllerProvider.future);

    final newTrip = buildTripCard(id: 'new-trip');
    bus.add(TripCreatedDispatched(trip: newTrip));
    await Future<void>.delayed(Duration.zero);

    final state = container.read(homeControllerProvider).value;
    expect(state?.trips.map((t) => t.id), ['new-trip']);
  });

  test(
    'ignores a duplicate TripCreatedDispatched for an id already held',
    () async {
      final existing = buildTripCard(id: 't1');
      final fakeRepo = FakeTripRepository()..tripsResult = Right([existing]);
      final bus = GlobalEventBus();
      addTearDown(bus.dispose);
      final container = ProviderContainer(
        overrides: [
          tripRepositoryProvider.overrideWithValue(fakeRepo),
          globalEventBusProvider.overrideWithValue(bus),
        ],
      );
      addTearDown(container.dispose);
      container.listen(homeControllerProvider, (_, _) {});

      await container.read(homeControllerProvider.future);

      bus.add(TripCreatedDispatched(trip: existing));
      await Future<void>.delayed(Duration.zero);

      final state = container.read(homeControllerProvider).value;
      expect(state?.trips, hasLength(1));
    },
  );

  test('replaces a trip renamed elsewhere via the event bus', () async {
    final existing = buildTripCard(id: 't1', name: 'Old name');
    final fakeRepo = FakeTripRepository()..tripsResult = Right([existing]);
    final bus = GlobalEventBus();
    addTearDown(bus.dispose);
    final container = ProviderContainer(
      overrides: [
        tripRepositoryProvider.overrideWithValue(fakeRepo),
        globalEventBusProvider.overrideWithValue(bus),
      ],
    );
    addTearDown(container.dispose);
    container.listen(homeControllerProvider, (_, _) {});

    await container.read(homeControllerProvider.future);

    final renamed = buildTripCard(id: 't1', name: 'New name');
    bus.add(TripUpdatedDispatched(trip: renamed));
    await Future<void>.delayed(Duration.zero);

    final state = container.read(homeControllerProvider).value;
    expect(state?.trips.single.name, 'New name');
  });

  test(
    'marks a trip kept-forever when its wrap-up is published elsewhere',
    () async {
      final existing = buildTripCard(id: 't1');
      final fakeRepo = FakeTripRepository()..tripsResult = Right([existing]);
      final bus = GlobalEventBus();
      addTearDown(bus.dispose);
      final container = ProviderContainer(
        overrides: [
          tripRepositoryProvider.overrideWithValue(fakeRepo),
          globalEventBusProvider.overrideWithValue(bus),
        ],
      );
      addTearDown(container.dispose);
      container.listen(homeControllerProvider, (_, _) {});

      await container.read(homeControllerProvider.future);
      expect(existing.isKeptForever, isFalse);

      final publishedAt = DateTime(2026, 2, 1);
      bus.add(
        WrapUpPublishedDispatched(tripId: 't1', publishedAt: publishedAt),
      );
      await Future<void>.delayed(Duration.zero);

      final state = container.read(homeControllerProvider).value;
      final trip = state?.trips.single;
      expect(trip?.isKeptForever, isTrue);
      expect(trip?.wrapUpPublishedAt, publishedAt);
    },
  );

  test('removes a trip deleted elsewhere via the event bus', () async {
    final existing = buildTripCard(id: 't1');
    final fakeRepo = FakeTripRepository()..tripsResult = Right([existing]);
    final bus = GlobalEventBus();
    addTearDown(bus.dispose);
    final container = ProviderContainer(
      overrides: [
        tripRepositoryProvider.overrideWithValue(fakeRepo),
        globalEventBusProvider.overrideWithValue(bus),
      ],
    );
    addTearDown(container.dispose);
    container.listen(homeControllerProvider, (_, _) {});

    await container.read(homeControllerProvider.future);

    bus.add(const TripDeletedDispatched(tripId: 't1'));
    await Future<void>.delayed(Duration.zero);

    final state = container.read(homeControllerProvider).value;
    expect(state?.trips, isEmpty);
  });
}
