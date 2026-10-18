// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appLanguagePrefs)
final appLanguagePrefsProvider = AppLanguagePrefsProvider._();

final class AppLanguagePrefsProvider
    extends
        $FunctionalProvider<
          AppLanguagePrefs,
          AppLanguagePrefs,
          AppLanguagePrefs
        >
    with $Provider<AppLanguagePrefs> {
  AppLanguagePrefsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLanguagePrefsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLanguagePrefsHash();

  @$internal
  @override
  $ProviderElement<AppLanguagePrefs> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppLanguagePrefs create(Ref ref) {
    return appLanguagePrefs(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppLanguagePrefs value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppLanguagePrefs>(value),
    );
  }
}

String _$appLanguagePrefsHash() => r'02e87b0eb7823ab3ec13919971781916bf3de812';

/// The stored choice, read in `main()` before `runApp` and overridden there,
/// so the first frame is already in the right language (#236).

@ProviderFor(initialAppLanguage)
final initialAppLanguageProvider = InitialAppLanguageProvider._();

/// The stored choice, read in `main()` before `runApp` and overridden there,
/// so the first frame is already in the right language (#236).

final class InitialAppLanguageProvider
    extends $FunctionalProvider<AppLanguage, AppLanguage, AppLanguage>
    with $Provider<AppLanguage> {
  /// The stored choice, read in `main()` before `runApp` and overridden there,
  /// so the first frame is already in the right language (#236).
  InitialAppLanguageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'initialAppLanguageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$initialAppLanguageHash();

  @$internal
  @override
  $ProviderElement<AppLanguage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppLanguage create(Ref ref) {
    return initialAppLanguage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppLanguage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppLanguage>(value),
    );
  }
}

String _$initialAppLanguageHash() =>
    r'eceb0a9f1a78b37f413214450208b3f4d3ab61d3';
