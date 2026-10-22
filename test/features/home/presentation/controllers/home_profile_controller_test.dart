import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/core/events/global_event.dart';
import 'package:traviato/core/events/global_event_bus.dart';
import 'package:traviato/features/auth/domain/entities/user_entity.dart';
import 'package:traviato/features/auth/presentation/controllers/auth_controller.dart';
import 'package:traviato/features/auth/presentation/controllers/auth_state.dart';
import 'package:traviato/features/home/presentation/controllers/home_header_profile.dart';
import 'package:traviato/features/home/presentation/controllers/home_profile_controller.dart';
import 'package:traviato/features/profile/presentation/providers/profile_providers.dart';

import '../../../profile/fakes/fake_profile_repository.dart';

/// Signed in with a metadata name, the way an email sign-up looks.
class _SignedInAuthController extends AuthController {
  _SignedInAuthController(this.metadataName);

  final String? metadataName;

  @override
  AuthState build() => AuthState.authenticated(
    UserEntity(id: 'u1', email: 'a@b.c', username: metadataName),
  );
}

ProviderContainer _container(
  FakeProfileRepository profileRepo, {
  String? metadataName,
}) {
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      profileRepositoryProvider.overrideWithValue(profileRepo),
      authControllerProvider.overrideWith(
        () => _SignedInAuthController(metadataName),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<HomeHeaderProfile> _read(ProviderContainer container) =>
    container.read(homeProfileControllerProvider.future);

void main() {
  test(
    'greets with profiles.username, not the auth metadata name (#266)',
    () async {
      final repo = FakeProfileRepository()
        ..profileResult = Right(buildProfile(username: 'Leo'));
      final container = _container(repo, metadataName: null);

      expect((await _read(container)).username, 'Leo');
    },
  );

  test(
    'no profile name (Apple sign-in) → null, so Home says "Hello!"',
    () async {
      final repo = FakeProfileRepository()
        ..profileResult = Right(buildProfile(username: '  '));
      final container = _container(repo);

      expect((await _read(container)).username, isNull);
    },
  );

  test('carries the profile avatar (#283)', () async {
    final repo = FakeProfileRepository()
      ..profileResult = Right(
        buildProfile(username: 'Leo', avatarUrl: 'u1/avatar.jpg'),
      );
    final container = _container(repo);

    expect(
      await _read(container),
      const HomeHeaderProfile(username: 'Leo', avatarUrl: 'u1/avatar.jpg'),
    );
  });

  test(
    'a saved profile or new avatar updates the header without a refetch',
    () async {
      final repo = FakeProfileRepository()
        ..profileResult = Right(buildProfile(username: null));
      final container = _container(repo);
      final sub = container.listen(homeProfileControllerProvider, (_, _) {});
      addTearDown(sub.close);
      expect(await _read(container), const HomeHeaderProfile());

      // What the avatar upload mutation publishes (#283).
      container
          .read(globalEventBusProvider)
          .add(
            ProfileUpdatedDispatched(
              profile: buildProfile(
                username: 'Leo',
                avatarUrl: 'u1/avatar.jpg',
              ),
            ),
          );
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(homeProfileControllerProvider).value,
        const HomeHeaderProfile(username: 'Leo', avatarUrl: 'u1/avatar.jpg'),
      );
      expect(repo.getProfileCallCount, 1);
    },
  );

  test(
    'falls back to the metadata name, no avatar, when the read fails',
    () async {
      final repo = FakeProfileRepository()
        ..profileResult = const Left(NetworkFailure());
      final container = _container(repo, metadataName: 'ada');

      expect(await _read(container), const HomeHeaderProfile(username: 'ada'));
    },
  );
}
