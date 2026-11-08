import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/film_plan_inspection.dart';
import '../../domain/repositories/film_director_repository.dart';
import '../datasources/film_director_remote_data_source.dart';

class FilmDirectorRepositoryImpl implements FilmDirectorRepository {
  FilmDirectorRepositoryImpl({required FilmDirectorRemoteDataSource remote})
    : _remote = remote;

  final FilmDirectorRemoteDataSource _remote;

  @override
  Future<Either<Failure, FilmPlanInspection>> getInspection(
    String tripId,
  ) async {
    try {
      return Right(await _remote.getInspection(tripId));
    } on AppException catch (e) {
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, void>> rerun(
    String tripId, {
    required String language,
  }) async {
    try {
      await _remote.rerun(tripId, language: language);
      return const Right(null);
    } on AppException catch (e) {
      return Left(_failureFor(e));
    }
  }
}

Failure _failureFor(AppException e) => switch (e) {
  AuthenticationException() => AuthenticationFailure(message: e.message),
  PermissionException() => PermissionFailure(message: e.message),
  ServerException() => ServerFailure(message: e.message),
  NetworkException() => const NetworkFailure(),
  DatabaseException() => ServerFailure(message: e.message),
  _ => UnknownFailure(message: e.message),
};
