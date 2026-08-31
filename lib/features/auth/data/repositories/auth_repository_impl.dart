import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required AuthRemoteDataSource remote}) : _remote = remote;

  final AuthRemoteDataSource _remote;

  // Wraps the data-source stream so an unexpected error logs and emits a
  // safe `null` fallback (signed-out) instead of terminating the stream —
  // the router redirect depends on this stream never dying (doc 03).
  @override
  Stream<UserEntity?> get onAuthStateChanged {
    StreamSubscription<UserEntity?>? subscription;
    late final StreamController<UserEntity?> controller;
    controller = StreamController<UserEntity?>.broadcast(
      onListen: () {
        subscription = _remote.onAuthStateChanged.listen(
          controller.add,
          onError: (Object error, StackTrace st) {
            debugPrint('Auth state stream error: $error\n$st');
            controller.add(null);
          },
        );
      },
      onCancel: () => subscription?.cancel(),
    );
    return controller.stream;
  }

  @override
  UserEntity? get currentUser => _remote.currentUser;

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      return Right(await _remote.login(email: email, password: password));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signup({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      return Right(
        await _remote.signup(
          email: email,
          password: password,
          username: username,
        ),
      );
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> signInWithApple() =>
      _runSocialSignIn(_remote.signInWithApple);

  @override
  Future<Either<Failure, void>> signInWithGoogle() =>
      _runSocialSignIn(_remote.signInWithGoogle);

  // Shared by both social providers: a cancelled sheet resolves to
  // Right(null) exactly like success (the router reacts to the auth-state
  // stream either way, so the caller has nothing else to do) — only a real
  // failure becomes Left.
  Future<Either<Failure, void>> _runSocialSignIn(
    Future<void> Function() signIn,
  ) async {
    try {
      await signIn();
      return const Right(null);
    } on SignInCancelledException {
      return const Right(null);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remote.logout();
      return const Right(null);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }
}
