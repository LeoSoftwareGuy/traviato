import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../../../core/providers/supabase_providers.dart';
import '../../data/datasources/profile_remote_data_source.dart';
import '../../data/datasources/supabase_profile_remote_data_source.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/repositories/profile_repository.dart';

part 'profile_providers.g.dart';

@riverpod
ProfileRemoteDataSource profileRemoteDataSource(Ref ref) =>
    SupabaseProfileRemoteDataSource(client: ref.watch(supabaseClientProvider));

@riverpod
ProfileRepository profileRepository(Ref ref) =>
    ProfileRepositoryImpl(remote: ref.watch(profileRemoteDataSourceProvider));

/// Signs a stored avatar path for display — `avatars` is a private bucket.
/// Auto-dispose, cached per path (mirrors `coverImageUrlProvider`).
@riverpod
Future<String> avatarImageUrl(Ref ref, String storagePath) async {
  final repo = ref.watch(profileRepositoryProvider);
  return (await repo.getAvatarUrl(storagePath)).fold(
    (failure) => throw PresentationFailureException(failure),
    (url) => url,
  );
}
