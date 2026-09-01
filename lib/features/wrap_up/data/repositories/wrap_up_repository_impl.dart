import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/wrap_up_entity.dart';
import '../../domain/repositories/wrap_up_repository.dart';
import '../datasources/wrap_up_remote_data_source.dart';

class WrapUpRepositoryImpl implements WrapUpRepository {
  WrapUpRepositoryImpl({required WrapUpRemoteDataSource remote})
    : _remote = remote;

  final WrapUpRemoteDataSource _remote;

  @override
  Future<Either<Failure, WrapUpEntity>> getOrGenerate(String tripId) async {
    try {
      return Right(await _remote.getOrGenerate(tripId));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(message: e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> publish(String tripId) async {
    try {
      await _remote.publish(tripId);
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
