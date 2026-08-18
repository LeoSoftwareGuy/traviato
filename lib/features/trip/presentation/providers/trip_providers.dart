import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/supabase_providers.dart';
import '../../data/datasources/supabase_trip_remote_data_source.dart';
import '../../data/datasources/trip_remote_data_source.dart';
import '../../data/repositories/trip_repository_impl.dart';
import '../../domain/repositories/trip_repository.dart';

part 'trip_providers.g.dart';

@riverpod
TripRemoteDataSource tripRemoteDataSource(Ref ref) =>
    SupabaseTripRemoteDataSource(client: ref.watch(supabaseClientProvider));

@riverpod
TripRepository tripRepository(Ref ref) =>
    TripRepositoryImpl(remote: ref.watch(tripRemoteDataSourceProvider));
