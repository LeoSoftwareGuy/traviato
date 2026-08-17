import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/auth/domain/entities/user_entity.dart';
import 'package:traviato/features/auth/domain/repositories/auth_repository.dart';

/// Test double for [AuthRepository]. The auth-state stream is driven
/// manually via [emit]; `login`/`signup`/`logout` return whatever result is
/// configured (defaulting to success) and record their calls.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository();

  final _controller = StreamController<UserEntity?>.broadcast();
  final loginCalls = <String>[];
  final signupCalls = <String>[];
  var logoutCalled = false;

  Either<Failure, UserEntity>? loginResult;
  Either<Failure, UserEntity>? signupResult;
  Either<Failure, void>? logoutResult;
  Duration delay = Duration.zero;

  void emit(UserEntity? user) => _controller.add(user);

  Future<void> dispose() => _controller.close();

  @override
  Stream<UserEntity?> get onAuthStateChanged => _controller.stream;

  @override
  UserEntity? get currentUser => null;

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    loginCalls.add(email);
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return loginResult ?? Right(UserEntity(id: 'u1', email: email));
  }

  @override
  Future<Either<Failure, UserEntity>> signup({
    required String email,
    required String password,
    required String username,
  }) async {
    signupCalls.add(email);
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return signupResult ??
        Right(UserEntity(id: 'u1', email: email, username: username));
  }

  @override
  Future<Either<Failure, void>> logout() async {
    logoutCalled = true;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return logoutResult ?? const Right(null);
  }
}
