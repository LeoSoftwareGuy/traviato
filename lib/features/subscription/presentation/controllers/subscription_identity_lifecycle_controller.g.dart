// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_identity_lifecycle_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Keeps RevenueCat's app-user-id in step with the signed-in Supabase user
/// (issue #138) — mirrors `BonusNotificationsLifecycleController`'s shape.
/// `keepAlive` so it survives for the whole session; instantiated once by
/// `ref.watch`ing this provider from `TraviatoApp.build()`.

@ProviderFor(SubscriptionIdentityLifecycleController)
final subscriptionIdentityLifecycleControllerProvider =
    SubscriptionIdentityLifecycleControllerProvider._();

/// Keeps RevenueCat's app-user-id in step with the signed-in Supabase user
/// (issue #138) — mirrors `BonusNotificationsLifecycleController`'s shape.
/// `keepAlive` so it survives for the whole session; instantiated once by
/// `ref.watch`ing this provider from `TraviatoApp.build()`.
final class SubscriptionIdentityLifecycleControllerProvider
    extends $NotifierProvider<SubscriptionIdentityLifecycleController, void> {
  /// Keeps RevenueCat's app-user-id in step with the signed-in Supabase user
  /// (issue #138) — mirrors `BonusNotificationsLifecycleController`'s shape.
  /// `keepAlive` so it survives for the whole session; instantiated once by
  /// `ref.watch`ing this provider from `TraviatoApp.build()`.
  SubscriptionIdentityLifecycleControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subscriptionIdentityLifecycleControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$subscriptionIdentityLifecycleControllerHash();

  @$internal
  @override
  SubscriptionIdentityLifecycleController create() =>
      SubscriptionIdentityLifecycleController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$subscriptionIdentityLifecycleControllerHash() =>
    r'fd00a099e3286ae16b297cd8e23209ec0f598ad0';

/// Keeps RevenueCat's app-user-id in step with the signed-in Supabase user
/// (issue #138) — mirrors `BonusNotificationsLifecycleController`'s shape.
/// `keepAlive` so it survives for the whole session; instantiated once by
/// `ref.watch`ing this provider from `TraviatoApp.build()`.

abstract class _$SubscriptionIdentityLifecycleController
    extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
