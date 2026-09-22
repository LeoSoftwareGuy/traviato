// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(purchasesRemoteDataSource)
final purchasesRemoteDataSourceProvider = PurchasesRemoteDataSourceProvider._();

final class PurchasesRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          PurchasesRemoteDataSource,
          PurchasesRemoteDataSource,
          PurchasesRemoteDataSource
        >
    with $Provider<PurchasesRemoteDataSource> {
  PurchasesRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'purchasesRemoteDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$purchasesRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<PurchasesRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PurchasesRemoteDataSource create(Ref ref) {
    return purchasesRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PurchasesRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PurchasesRemoteDataSource>(value),
    );
  }
}

String _$purchasesRemoteDataSourceHash() =>
    r'c067831fba7a305f02a970ef14910ef2381552fc';

@ProviderFor(entitlementsRemoteDataSource)
final entitlementsRemoteDataSourceProvider =
    EntitlementsRemoteDataSourceProvider._();

final class EntitlementsRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          EntitlementsRemoteDataSource,
          EntitlementsRemoteDataSource,
          EntitlementsRemoteDataSource
        >
    with $Provider<EntitlementsRemoteDataSource> {
  EntitlementsRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'entitlementsRemoteDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$entitlementsRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<EntitlementsRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EntitlementsRemoteDataSource create(Ref ref) {
    return entitlementsRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EntitlementsRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EntitlementsRemoteDataSource>(value),
    );
  }
}

String _$entitlementsRemoteDataSourceHash() =>
    r'e5233d1a1016aa285524d5757480bf8b2fafd5db';

@ProviderFor(subscriptionRepository)
final subscriptionRepositoryProvider = SubscriptionRepositoryProvider._();

final class SubscriptionRepositoryProvider
    extends
        $FunctionalProvider<
          SubscriptionRepository,
          SubscriptionRepository,
          SubscriptionRepository
        >
    with $Provider<SubscriptionRepository> {
  SubscriptionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subscriptionRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subscriptionRepositoryHash();

  @$internal
  @override
  $ProviderElement<SubscriptionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SubscriptionRepository create(Ref ref) {
    return subscriptionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SubscriptionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SubscriptionRepository>(value),
    );
  }
}

String _$subscriptionRepositoryHash() =>
    r'05f0287cea14118363b25ef034a508191d750511';
