import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/star_ledger_group_entity.dart';
import '../../domain/repositories/star_breakdown_repository.dart';
import '../datasources/star_breakdown_remote_data_source.dart';

class StarBreakdownRepositoryImpl implements StarBreakdownRepository {
  StarBreakdownRepositoryImpl({required StarBreakdownRemoteDataSource remote})
    : _remote = remote;

  final StarBreakdownRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<StarLedgerGroupEntity>>> getBreakdown() async {
    try {
      return Right(await _remote.getBreakdown());
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }
}
