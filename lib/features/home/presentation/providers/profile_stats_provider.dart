import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/supabase_providers.dart';
import '../../data/datasources/profile_stats_remote_data_source.dart';
import '../../data/datasources/supabase_profile_stats_remote_data_source.dart';
import '../../data/repositories/profile_stats_repository_impl.dart';
import '../../domain/repositories/profile_stats_repository.dart';

part 'profile_stats_provider.g.dart';

@riverpod
ProfileStatsRemoteDataSource profileStatsRemoteDataSource(Ref ref) =>
    SupabaseProfileStatsRemoteDataSource(
      client: ref.watch(supabaseClientProvider),
    );

@riverpod
ProfileStatsRepository profileStatsRepository(Ref ref) =>
    ProfileStatsRepositoryImpl(
      remote: ref.watch(profileStatsRemoteDataSourceProvider),
    );
