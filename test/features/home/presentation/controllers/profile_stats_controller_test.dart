import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/core/events/global_event.dart';
import 'package:traviato/core/events/global_event_bus.dart';
import 'package:traviato/features/home/domain/entities/profile_stats_entity.dart';
import 'package:traviato/features/home/presentation/controllers/profile_stats_controller.dart';
import 'package:traviato/features/home/presentation/providers/profile_stats_provider.dart';

import '../../fakes/fake_profile_stats_repository.dart';

ProviderContainer _buildContainer(FakeProfileStatsRepository repo) {
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [profileStatsRepositoryProvider.overrideWithValue(repo)],
  );
  return container;
}

void main() {
  test('fetches stats from the repository on build', () async {
    final repo = FakeProfileStatsRepository()
      ..statsResult = const Right(
        ProfileStatsEntity(memories: 1, places: 2, days: 3, stars: 4),
      );
    final container = _buildContainer(repo);
    addTearDown(container.dispose);

    final stats = await container.read(
      profileStatsControllerProvider.future,
    );

    expect(stats.stars, 4);
    expect(repo.getStatsCallCount, 1);
  });

  test('refetches when StarsAwardedDispatched arrives on the bus', () async {
    final repo = FakeProfileStatsRepository()
      ..statsResult = const Right(
        ProfileStatsEntity(
          memories: 0,
          places: 0,
          days: 0,
          stars: 4,
        ),
      );
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [profileStatsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await container.read(profileStatsControllerProvider.future);
    expect(repo.getStatsCallCount, 1);

    repo.statsResult = const Right(
      ProfileStatsEntity(memories: 0, places: 0, days: 0, stars: 9),
    );
    container.read(globalEventBusProvider).add(const StarsAwardedDispatched());
    await Future<void>.delayed(Duration.zero);

    final updated = await container.read(
      profileStatsControllerProvider.future,
    );
    expect(updated.stars, 9);
    expect(repo.getStatsCallCount, 2);
  });

  test('propagates a repository failure', () async {
    final repo = FakeProfileStatsRepository()
      ..statsResult = const Left(NetworkFailure());
    final container = _buildContainer(repo);
    addTearDown(container.dispose);

    await expectLater(
      container.read(profileStatsControllerProvider.future),
      throwsA(anything),
    );
  });
}
