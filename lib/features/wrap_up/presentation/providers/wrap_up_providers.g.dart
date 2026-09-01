// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wrap_up_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(wrapUpRemoteDataSource)
final wrapUpRemoteDataSourceProvider = WrapUpRemoteDataSourceProvider._();

final class WrapUpRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          WrapUpRemoteDataSource,
          WrapUpRemoteDataSource,
          WrapUpRemoteDataSource
        >
    with $Provider<WrapUpRemoteDataSource> {
  WrapUpRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wrapUpRemoteDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wrapUpRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<WrapUpRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WrapUpRemoteDataSource create(Ref ref) {
    return wrapUpRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WrapUpRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WrapUpRemoteDataSource>(value),
    );
  }
}

String _$wrapUpRemoteDataSourceHash() =>
    r'8e78b096a04fe0d4e629e2d370e5d8c94c1db95a';

@ProviderFor(wrapUpRepository)
final wrapUpRepositoryProvider = WrapUpRepositoryProvider._();

final class WrapUpRepositoryProvider
    extends
        $FunctionalProvider<
          WrapUpRepository,
          WrapUpRepository,
          WrapUpRepository
        >
    with $Provider<WrapUpRepository> {
  WrapUpRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wrapUpRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wrapUpRepositoryHash();

  @$internal
  @override
  $ProviderElement<WrapUpRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WrapUpRepository create(Ref ref) {
    return wrapUpRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WrapUpRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WrapUpRepository>(value),
    );
  }
}

String _$wrapUpRepositoryHash() => r'e15d0eda78c5239749d6fb81f62ca72d9ad87375';
