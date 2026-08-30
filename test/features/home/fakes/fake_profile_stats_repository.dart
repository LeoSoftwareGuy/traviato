import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/home/domain/entities/profile_stats_entity.dart';
import 'package:traviato/features/home/domain/repositories/profile_stats_repository.dart';

class FakeProfileStatsRepository implements ProfileStatsRepository {
  Either<Failure, ProfileStatsEntity>? statsResult;
  var getStatsCallCount = 0;

  @override
  Future<Either<Failure, ProfileStatsEntity>> getStats() async {
    getStatsCallCount++;
    return statsResult ?? const Right(ProfileStatsEntity.zero());
  }
}
