import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../domain/entities/signup_result.dart';
import '../providers/auth_providers.dart';

final loginMutation = Mutation<void>();
final signupMutation = Mutation<SignupResult>();
final resendConfirmationMutation = Mutation<void>();
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

Future<SignupResult> runSignup({
  required WidgetRef ref,
  required String email,
  required String password,
  required String username,
}) {
  return signupMutation.run(ref, (tsx) async {
    final repo = tsx.get(authRepositoryProvider);
    return (await repo.signup(
      email: email,
      password: password,
      username: username,
    )).fold(
      (failure) => throw PresentationFailureException(failure),
      (result) => result,
    );
  });
}

Future<void> runResendConfirmation({
  required WidgetRef ref,
  required String email,
}) {
  return resendConfirmationMutation.run(ref, (tsx) async {
    final repo = tsx.get(authRepositoryProvider);
    (await repo.resendSignupConfirmation(email: email)).fold(
      (failure) => throw PresentationFailureException(failure),
      (_) {},
    );
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
