import '../models/profile_stats_model.dart';

abstract interface class ProfileStatsRemoteDataSource {
  Future<ProfileStatsModel> getStats();
}
