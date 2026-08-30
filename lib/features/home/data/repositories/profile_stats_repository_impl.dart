import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/profile_stats_entity.dart';
import '../../domain/repositories/profile_stats_repository.dart';
import '../datasources/profile_stats_remote_data_source.dart';

class ProfileStatsRepositoryImpl implements ProfileStatsRepository {
  ProfileStatsRepositoryImpl({required ProfileStatsRemoteDataSource remote})
    : _remote = remote;

  final ProfileStatsRemoteDataSource _remote;

  @override
  Future<Either<Failure, ProfileStatsEntity>> getStats() async {
    try {
      return Right(await _remote.getStats());
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }
}
