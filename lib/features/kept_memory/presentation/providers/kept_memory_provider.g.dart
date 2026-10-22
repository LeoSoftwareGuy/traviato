// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kept_memory_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Everything the Kept Memory page shows (#279), fetched concurrently and
/// grouped by [buildKeptMemory]. Read-only — the page edits nothing, so
/// there's no controller or event subscription.

@ProviderFor(keptMemory)
final keptMemoryProvider = KeptMemoryFamily._();

/// Everything the Kept Memory page shows (#279), fetched concurrently and
/// grouped by [buildKeptMemory]. Read-only — the page edits nothing, so
/// there's no controller or event subscription.

final class KeptMemoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<KeptMemory>,
          KeptMemory,
          FutureOr<KeptMemory>
        >
    with $FutureModifier<KeptMemory>, $FutureProvider<KeptMemory> {
  /// Everything the Kept Memory page shows (#279), fetched concurrently and
  /// grouped by [buildKeptMemory]. Read-only — the page edits nothing, so
  /// there's no controller or event subscription.
  KeptMemoryProvider._({
    required KeptMemoryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'keptMemoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$keptMemoryHash();

  @override
  String toString() {
    return r'keptMemoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<KeptMemory> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<KeptMemory> create(Ref ref) {
    final argument = this.argument as String;
    return keptMemory(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is KeptMemoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$keptMemoryHash() => r'601a1c794b9db04807a74433edb551e2b92ef467';

/// Everything the Kept Memory page shows (#279), fetched concurrently and
/// grouped by [buildKeptMemory]. Read-only — the page edits nothing, so
/// there's no controller or event subscription.

final class KeptMemoryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<KeptMemory>, String> {
  KeptMemoryFamily._()
    : super(
        retry: null,
        name: r'keptMemoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Everything the Kept Memory page shows (#279), fetched concurrently and
  /// grouped by [buildKeptMemory]. Read-only — the page edits nothing, so
  /// there's no controller or event subscription.

  KeptMemoryProvider call(String tripId) =>
      KeptMemoryProvider._(argument: tripId, from: this);

  @override
  String toString() => r'keptMemoryProvider';
}
