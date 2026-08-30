import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/profile_stats_entity.dart';

abstract interface class ProfileStatsRepository {
  Future<Either<Failure, ProfileStatsEntity>> getStats();
}
