import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../providers/auth_providers.dart';

final loginMutation = Mutation<void>();
final signupMutation = Mutation<void>();
final signInWithAppleMutation = Mutation<void>();
final signInWithGoogleMutation = Mutation<void>();
final logoutMutation = Mutation<void>();

Future<void> runLogin({
  required WidgetRef ref,
  required String email,
  required String password,
}) {
  return loginMutation.run(ref, (tsx) async {
    final repo = tsx.get(authRepositoryProvider);
    (await repo.login(email: email, password: password)).fold(
      (failure) => throw PresentationFailureException(failure),
      (_) {},
    );
  });
}

Future<void> runSignup({
  required WidgetRef ref,
  required String email,
  required String password,
  required String username,
}) {
  return signupMutation.run(ref, (tsx) async {
    final repo = tsx.get(authRepositoryProvider);
    (await repo.signup(
      email: email,
      password: password,
      username: username,
    )).fold((failure) => throw PresentationFailureException(failure), (_) {});
  });
}

Future<void> runSignInWithApple({required WidgetRef ref}) {
  return signInWithAppleMutation.run(ref, (tsx) async {
    final repo = tsx.get(authRepositoryProvider);
    (await repo.signInWithApple()).fold(
      (failure) => throw PresentationFailureException(failure),
      (_) {},
    );
  });
}

Future<void> runSignInWithGoogle({required WidgetRef ref}) {
  return signInWithGoogleMutation.run(ref, (tsx) async {
    final repo = tsx.get(authRepositoryProvider);
    (await repo.signInWithGoogle()).fold(
      (failure) => throw PresentationFailureException(failure),
      (_) {},
    );
  });
}

Future<void> runLogout({required WidgetRef ref}) {
  return logoutMutation.run(ref, (tsx) async {
    final repo = tsx.get(authRepositoryProvider);
    (await repo.logout()).fold(
      (failure) => throw PresentationFailureException(failure),
      (_) {},
    );
  });
}
