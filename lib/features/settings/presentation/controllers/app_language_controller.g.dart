// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_language_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The user's UI-language choice (#236): on-device first, mirrored to
/// `profiles.language` while signed in.

@ProviderFor(AppLanguageController)
final appLanguageControllerProvider = AppLanguageControllerProvider._();

/// The user's UI-language choice (#236): on-device first, mirrored to
/// `profiles.language` while signed in.
final class AppLanguageControllerProvider
    extends $NotifierProvider<AppLanguageController, AppLanguage> {
  /// The user's UI-language choice (#236): on-device first, mirrored to
  /// `profiles.language` while signed in.
  AppLanguageControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLanguageControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLanguageControllerHash();

  @$internal
  @override
  AppLanguageController create() => AppLanguageController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppLanguage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppLanguage>(value),
    );
  }
}

String _$appLanguageControllerHash() =>
    r'384f0d09f876c6d4e50c70ce9cefbf443a3f4f4e';

/// The user's UI-language choice (#236): on-device first, mirrored to
/// `profiles.language` while signed in.

abstract class _$AppLanguageController extends $Notifier<AppLanguage> {
  AppLanguage build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AppLanguage, AppLanguage>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppLanguage, AppLanguage>,
              AppLanguage,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// What the choice resolves to right now — `system` becomes the device's
/// first supported language (or English).

@ProviderFor(resolvedAppLanguage)
final resolvedAppLanguageProvider = ResolvedAppLanguageProvider._();

/// What the choice resolves to right now — `system` becomes the device's
/// first supported language (or English).

final class ResolvedAppLanguageProvider
    extends $FunctionalProvider<AppLanguage, AppLanguage, AppLanguage>
    with $Provider<AppLanguage> {
  /// What the choice resolves to right now — `system` becomes the device's
  /// first supported language (or English).
  ResolvedAppLanguageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'resolvedAppLanguageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$resolvedAppLanguageHash();

  @$internal
  @override
  $ProviderElement<AppLanguage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppLanguage create(Ref ref) {
    return resolvedAppLanguage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppLanguage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppLanguage>(value),
    );
  }
}

String _$resolvedAppLanguageHash() =>
    r'e79f465aeefc9c7f0f185dc93561dca9c714b899';

/// The locale `MaterialApp` runs in.

@ProviderFor(appLocale)
final appLocaleProvider = AppLocaleProvider._();

/// The locale `MaterialApp` runs in.

final class AppLocaleProvider
    extends $FunctionalProvider<Locale, Locale, Locale>
    with $Provider<Locale> {
  /// The locale `MaterialApp` runs in.
  AppLocaleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLocaleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLocaleHash();

  @$internal
  @override
  $ProviderElement<Locale> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Locale create(Ref ref) {
    return appLocale(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Locale value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Locale>(value),
    );
  }
}

String _$appLocaleHash() => r'270f5499bf301b8b3b94e7d4f614f89e19b398ae';

/// Reconciles the device choice with `profiles.language` on sign-in
/// (#236): a value on the profile wins (it's the user's choice from
/// another device); otherwise this device's choice is written up.
/// Instantiated from `TraviatoApp.build()`, like the other lifecycle
/// controllers.

@ProviderFor(LanguageProfileSyncController)
final languageProfileSyncControllerProvider =
    LanguageProfileSyncControllerProvider._();

/// Reconciles the device choice with `profiles.language` on sign-in
/// (#236): a value on the profile wins (it's the user's choice from
/// another device); otherwise this device's choice is written up.
/// Instantiated from `TraviatoApp.build()`, like the other lifecycle
/// controllers.
final class LanguageProfileSyncControllerProvider
    extends $NotifierProvider<LanguageProfileSyncController, void> {
  /// Reconciles the device choice with `profiles.language` on sign-in
  /// (#236): a value on the profile wins (it's the user's choice from
  /// another device); otherwise this device's choice is written up.
  /// Instantiated from `TraviatoApp.build()`, like the other lifecycle
  /// controllers.
  LanguageProfileSyncControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'languageProfileSyncControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$languageProfileSyncControllerHash();

  @$internal
  @override
  LanguageProfileSyncController create() => LanguageProfileSyncController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$languageProfileSyncControllerHash() =>
    r'cf8297ae7a932228e91937bad0f324633513042d';

/// Reconciles the device choice with `profiles.language` on sign-in
/// (#236): a value on the profile wins (it's the user's choice from
/// another device); otherwise this device's choice is written up.
/// Instantiated from `TraviatoApp.build()`, like the other lifecycle
/// controllers.

abstract class _$LanguageProfileSyncController extends $Notifier<void> {
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
