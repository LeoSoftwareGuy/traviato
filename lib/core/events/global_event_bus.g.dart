// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_event_bus.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(globalEventBus)
final globalEventBusProvider = GlobalEventBusProvider._();

final class GlobalEventBusProvider
    extends $FunctionalProvider<GlobalEventBus, GlobalEventBus, GlobalEventBus>
    with $Provider<GlobalEventBus> {
  GlobalEventBusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'globalEventBusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$globalEventBusHash();

  @$internal
  @override
  $ProviderElement<GlobalEventBus> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GlobalEventBus create(Ref ref) {
    return globalEventBus(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GlobalEventBus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GlobalEventBus>(value),
    );
  }
}

String _$globalEventBusHash() => r'74678a1a24ba743786ee35e19505189c48781328';
