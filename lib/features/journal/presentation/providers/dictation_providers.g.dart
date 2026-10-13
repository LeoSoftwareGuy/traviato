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
