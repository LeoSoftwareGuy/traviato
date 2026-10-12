import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/exceptions.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:traviato/features/auth/data/models/user_model.dart';
import 'package:traviato/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:traviato/features/auth/domain/entities/signup_result.dart';

class _FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  _FakeAuthRemoteDataSource({
    this.authStateStream = const Stream.empty(),
    this.loginException,
    this.signupException,
    this.signupNeedsConfirmation = false,
    this.resendException,
    this.signInWithAppleException,
    this.signInWithGoogleException,
    this.logoutException,
  });

  final Stream<UserModel?> authStateStream;
  Exception? loginException;
  Exception? signupException;
  bool signupNeedsConfirmation;
  Exception? resendException;
  final resendCalls = <String>[];
  Exception? signInWithAppleException;
  Exception? signInWithGoogleException;
  Exception? logoutException;

  static const _user = UserModel(
    id: 'u1',
    email: 'ada@example.com',
    username: 'ada',
  );

  @override
  Stream<UserModel?> get onAuthStateChanged => authStateStream;

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
  Future<SignupResult> signup({
    required String email,
    required String password,
    required String username,
  }) async {
    if (signupException != null) throw signupException!;
    return SignupResult(
      user: _user,
      needsEmailConfirmation: signupNeedsConfirmation,
    );
  }

  @override
  Future<void> resendSignupConfirmation({required String email}) async {
    resendCalls.add(email);
    if (resendException != null) throw resendException!;
  }

  @override
  Future<void> signInWithApple() async {
    if (signInWithAppleException != null) throw signInWithAppleException!;
  }

  @override
  Future<void> signInWithGoogle() async {
    if (signInWithGoogleException != null) throw signInWithGoogleException!;
  }

  @override
  Future<void> logout() async {
    if (logoutException != null) throw logoutException!;
  }
}

