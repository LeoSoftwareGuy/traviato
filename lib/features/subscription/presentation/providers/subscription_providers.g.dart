// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether `Purchases.configure` ran this session. `main.dart` overrides this
/// with the real result; the default is the safe answer — never call into an
/// unconfigured RevenueCat SDK (#156).

@ProviderFor(revenueCatConfigured)
final revenueCatConfiguredProvider = RevenueCatConfiguredProvider._();

/// Whether `Purchases.configure` ran this session. `main.dart` overrides this
/// with the real result; the default is the safe answer — never call into an
/// unconfigured RevenueCat SDK (#156).

final class RevenueCatConfiguredProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether `Purchases.configure` ran this session. `main.dart` overrides this
  /// with the real result; the default is the safe answer — never call into an
  /// unconfigured RevenueCat SDK (#156).
  RevenueCatConfiguredProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'revenueCatConfiguredProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$revenueCatConfiguredHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return revenueCatConfigured(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$revenueCatConfiguredHash() =>
    r'47a932af743a25394be19f04dbaf16e2e3a10c5a';

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
    r'62ea8e371d9c66e2254c7a5b2ab85c294e055594';

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
