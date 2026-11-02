import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:play_install_referrer/play_install_referrer.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/config/router/app_router.dart';
import '../../../../core/config/router/route_constants.dart';
import '../../data/prefs/pending_share_slug_prefs.dart';
import '../../domain/share_slug.dart';
import '../providers/share_providers.dart';
import 'pending_share_slug_controller.dart';

part 'share_link_intake_controller.g.dart';

/// Where shared-memory links come into the app (#310):
/// - universal / app links (`https://storyni.app/m/{slug}`) and the web
///   page's `com.leo.storyni://m/{slug}` fallback, through `app_links`
///   (Flutter deep linking is off — supabase_flutter owns auth links);
/// - on Android's first launch, the Play install referrer the web page's
///   store button set.
/// Each one becomes the pending slug and opens `/m/{slug}`; the router's
/// redirect holds it through the splash and sign-up. `keepAlive`,
/// instantiated from `main.dart`.
@Riverpod(keepAlive: true)
class ShareLinkIntakeController extends _$ShareLinkIntakeController {
  @override
  void build() {
    final sub = AppLinks().uriLinkStream.listen(
      (uri) {
        final slug = parseShareSlug(uri.toString());
        if (slug != null) open(slug);
      },
      onError: (Object e) => debugPrint('Share link stream failed: $e'),
    );
    ref.onDispose(sub.cancel);
    unawaited(_readInstallReferrer());
  }

  /// Opens the shared memory [slug] — also used by "I have a link".
  void open(String slug) {
    ref.read(pendingShareSlugControllerProvider.notifier).set(slug);
    ref.read(routerProvider).go(RoutePaths.sharedMemoryFor(slug));
  }

  Future<void> _readInstallReferrer() async {
    if (defaultTargetPlatform != TargetPlatform.android || kIsWeb) return;
    try {
      final alreadyChecked = await ref
          .read(pendingShareSlugPrefsProvider)
          .testAndSet(PendingShareSlugPrefs.referrerCheckedKey);
      if (alreadyChecked) return;
      final details = await PlayInstallReferrer.installReferrer;
      final slug = parseReferrerSlug(details.installReferrer);
      if (slug != null) open(slug);
    } catch (e) {
      // No Play Store (emulator, sideload) — nothing to restore.
      debugPrint('Install referrer unavailable: $e');
    }
  }
}