void main() {
  group('AuthRepositoryImpl auth link failures (#157)', () {
    test('a failed confirmation link surfaces as AuthLinkFailure and does not '
        'sign the user out', () async {
      final source = StreamController<UserModel?>.broadcast();
      addTearDown(source.close);
      final repo = AuthRepositoryImpl(
        remote: _FakeAuthRemoteDataSource(authStateStream: source.stream),
      );
      final states = <Object?>[];
      final failures = <Object>[];
      repo.onAuthStateChanged.listen(states.add);
      repo.onAuthLinkFailure.listen(failures.add);

      source
        ..add(_FakeAuthRemoteDataSource._user)
        ..addError(const AuthLinkException(message: 'Email link expired'));
      await Future<void>.delayed(Duration.zero);

      expect(states, [_FakeAuthRemoteDataSource._user]);
      expect(failures, [const AuthLinkFailure()]);
    });

    test('an unexpected stream error still falls back to signed-out and is '
        'not reported as a link failure', () async {
      final source = StreamController<UserModel?>.broadcast();
      addTearDown(source.close);
      final repo = AuthRepositoryImpl(
        remote: _FakeAuthRemoteDataSource(authStateStream: source.stream),
      );
      final states = <Object?>[];
      final failures = <Object>[];
      repo.onAuthStateChanged.listen(states.add);
      repo.onAuthLinkFailure.listen(failures.add);

      source.addError(StateError('boom'));
      await Future<void>.delayed(Duration.zero);

      expect(states, [null]);
      expect(failures, isEmpty);
    });
  });

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

    test('maps a rate limit to RateLimitedFailure (#155)', () async {
      final repo = AuthRepositoryImpl(
        remote: _FakeAuthRemoteDataSource(
          loginException: const RateLimitedException(),
        ),
      );
      final result = await repo.login(
        email: 'ada@example.com',
        password: 'secret1',
      );
      result.fold(
        (failure) => expect(failure, isA<RateLimitedFailure>()),
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
    test('passes through whether the account awaits email confirmation '
        '(#162)', () async {
      for (final needsConfirmation in [true, false]) {
        final repo = AuthRepositoryImpl(
          remote: _FakeAuthRemoteDataSource(
            signupNeedsConfirmation: needsConfirmation,
          ),
        );
        final result = await repo.signup(
          email: 'ada@example.com',
          password: 'secret1',
          username: 'ada',
        );
        result.fold(
          (failure) => fail('expected Right, got Left($failure)'),
          (signup) => expect(signup.needsEmailConfirmation, needsConfirmation),
        );
      }
    });

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

    test('keeps the email-quota flag through to the Failure (#158)', () async {
      final repo = AuthRepositoryImpl(
        remote: _FakeAuthRemoteDataSource(
          signupException: const RateLimitedException(isEmailQuota: true),
        ),
      );
      final result = await repo.signup(
        email: 'ada@example.com',
        password: 'secret1',
        username: 'ada',
      );
      result.fold(
        (failure) => expect(
          failure.message,
          "We've sent too many emails for now. Please try again in a "
          'little while.',
        ),
        (_) => fail('expected Left'),
      );
    });

    test(
      'maps a rate limit to RateLimitedFailure, not a raw throw (#155)',
      () async {
        final repo = AuthRepositoryImpl(
          remote: _FakeAuthRemoteDataSource(
            signupException: const RateLimitedException(retryAfterSeconds: 43),
          ),
        );
        final result = await repo.signup(
          email: 'ada@example.com',
          password: 'secret1',
          username: 'ada',
        );
        result.fold(
          (failure) =>
              expect(failure, RateLimitedFailure(retryAfterSeconds: 43)),
          (_) => fail('expected Left'),
        );
      },
    );
  });

  group('AuthRepositoryImpl.signInWithApple', () {
    test('returns Right(null) on success', () async {
      final repo = AuthRepositoryImpl(remote: _FakeAuthRemoteDataSource());
      final result = await repo.signInWithApple();
      expect(result.isRight(), isTrue);
    });

    test(
      'returns Right(null), not Left, when the user cancels the sheet',
      () async {
        final repo = AuthRepositoryImpl(
          remote: _FakeAuthRemoteDataSource(
            signInWithAppleException: const SignInCancelledException(),
          ),
        );
        final result = await repo.signInWithApple();
        expect(result.isRight(), isTrue);
      },
    );

    test('maps AuthenticationException to AuthenticationFailure', () async {
      final repo = AuthRepositoryImpl(
        remote: _FakeAuthRemoteDataSource(
          signInWithAppleException: const AuthenticationException(
            message: 'apple auth failed',
          ),
        ),
      );
      final result = await repo.signInWithApple();
      result.fold(
        (failure) => expect(
          failure,
          const AuthenticationFailure(message: 'apple auth failed'),
        ),
        (_) => fail('expected Left'),
      );
    });

    test('maps NetworkException to NetworkFailure', () async {
      final repo = AuthRepositoryImpl(
        remote: _FakeAuthRemoteDataSource(
          signInWithAppleException: const NetworkException(),
        ),
      );
      final result = await repo.signInWithApple();
      result.fold(
        (failure) => expect(failure, const NetworkFailure()),
        (_) => fail('expected Left'),
      );
    });
  });

  group('AuthRepositoryImpl.signInWithGoogle', () {
    test('returns Right(null) on success', () async {
      final repo = AuthRepositoryImpl(remote: _FakeAuthRemoteDataSource());
      final result = await repo.signInWithGoogle();
      expect(result.isRight(), isTrue);
    });

    test(
      'returns Right(null), not Left, when the user cancels the sheet',
      () async {
        final repo = AuthRepositoryImpl(
          remote: _FakeAuthRemoteDataSource(
            signInWithGoogleException: const SignInCancelledException(),
          ),
        );
        final result = await repo.signInWithGoogle();
        expect(result.isRight(), isTrue);
      },
    );

    test('maps AuthenticationException to AuthenticationFailure', () async {
      final repo = AuthRepositoryImpl(
        remote: _FakeAuthRemoteDataSource(
          signInWithGoogleException: const AuthenticationException(
            message: 'google auth failed',
          ),
        ),
      );
      final result = await repo.signInWithGoogle();
      result.fold(
        (failure) => expect(
          failure,
          const AuthenticationFailure(message: 'google auth failed'),
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

  group('AuthRepositoryImpl.resendSignupConfirmation (#162)', () {
    test('returns Right on success and resends to the given email', () async {
      final remote = _FakeAuthRemoteDataSource();
      final repo = AuthRepositoryImpl(remote: remote);

      final result = await repo.resendSignupConfirmation(
        email: 'ada@example.com',
      );

      expect(result.isRight(), isTrue);
      expect(remote.resendCalls, ['ada@example.com']);
    });

    test('maps the email quota to the #158 RateLimitedFailure copy', () async {
      final repo = AuthRepositoryImpl(
        remote: _FakeAuthRemoteDataSource(
          resendException: const RateLimitedException(isEmailQuota: true),
        ),
      );

      final result = await repo.resendSignupConfirmation(
        email: 'ada@example.com',
      );

      result.fold(
        (failure) => expect(
          failure,
          isA<RateLimitedFailure>().having(
            (f) => f.isEmailQuota,
            'isEmailQuota',
            isTrue,
          ),
        ),
        (_) => fail('expected Left'),
      );
    });

    test('maps NetworkException to NetworkFailure', () async {
      final repo = AuthRepositoryImpl(
        remote: _FakeAuthRemoteDataSource(
          resendException: const NetworkException(),
        ),
      );

      final result = await repo.resendSignupConfirmation(
        email: 'ada@example.com',
      );

      expect(result, const Left<Failure, void>(NetworkFailure()));
    });
  });
}
