import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract interface class AuthRepository {
  Stream<UserEntity?> get onAuthStateChanged;

  UserEntity? get currentUser;

  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> signup({
    required String email,
    required String password,
    required String username,
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
