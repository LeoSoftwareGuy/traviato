import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers/share_providers.dart';

part 'pending_share_slug_controller.g.dart';

/// The shared memory someone arrived from and hasn't seen signed in yet
/// (#310's deferred deep link). The router sends them to `/m/{slug}` once
/// the splash, sign-up or log-in is done; the preview page clears it once
/// shown signed in. Persisted, so it survives the install → first launch
/// gap and an app restart mid sign-up.
@Riverpod(keepAlive: true)
class PendingShareSlugController extends _$PendingShareSlugController {
  @override
  String? build() => ref.read(initialPendingShareSlugProvider);

  void set(String slug) {
    if (state == slug) return;
    state = slug;
    unawaited(ref.read(pendingShareSlugPrefsProvider).write(slug));
  }

  void clear() {
    if (state == null) return;
    state = null;
    unawaited(ref.read(pendingShareSlugPrefsProvider).write(null));
  }
}
