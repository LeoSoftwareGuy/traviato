import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/signup_result.dart';
import '../entities/user_entity.dart';

abstract interface class AuthRepository {
  Stream<UserEntity?> get onAuthStateChanged;

  /// Emits an [AuthLinkFailure] each time an incoming email confirmation
  /// link fails to produce a session (#157) — expired, already used, or
  /// opened on another device. Such failures never touch
  /// [onAuthStateChanged]: a stale link doesn't sign anyone out.
  Stream<AuthLinkFailure> get onAuthLinkFailure;

  UserEntity? get currentUser;

  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, SignupResult>> signup({
    required String email,
    required String password,
    required String username,
  });

  /// Re-sends the signup confirmation email (#162). Rate limits surface as
  /// [RateLimitedFailure], the hourly email quota included.
  Future<Either<Failure, void>> resendSignupConfirmation({
    required String email,
  });

  /// Native Sign in with Apple. Resolves to `Right(null)` both on success
  /// and when the user cancels the system sheet — the router already reacts
  /// to [onAuthStateChanged], so the caller has nothing else to do either
  /// way; only a real failure surfaces as [Left].
  Future<Either<Failure, void>> signInWithApple();

  /// Native Google sign-in. Same `Right(null)`-on-cancel contract as
  /// [signInWithApple].
  Future<Either<Failure, void>> signInWithGoogle();

  Future<Either<Failure, void>> logout();
}
