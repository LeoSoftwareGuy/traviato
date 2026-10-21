import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/core/events/global_event.dart';
import 'package:traviato/core/events/global_event_bus.dart';
import 'package:traviato/features/auth/domain/entities/user_entity.dart';
import 'package:traviato/features/auth/presentation/controllers/auth_controller.dart';
import 'package:traviato/features/auth/presentation/controllers/auth_state.dart';
import 'package:traviato/features/home/presentation/controllers/home_username_controller.dart';
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

void main() {
  test(
    'greets with profiles.username, not the auth metadata name (#266)',
    () async {
      final repo = FakeProfileRepository()
        ..profileResult = Right(buildProfile(username: 'Leo'));
      final container = _container(repo, metadataName: null);

      expect(
        await container.read(homeUsernameControllerProvider.future),
        'Leo',
      );
    },
  );

  test(
    'no profile name (Apple sign-in) → null, so Home says "Hello!"',
    () async {
      final repo = FakeProfileRepository()
        ..profileResult = Right(buildProfile(username: '  '));
      final container = _container(repo);

      expect(
        await container.read(homeUsernameControllerProvider.future),
        isNull,
      );
    },
  );

  test('a saved profile updates the name without a refetch', () async {
    final repo = FakeProfileRepository()
      ..profileResult = Right(buildProfile(username: null));
    final container = _container(repo);
    final sub = container.listen(homeUsernameControllerProvider, (_, _) {});
    addTearDown(sub.close);
    expect(await container.read(homeUsernameControllerProvider.future), isNull);

    container
        .read(globalEventBusProvider)
        .add(ProfileUpdatedDispatched(profile: buildProfile(username: 'Leo')));
    await Future<void>.delayed(Duration.zero);

    expect(container.read(homeUsernameControllerProvider).value, 'Leo');
    expect(repo.getProfileCallCount, 1);
  });

  test('falls back to the metadata name when the profile read fails', () async {
    final repo = FakeProfileRepository()
      ..profileResult = const Left(NetworkFailure());
    final container = _container(repo, metadataName: 'ada');

    expect(await container.read(homeUsernameControllerProvider.future), 'ada');
  });
}
