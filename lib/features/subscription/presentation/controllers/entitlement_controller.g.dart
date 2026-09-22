// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entitlement_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The shared read of the caller's tier — M6-3/M6-4/M6-5/M6-6 gate their UI
/// on this rather than each re-fetching `entitlements` themselves.

@ProviderFor(EntitlementController)
final entitlementControllerProvider = EntitlementControllerProvider._();

/// The shared read of the caller's tier — M6-3/M6-4/M6-5/M6-6 gate their UI
/// on this rather than each re-fetching `entitlements` themselves.
final class EntitlementControllerProvider
    extends $AsyncNotifierProvider<EntitlementController, EntitlementEntity> {
  /// The shared read of the caller's tier — M6-3/M6-4/M6-5/M6-6 gate their UI
  /// on this rather than each re-fetching `entitlements` themselves.
  EntitlementControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'entitlementControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$entitlementControllerHash();

  @$internal
  @override
  EntitlementController create() => EntitlementController();
}

String _$entitlementControllerHash() =>
    r'd7d2bbcd5280b58f02598e1b43304ee9ea47dac9';

/// The shared read of the caller's tier — M6-3/M6-4/M6-5/M6-6 gate their UI
/// on this rather than each re-fetching `entitlements` themselves.

abstract class _$EntitlementController
    extends $AsyncNotifier<EntitlementEntity> {
  FutureOr<EntitlementEntity> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<EntitlementEntity>, EntitlementEntity>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<EntitlementEntity>, EntitlementEntity>,
              AsyncValue<EntitlementEntity>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
