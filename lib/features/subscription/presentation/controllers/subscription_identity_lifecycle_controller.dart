import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/auth_state.dart';
import '../providers/subscription_providers.dart';
import 'entitlement_controller.dart';

part 'subscription_identity_lifecycle_controller.g.dart';

/// Keeps RevenueCat's app-user-id in step with the signed-in Supabase user
/// (issue #138) — mirrors `BonusNotificationsLifecycleController`'s shape.
/// `keepAlive` so it survives for the whole session; instantiated once by
/// `ref.watch`ing this provider from `TraviatoApp.build()`.
@Riverpod(keepAlive: true)
class SubscriptionIdentityLifecycleController
    extends _$SubscriptionIdentityLifecycleController {
  @override
  void build() {
    ref.listen<AuthState>(
      authControllerProvider,
      (previous, next) => unawaited(_sync(previous, next)),
      fireImmediately: true,
    );
  }

  /// Wrapped in a broad `try/catch`, not just an `Either` fold: this runs
  /// off an auth-state listener with nothing to show a failure to, so even
  /// a provider-construction error (e.g. RevenueCat/Supabase not configured
  /// in this environment) should log and degrade rather than propagate into
  /// `ref.listen`'s caller (guidelines doc 03, same posture as
  /// `BonusNotificationsLifecycleController._evaluate`).
  Future<void> _sync(AuthState? previous, AuthState next) async {
    if (previous?.status == next.status &&
        previous?.user?.id == next.user?.id) {
      return;
    }
    try {
      final repo = ref.read(subscriptionRepositoryProvider);
      switch (next.status) {
        case AuthStatus.authenticated:
          await repo.syncIdentity(next.user!.id);
        case AuthStatus.unauthenticated:
          await repo.syncIdentity(null);
        case AuthStatus.unknown:
          return;
      }
      if (!ref.mounted) return;
      ref.invalidate(entitlementControllerProvider);
    } catch (e) {
      debugPrint('Subscription identity sync failed: $e');
    }
  }
}
