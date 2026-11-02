// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(shareRemoteDataSource)
final shareRemoteDataSourceProvider = ShareRemoteDataSourceProvider._();

final class ShareRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          ShareRemoteDataSource,
          ShareRemoteDataSource,
          ShareRemoteDataSource
        >
    with $Provider<ShareRemoteDataSource> {
  ShareRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shareRemoteDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shareRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<ShareRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ShareRemoteDataSource create(Ref ref) {
    return shareRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShareRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShareRemoteDataSource>(value),
    );
  }
}

String _$shareRemoteDataSourceHash() =>
    r'e514f5bbbae6134547ff8679efa0117a48a2d488';

@ProviderFor(shareImageService)
final shareImageServiceProvider = ShareImageServiceProvider._();

final class ShareImageServiceProvider
    extends
        $FunctionalProvider<
          ShareImageService,
          ShareImageService,
          ShareImageService
        >
    with $Provider<ShareImageService> {
  ShareImageServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shareImageServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shareImageServiceHash();

  @$internal
  @override
  $ProviderElement<ShareImageService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ShareImageService create(Ref ref) {
    return shareImageService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShareImageService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShareImageService>(value),
    );
  }
}

String _$shareImageServiceHash() => r'f90da90c203bbac16a4f219c8401659bcb9876ed';

@ProviderFor(shareRepository)
final shareRepositoryProvider = ShareRepositoryProvider._();

final class ShareRepositoryProvider
    extends
        $FunctionalProvider<ShareRepository, ShareRepository, ShareRepository>
    with $Provider<ShareRepository> {
  ShareRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shareRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shareRepositoryHash();

  @$internal
  @override
  $ProviderElement<ShareRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ShareRepository create(Ref ref) {
    return shareRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShareRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShareRepository>(value),
    );
  }
}

String _$shareRepositoryHash() => r'6d4513987e2b7896df5c21eaa39c8255b153bfef';

@ProviderFor(pendingShareSlugPrefs)
final pendingShareSlugPrefsProvider = PendingShareSlugPrefsProvider._();

final class PendingShareSlugPrefsProvider
    extends
        $FunctionalProvider<
          PendingShareSlugPrefs,
          PendingShareSlugPrefs,
          PendingShareSlugPrefs
        >
    with $Provider<PendingShareSlugPrefs> {
  PendingShareSlugPrefsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingShareSlugPrefsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingShareSlugPrefsHash();

  @$internal
  @override
  $ProviderElement<PendingShareSlugPrefs> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PendingShareSlugPrefs create(Ref ref) {
    return pendingShareSlugPrefs(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PendingShareSlugPrefs value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PendingShareSlugPrefs>(value),
    );
  }
}

String _$pendingShareSlugPrefsHash() =>
    r'94d0e497bc30bd1fcad4d40261115a5677aab134';

/// The stored pending slug (#310), read in `main()` before `runApp` and
/// overridden there, so the router sees it on the first redirect.

@ProviderFor(initialPendingShareSlug)
final initialPendingShareSlugProvider = InitialPendingShareSlugProvider._();

/// The stored pending slug (#310), read in `main()` before `runApp` and
/// overridden there, so the router sees it on the first redirect.

final class InitialPendingShareSlugProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// The stored pending slug (#310), read in `main()` before `runApp` and
  /// overridden there, so the router sees it on the first redirect.
  InitialPendingShareSlugProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'initialPendingShareSlugProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$initialPendingShareSlugHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return initialPendingShareSlug(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$initialPendingShareSlugHash() =>
    r'54541a46813ea197444c72085b7a19fa51fb57bd';
