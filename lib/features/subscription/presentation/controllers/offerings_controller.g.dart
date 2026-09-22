// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offerings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OfferingsController)
final offeringsControllerProvider = OfferingsControllerProvider._();

final class OfferingsControllerProvider
    extends
        $AsyncNotifierProvider<
          OfferingsController,
          List<SubscriptionOfferingEntity>
        > {
  OfferingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'offeringsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$offeringsControllerHash();

  @$internal
  @override
  OfferingsController create() => OfferingsController();
}

String _$offeringsControllerHash() =>
    r'af6b1a6210f2e95f1ec29d497896b05feec697e4';

abstract class _$OfferingsController
    extends $AsyncNotifier<List<SubscriptionOfferingEntity>> {
  FutureOr<List<SubscriptionOfferingEntity>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<SubscriptionOfferingEntity>>,
              List<SubscriptionOfferingEntity>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<SubscriptionOfferingEntity>>,
                List<SubscriptionOfferingEntity>
              >,
              AsyncValue<List<SubscriptionOfferingEntity>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
