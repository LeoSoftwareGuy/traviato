import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/auth/domain/entities/user_entity.dart';
import 'package:traviato/features/auth/domain/repositories/auth_repository.dart';
import 'package:traviato/features/auth/presentation/providers/auth_providers.dart';
import 'package:traviato/main.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<UserEntity?> get onAuthStateChanged => const Stream.empty();

  @override
  UserEntity? get currentUser => null;

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<Either<Failure, UserEntity>> signup({
    required String email,
    required String password,
    required String username,
  }) => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> signInWithApple() => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> signInWithGoogle() =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, void>> logout() => throw UnimplementedError();
}

void main() {
  testWidgets(
    'TraviatoApp shows the splash page while auth status is unknown',
    (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          ],
          child: const TraviatoApp(),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    },
  );
}
