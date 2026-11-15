// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reduce_flashing_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The You → Settings "Reduce flashing" switch (#363): films with flashes
/// (Neon Night) play their softer version. Stored on the device.

@ProviderFor(ReduceFlashingController)
final reduceFlashingControllerProvider = ReduceFlashingControllerProvider._();

/// The You → Settings "Reduce flashing" switch (#363): films with flashes
/// (Neon Night) play their softer version. Stored on the device.
final class ReduceFlashingControllerProvider
    extends $NotifierProvider<ReduceFlashingController, bool> {
  /// The You → Settings "Reduce flashing" switch (#363): films with flashes
  /// (Neon Night) play their softer version. Stored on the device.
  ReduceFlashingControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reduceFlashingControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reduceFlashingControllerHash();

  @$internal
  @override
  ReduceFlashingController create() => ReduceFlashingController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$reduceFlashingControllerHash() =>
    r'3b02d1376eef9fe14f0c483c0954e6a0ba09da6f';

/// The You → Settings "Reduce flashing" switch (#363): films with flashes
/// (Neon Night) play their softer version. Stored on the device.

abstract class _$ReduceFlashingController extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
