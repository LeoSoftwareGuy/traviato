import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/errors/exceptions.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:traviato/features/auth/data/models/user_model.dart';
import 'package:traviato/features/auth/data/repositories/auth_repository_impl.dart';

class _FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  _FakeAuthRemoteDataSource({
    this.loginException,
    this.signupException,
    this.logoutException,
  });

  Exception? loginException;
  Exception? signupException;
  Exception? logoutException;

  static const _user = UserModel(
    id: 'u1',
    email: 'ada@example.com',
    username: 'ada',
  );

  @override
  Stream<UserModel?> get onAuthStateChanged => const Stream.empty();

  @override
  UserModel? get currentUser => null;

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    if (loginException != null) throw loginException!;
    return _user;
  }

  @override
  Future<UserModel> signup({
    required String email,
    required String password,
    required String username,
  }) async {
    if (signupException != null) throw signupException!;
    return _user;
  }

  @override
  Future<void> logout() async {
    if (logoutException != null) throw logoutException!;
  }
}

void main() {
  group('AuthRepositoryImpl.login', () {
    test('returns Right(user) on success', () async {
      final repo = AuthRepositoryImpl(remote: _FakeAuthRemoteDataSource());
      final result = await repo.login(
        email: 'ada@example.com',
        password: 'secret1',
      );
      result.fold(
        (failure) => fail('expected Right, got Left($failure)'),
        (user) => expect(user.email, 'ada@example.com'),
      );
    });

    test('maps AuthenticationException to AuthenticationFailure', () async {
      final repo = AuthRepositoryImpl(
        remote: _FakeAuthRemoteDataSource(
          loginException: const AuthenticationException(
            message: 'bad creds',
          ),
        ),
      );
      final result = await repo.login(
        email: 'ada@example.com',
        password: 'secret1',
      );
      result.fold(
        (failure) =>
            expect(failure, const AuthenticationFailure(message: 'bad creds')),
        (_) => fail('expected Left'),
      );
    });

    test('maps NetworkException to NetworkFailure', () async {
      final repo = AuthRepositoryImpl(
        remote: _FakeAuthRemoteDataSource(
          loginException: const NetworkException(),
        ),
      );
      final result = await repo.login(
        email: 'ada@example.com',
        password: 'secret1',
      );
      result.fold(
        (failure) => expect(failure, const NetworkFailure()),
        (_) => fail('expected Left'),
      );
    });

    test('maps other AppExceptions to UnknownFailure', () async {
      final repo = AuthRepositoryImpl(
        remote: _FakeAuthRemoteDataSource(
          loginException: const UnknownException(message: 'boom'),
        ),
      );
      final result = await repo.login(
        email: 'ada@example.com',
        password: 'secret1',
      );
      result.fold(
        (failure) => expect(failure, const UnknownFailure(message: 'boom')),
        (_) => fail('expected Left'),
      );
    });
  });

  group('AuthRepositoryImpl.signup', () {
    test('returns Right(user) on success', () async {
      final repo = AuthRepositoryImpl(remote: _FakeAuthRemoteDataSource());
      final result = await repo.signup(
        email: 'ada@example.com',
        password: 'secret1',
        username: 'ada',
      );
      expect(result.isRight(), isTrue);
    });

    test('maps AuthenticationException to AuthenticationFailure', () async {
      final repo = AuthRepositoryImpl(
        remote: _FakeAuthRemoteDataSource(
          signupException: const AuthenticationException(
            message: 'email already registered',
          ),
        ),
      );
      final result = await repo.signup(
        email: 'ada@example.com',
        password: 'secret1',
        username: 'ada',
      );
      result.fold(
        (failure) => expect(
          failure,
          const AuthenticationFailure(message: 'email already registered'),
        ),
        (_) => fail('expected Left'),
      );
    });
  });

  group('AuthRepositoryImpl.logout', () {
    test('returns Right(null) on success', () async {
      final repo = AuthRepositoryImpl(remote: _FakeAuthRemoteDataSource());
      final result = await repo.logout();
      expect(result.isRight(), isTrue);
    });

    test('maps AuthenticationException to AuthenticationFailure', () async {
      final repo = AuthRepositoryImpl(
        remote: _FakeAuthRemoteDataSource(
          logoutException: const AuthenticationException(
            message: 'no session',
          ),
        ),
      );
      final result = await repo.logout();
      result.fold(
        (failure) =>
            expect(failure, const AuthenticationFailure(message: 'no session')),
        (_) => fail('expected Left'),
      );
    });
  });
}
