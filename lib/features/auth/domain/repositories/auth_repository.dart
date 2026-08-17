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

  Future<Either<Failure, void>> logout();
}
