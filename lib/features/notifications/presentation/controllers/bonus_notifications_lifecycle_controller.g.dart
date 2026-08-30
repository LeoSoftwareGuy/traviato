// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bonus_notifications_lifecycle_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns the whole local-notification lifecycle for the bonus daily-tray
/// loop (issue #65): plugin init, the arrival-notification reaction to
/// trip create/edit/delete, the app-open/close-driven re-evaluation of
/// today's morning/evening nudges, and routing a tapped notification to the
/// tray. `keepAlive` — this must survive for the whole app session, exactly
/// like the global event bus it subscribes to (guidelines doc 02).
/// Instantiated once by `ref.watch`ing this provider from
/// `TraviatoApp.build()` in `main.dart`.

@ProviderFor(BonusNotificationsLifecycleController)
final bonusNotificationsLifecycleControllerProvider =
    BonusNotificationsLifecycleControllerProvider._();

/// Owns the whole local-notification lifecycle for the bonus daily-tray
/// loop (issue #65): plugin init, the arrival-notification reaction to
/// trip create/edit/delete, the app-open/close-driven re-evaluation of
/// today's morning/evening nudges, and routing a tapped notification to the
/// tray. `keepAlive` — this must survive for the whole app session, exactly
/// like the global event bus it subscribes to (guidelines doc 02).
/// Instantiated once by `ref.watch`ing this provider from
/// `TraviatoApp.build()` in `main.dart`.
final class BonusNotificationsLifecycleControllerProvider
    extends $NotifierProvider<BonusNotificationsLifecycleController, void> {
  /// Owns the whole local-notification lifecycle for the bonus daily-tray
  /// loop (issue #65): plugin init, the arrival-notification reaction to
  /// trip create/edit/delete, the app-open/close-driven re-evaluation of
  /// today's morning/evening nudges, and routing a tapped notification to the
  /// tray. `keepAlive` — this must survive for the whole app session, exactly
  /// like the global event bus it subscribes to (guidelines doc 02).
  /// Instantiated once by `ref.watch`ing this provider from
  /// `TraviatoApp.build()` in `main.dart`.
  BonusNotificationsLifecycleControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bonusNotificationsLifecycleControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$bonusNotificationsLifecycleControllerHash();

  @$internal
  @override
  BonusNotificationsLifecycleController create() =>
      BonusNotificationsLifecycleController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$bonusNotificationsLifecycleControllerHash() =>
    r'f261c2ac8ece85abf503afe328585920bcfb325c';

/// Owns the whole local-notification lifecycle for the bonus daily-tray
/// loop (issue #65): plugin init, the arrival-notification reaction to
/// trip create/edit/delete, the app-open/close-driven re-evaluation of
/// today's morning/evening nudges, and routing a tapped notification to the
/// tray. `keepAlive` — this must survive for the whole app session, exactly
/// like the global event bus it subscribes to (guidelines doc 02).
/// Instantiated once by `ref.watch`ing this provider from
/// `TraviatoApp.build()` in `main.dart`.

abstract class _$BonusNotificationsLifecycleController extends $Notifier<void> {
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
