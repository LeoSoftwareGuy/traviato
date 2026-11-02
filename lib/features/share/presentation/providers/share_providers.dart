import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/supabase_providers.dart';
import '../../data/datasources/share_remote_data_source.dart';
import '../../data/datasources/supabase_share_remote_data_source.dart';
import '../../data/prefs/pending_share_slug_prefs.dart';
import '../../data/repositories/share_repository_impl.dart';
import '../../data/services/share_image_service.dart';
import '../../data/services/share_outlets.dart';
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

/// The share sheet's ways out (#311). `FACEBOOK_APP_ID` (Meta App ID) in
/// `.env` turns on Instagram Stories; without it the story card goes to
/// the system share sheet.
@riverpod
ShareOutlets shareOutlets(Ref ref) => ShareOutlets(
  facebookAppId: dotenv.isInitialized ? dotenv.env['FACEBOOK_APP_ID'] : null,
);
