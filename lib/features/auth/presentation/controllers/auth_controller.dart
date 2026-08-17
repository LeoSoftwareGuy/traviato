import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers/auth_providers.dart';
import 'auth_state.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  AuthState build() {
    final repo = ref.watch(authRepositoryProvider);
    final sub = repo.onAuthStateChanged.listen((user) {
      state = user == null
          ? const AuthState.unauthenticated()
          : AuthState.authenticated(user);
    });
    ref.onDispose(sub.cancel);
    return const AuthState.unknown();
  }
}
