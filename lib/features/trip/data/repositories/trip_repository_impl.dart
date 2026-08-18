import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/trip_card_entity.dart';
import '../../domain/repositories/trip_repository.dart';
import '../datasources/trip_remote_data_source.dart';

class TripRepositoryImpl implements TripRepository {
  TripRepositoryImpl({required TripRemoteDataSource remote}) : _remote = remote;

  final TripRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<TripCardEntity>>> getTripCards() async {
    try {
      return Right(await _remote.getTripCards());
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }
}
