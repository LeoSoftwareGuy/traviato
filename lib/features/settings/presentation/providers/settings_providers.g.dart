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

@ProviderFor(dictationLanguagePrefs)
final dictationLanguagePrefsProvider = DictationLanguagePrefsProvider._();

final class DictationLanguagePrefsProvider
    extends
        $FunctionalProvider<
          DictationLanguagePrefs,
          DictationLanguagePrefs,
          DictationLanguagePrefs
        >
    with $Provider<DictationLanguagePrefs> {
  DictationLanguagePrefsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dictationLanguagePrefsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dictationLanguagePrefsHash();

  @$internal
  @override
  $ProviderElement<DictationLanguagePrefs> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DictationLanguagePrefs create(Ref ref) {
    return dictationLanguagePrefs(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DictationLanguagePrefs value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DictationLanguagePrefs>(value),
    );
  }
}

String _$dictationLanguagePrefsHash() =>
    r'db03270197cfd5876f2b9fc877d9b79dd5ae50e0';

/// The stored dictation language (or `null`), read in `main()` like
/// [initialAppLanguage] (#218).

@ProviderFor(initialDictationLanguage)
final initialDictationLanguageProvider = InitialDictationLanguageProvider._();

/// The stored dictation language (or `null`), read in `main()` like
/// [initialAppLanguage] (#218).

final class InitialDictationLanguageProvider
    extends $FunctionalProvider<AppLanguage?, AppLanguage?, AppLanguage?>
    with $Provider<AppLanguage?> {
  /// The stored dictation language (or `null`), read in `main()` like
  /// [initialAppLanguage] (#218).
  InitialDictationLanguageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'initialDictationLanguageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$initialDictationLanguageHash();

  @$internal
  @override
  $ProviderElement<AppLanguage?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppLanguage? create(Ref ref) {
    return initialDictationLanguage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppLanguage? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppLanguage?>(value),
    );
  }
}

String _$initialDictationLanguageHash() =>
    r'77573993fd957736874710b09b4c614ec4ac4fd5';

@ProviderFor(reduceFlashingPrefs)
final reduceFlashingPrefsProvider = ReduceFlashingPrefsProvider._();

final class ReduceFlashingPrefsProvider
    extends
        $FunctionalProvider<
          ReduceFlashingPrefs,
          ReduceFlashingPrefs,
          ReduceFlashingPrefs
        >
    with $Provider<ReduceFlashingPrefs> {
  ReduceFlashingPrefsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reduceFlashingPrefsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reduceFlashingPrefsHash();

  @$internal
  @override
  $ProviderElement<ReduceFlashingPrefs> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReduceFlashingPrefs create(Ref ref) {
    return reduceFlashingPrefs(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReduceFlashingPrefs value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReduceFlashingPrefs>(value),
    );
  }
}

String _$reduceFlashingPrefsHash() =>
    r'43e35a4b0d2ee55f958e9f9f0615e34d52c655e7';

/// The stored "Reduce flashing" choice, read in `main()` like
/// [initialAppLanguage], so a film never plays its first flash before the
/// setting has loaded (#363).

@ProviderFor(initialReduceFlashing)
final initialReduceFlashingProvider = InitialReduceFlashingProvider._();

/// The stored "Reduce flashing" choice, read in `main()` like
/// [initialAppLanguage], so a film never plays its first flash before the
/// setting has loaded (#363).

final class InitialReduceFlashingProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// The stored "Reduce flashing" choice, read in `main()` like
  /// [initialAppLanguage], so a film never plays its first flash before the
  /// setting has loaded (#363).
  InitialReduceFlashingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'initialReduceFlashingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$initialReduceFlashingHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return initialReduceFlashing(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$initialReduceFlashingHash() =>
    r'5880b887c0760230ba280a2aa84b238d12a08d7e';
