// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dictation_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Kept alive: the platform recogniser is initialised once per app run.

@ProviderFor(dictationService)
final dictationServiceProvider = DictationServiceProvider._();

/// Kept alive: the platform recogniser is initialised once per app run.

final class DictationServiceProvider
    extends
        $FunctionalProvider<
          DictationService,
          DictationService,
          DictationService
        >
    with $Provider<DictationService> {
  /// Kept alive: the platform recogniser is initialised once per app run.
  DictationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dictationServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dictationServiceHash();

  @$internal
  @override
  $ProviderElement<DictationService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DictationService create(Ref ref) {
    return dictationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DictationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DictationService>(value),
    );
  }
}

String _$dictationServiceHash() => r'b3d5460f0889b1f4e6c0aaadf6df6df012cda11b';

/// The recogniser's locale ids, or `null` while unknown (speech permission
/// not granted yet — asking would pop a dialog just for opening a note).
/// Re-read each time a note opens (not keepAlive) and after the mic
/// permission prompt (#218).

@ProviderFor(dictationSupportedLocales)
final dictationSupportedLocalesProvider = DictationSupportedLocalesProvider._();

/// The recogniser's locale ids, or `null` while unknown (speech permission
/// not granted yet — asking would pop a dialog just for opening a note).
/// Re-read each time a note opens (not keepAlive) and after the mic
/// permission prompt (#218).

final class DictationSupportedLocalesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>?>,
          List<String>?,
          FutureOr<List<String>?>
        >
    with $FutureModifier<List<String>?>, $FutureProvider<List<String>?> {
  /// The recogniser's locale ids, or `null` while unknown (speech permission
  /// not granted yet — asking would pop a dialog just for opening a note).
  /// Re-read each time a note opens (not keepAlive) and after the mic
  /// permission prompt (#218).
  DictationSupportedLocalesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dictationSupportedLocalesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dictationSupportedLocalesHash();

  @$internal
  @override
  $FutureProviderElement<List<String>?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>?> create(Ref ref) {
    return dictationSupportedLocales(ref);
  }
}

String _$dictationSupportedLocalesHash() =>
    r'0c6f2d4c659a9f4a9b0ee314be462b726ef0c3bd';

@ProviderFor(dictationLanguageStatus)
final dictationLanguageStatusProvider = DictationLanguageStatusProvider._();

final class DictationLanguageStatusProvider
    extends
        $FunctionalProvider<
          DictationLanguageStatus,
          DictationLanguageStatus,
          DictationLanguageStatus
        >
    with $Provider<DictationLanguageStatus> {
  DictationLanguageStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dictationLanguageStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dictationLanguageStatusHash();

  @$internal
  @override
  $ProviderElement<DictationLanguageStatus> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DictationLanguageStatus create(Ref ref) {
    return dictationLanguageStatus(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DictationLanguageStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DictationLanguageStatus>(value),
    );
  }
}

String _$dictationLanguageStatusHash() =>
    r'ff044d4252a5a8534403ad35a35d561f3d7d9bb1';

/// Whether [language] can be recognised here (`true` while unknown).

@ProviderFor(dictationLanguageSupported)
final dictationLanguageSupportedProvider = DictationLanguageSupportedFamily._();

/// Whether [language] can be recognised here (`true` while unknown).

final class DictationLanguageSupportedProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether [language] can be recognised here (`true` while unknown).
  DictationLanguageSupportedProvider._({
    required DictationLanguageSupportedFamily super.from,
    required AppLanguage super.argument,
  }) : super(
         retry: null,
         name: r'dictationLanguageSupportedProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dictationLanguageSupportedHash();

  @override
  String toString() {
    return r'dictationLanguageSupportedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as AppLanguage;
    return dictationLanguageSupported(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DictationLanguageSupportedProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dictationLanguageSupportedHash() =>
    r'3ab3add757c3e21b77e22982180c727c0eeb67b0';

/// Whether [language] can be recognised here (`true` while unknown).

final class DictationLanguageSupportedFamily extends $Family
    with $FunctionalFamilyOverride<bool, AppLanguage> {
  DictationLanguageSupportedFamily._()
    : super(
        retry: null,
        name: r'dictationLanguageSupportedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether [language] can be recognised here (`true` while unknown).

  DictationLanguageSupportedProvider call(AppLanguage language) =>
      DictationLanguageSupportedProvider._(argument: language, from: this);

  @override
  String toString() => r'dictationLanguageSupportedProvider';
}
