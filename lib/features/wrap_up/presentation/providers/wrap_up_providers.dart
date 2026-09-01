import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/supabase_providers.dart';
import '../../data/datasources/supabase_wrap_up_remote_data_source.dart';
import '../../data/datasources/wrap_up_remote_data_source.dart';
import '../../data/repositories/wrap_up_repository_impl.dart';
import '../../domain/repositories/wrap_up_repository.dart';

part 'wrap_up_providers.g.dart';

@riverpod
WrapUpRemoteDataSource wrapUpRemoteDataSource(Ref ref) =>
    SupabaseWrapUpRemoteDataSource(client: ref.watch(supabaseClientProvider));

@riverpod
WrapUpRepository wrapUpRepository(Ref ref) =>
    WrapUpRepositoryImpl(remote: ref.watch(wrapUpRemoteDataSourceProvider));
