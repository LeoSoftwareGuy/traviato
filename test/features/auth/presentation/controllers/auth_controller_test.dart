import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/auth/domain/entities/user_entity.dart';
import 'package:traviato/features/auth/presentation/controllers/auth_controller.dart';
import 'package:traviato/features/auth/presentation/controllers/auth_state.dart';
import 'package:traviato/features/auth/presentation/providers/auth_providers.dart';

import '../../fakes/fake_auth_repository.dart';

void main() {
  test('starts unknown, then reflects the auth stream', () async {
    final fakeRepo = FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepo)],
    );
    addTearDown(container.dispose);
    addTearDown(fakeRepo.dispose);
    // Keep the (autoDispose) controller alive for the test, mirroring how
    // the router's ref.listen keeps it alive in the running app.
    container.listen(authControllerProvider, (_, _) {});

    expect(container.read(authControllerProvider).status, AuthStatus.unknown);

    const user = UserEntity(
      id: 'u1',
      email: 'ada@example.com',
      username: 'ada',
    );
    fakeRepo.emit(user);
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(authControllerProvider).status,
      AuthStatus.authenticated,
    );
    expect(container.read(authControllerProvider).user, user);

    fakeRepo.emit(null);
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(authControllerProvider).status,
      AuthStatus.unauthenticated,
    );
    expect(container.read(authControllerProvider).user, isNull);
  });
}
