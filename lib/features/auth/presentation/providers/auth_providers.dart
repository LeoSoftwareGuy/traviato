import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/supabase_providers.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/supabase_auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_providers.g.dart';

@riverpod
AuthRemoteDataSource authRemoteDataSource(Ref ref) =>
    SupabaseAuthRemoteDataSource(client: ref.watch(supabaseClientProvider));

@riverpod
AuthRepository authRepository(Ref ref) =>
    AuthRepositoryImpl(remote: ref.watch(authRemoteDataSourceProvider));
