import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/supabase_providers.dart';
import '../../data/datasources/share_remote_data_source.dart';
import '../../data/datasources/supabase_share_remote_data_source.dart';
import '../../data/prefs/pending_share_slug_prefs.dart';
import '../../data/repositories/share_repository_impl.dart';
import '../../data/services/share_image_service.dart';
import '../../domain/repositories/share_repository.dart';

part 'share_providers.g.dart';

@riverpod
ShareRemoteDataSource shareRemoteDataSource(Ref ref) =>
    SupabaseShareRemoteDataSource(client: ref.watch(supabaseClientProvider));

@riverpod
ShareImageService shareImageService(Ref ref) => const ShareImageService();

@riverpod
ShareRepository shareRepository(Ref ref) => ShareRepositoryImpl(
  remote: ref.watch(shareRemoteDataSourceProvider),
  images: ref.watch(shareImageServiceProvider),
);

@Riverpod(keepAlive: true)
PendingShareSlugPrefs pendingShareSlugPrefs(Ref ref) =>
    const PendingShareSlugPrefs();

/// The stored pending slug (#310), read in `main()` before `runApp` and
/// overridden there, so the router sees it on the first redirect.
@Riverpod(keepAlive: true)
String? initialPendingShareSlug(Ref ref) => null;
