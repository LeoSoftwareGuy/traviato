// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(photoRemoteDataSource)
final photoRemoteDataSourceProvider = PhotoRemoteDataSourceProvider._();

final class PhotoRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          PhotoRemoteDataSource,
          PhotoRemoteDataSource,
          PhotoRemoteDataSource
        >
    with $Provider<PhotoRemoteDataSource> {
  PhotoRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'photoRemoteDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$photoRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<PhotoRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PhotoRemoteDataSource create(Ref ref) {
    return photoRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PhotoRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PhotoRemoteDataSource>(value),
    );
  }
}

String _$photoRemoteDataSourceHash() =>
    r'a59819a300dc12839324c06d5172f2facdbe58d1';

@ProviderFor(photoRepository)
final photoRepositoryProvider = PhotoRepositoryProvider._();

final class PhotoRepositoryProvider
    extends
        $FunctionalProvider<PhotoRepository, PhotoRepository, PhotoRepository>
    with $Provider<PhotoRepository> {
  PhotoRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'photoRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$photoRepositoryHash();

  @$internal
  @override
  $ProviderElement<PhotoRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PhotoRepository create(Ref ref) {
    return photoRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PhotoRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PhotoRepository>(value),
    );
  }
}

String _$photoRepositoryHash() => r'2b9de6cb84dc4dd83d3694f1472961eaf88f3929';

@ProviderFor(photoCompressor)
final photoCompressorProvider = PhotoCompressorProvider._();

final class PhotoCompressorProvider
    extends
        $FunctionalProvider<PhotoCompressor, PhotoCompressor, PhotoCompressor>
    with $Provider<PhotoCompressor> {
  PhotoCompressorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'photoCompressorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$photoCompressorHash();

  @$internal
  @override
  $ProviderElement<PhotoCompressor> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PhotoCompressor create(Ref ref) {
    return photoCompressor(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PhotoCompressor value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PhotoCompressor>(value),
    );
  }
}

String _$photoCompressorHash() => r'cfdbd02f0727a62fcdc7a06c7a29768e248ad109';

@ProviderFor(photoExifReader)
final photoExifReaderProvider = PhotoExifReaderProvider._();

final class PhotoExifReaderProvider
    extends
        $FunctionalProvider<PhotoExifReader, PhotoExifReader, PhotoExifReader>
    with $Provider<PhotoExifReader> {
  PhotoExifReaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'photoExifReaderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$photoExifReaderHash();

  @$internal
  @override
  $ProviderElement<PhotoExifReader> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PhotoExifReader create(Ref ref) {
    return photoExifReader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PhotoExifReader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PhotoExifReader>(value),
    );
  }
}

String _$photoExifReaderHash() => r'1cb26cd60e7bcce9a6faef380c7f7ed6575d9bf3';
