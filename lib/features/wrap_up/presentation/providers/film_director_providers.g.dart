// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'film_director_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(filmDirectorRemoteDataSource)
final filmDirectorRemoteDataSourceProvider =
    FilmDirectorRemoteDataSourceProvider._();

final class FilmDirectorRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          FilmDirectorRemoteDataSource,
          FilmDirectorRemoteDataSource,
          FilmDirectorRemoteDataSource
        >
    with $Provider<FilmDirectorRemoteDataSource> {
  FilmDirectorRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filmDirectorRemoteDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filmDirectorRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<FilmDirectorRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FilmDirectorRemoteDataSource create(Ref ref) {
    return filmDirectorRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FilmDirectorRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FilmDirectorRemoteDataSource>(value),
    );
  }
}

String _$filmDirectorRemoteDataSourceHash() =>
    r'89fa230a52d4f7293eda79aa12c40ed28f34ffdb';

@ProviderFor(filmDirectorRepository)
final filmDirectorRepositoryProvider = FilmDirectorRepositoryProvider._();

final class FilmDirectorRepositoryProvider
    extends
        $FunctionalProvider<
          FilmDirectorRepository,
          FilmDirectorRepository,
          FilmDirectorRepository
        >
    with $Provider<FilmDirectorRepository> {
  FilmDirectorRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filmDirectorRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filmDirectorRepositoryHash();

  @$internal
  @override
  $ProviderElement<FilmDirectorRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FilmDirectorRepository create(Ref ref) {
    return filmDirectorRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FilmDirectorRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FilmDirectorRepository>(value),
    );
  }
}

String _$filmDirectorRepositoryHash() =>
    r'5a964aba8ed7c62d98dd950fdc502c65206c78f5';

/// What the debug Plan inspector (#328) shows: the last director run and
/// the photo analysis.

@ProviderFor(filmPlanInspection)
final filmPlanInspectionProvider = FilmPlanInspectionFamily._();

/// What the debug Plan inspector (#328) shows: the last director run and
/// the photo analysis.

final class FilmPlanInspectionProvider
    extends
        $FunctionalProvider<
          AsyncValue<FilmPlanInspection>,
          FilmPlanInspection,
          FutureOr<FilmPlanInspection>
        >
    with
        $FutureModifier<FilmPlanInspection>,
        $FutureProvider<FilmPlanInspection> {
  /// What the debug Plan inspector (#328) shows: the last director run and
  /// the photo analysis.
  FilmPlanInspectionProvider._({
    required FilmPlanInspectionFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'filmPlanInspectionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$filmPlanInspectionHash();

  @override
  String toString() {
    return r'filmPlanInspectionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<FilmPlanInspection> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<FilmPlanInspection> create(Ref ref) {
    final argument = this.argument as String;
    return filmPlanInspection(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FilmPlanInspectionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$filmPlanInspectionHash() =>
    r'8129e5a35dacc25e937ddda5a745f51265e9f8d4';

/// What the debug Plan inspector (#328) shows: the last director run and
/// the photo analysis.

final class FilmPlanInspectionFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<FilmPlanInspection>, String> {
  FilmPlanInspectionFamily._()
    : super(
        retry: null,
        name: r'filmPlanInspectionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// What the debug Plan inspector (#328) shows: the last director run and
  /// the photo analysis.

  FilmPlanInspectionProvider call(String tripId) =>
      FilmPlanInspectionProvider._(argument: tripId, from: this);

  @override
  String toString() => r'filmPlanInspectionProvider';
}

/// Signed thumbnail URL per photo id, for the inspector's scene rows. A
/// failed lookup just means no thumbnails.

@ProviderFor(filmPlanPhotoUrls)
final filmPlanPhotoUrlsProvider = FilmPlanPhotoUrlsFamily._();

/// Signed thumbnail URL per photo id, for the inspector's scene rows. A
/// failed lookup just means no thumbnails.

final class FilmPlanPhotoUrlsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, String>>,
          Map<String, String>,
          FutureOr<Map<String, String>>
        >
    with
        $FutureModifier<Map<String, String>>,
        $FutureProvider<Map<String, String>> {
  /// Signed thumbnail URL per photo id, for the inspector's scene rows. A
  /// failed lookup just means no thumbnails.
  FilmPlanPhotoUrlsProvider._({
    required FilmPlanPhotoUrlsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'filmPlanPhotoUrlsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$filmPlanPhotoUrlsHash();

  @override
  String toString() {
    return r'filmPlanPhotoUrlsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Map<String, String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, String>> create(Ref ref) {
    final argument = this.argument as String;
    return filmPlanPhotoUrls(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FilmPlanPhotoUrlsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$filmPlanPhotoUrlsHash() => r'c0b3b361e399bae99d27c2421005d424948c8eba';

/// Signed thumbnail URL per photo id, for the inspector's scene rows. A
/// failed lookup just means no thumbnails.

final class FilmPlanPhotoUrlsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Map<String, String>>, String> {
  FilmPlanPhotoUrlsFamily._()
    : super(
        retry: null,
        name: r'filmPlanPhotoUrlsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Signed thumbnail URL per photo id, for the inspector's scene rows. A
  /// failed lookup just means no thumbnails.

  FilmPlanPhotoUrlsProvider call(String tripId) =>
      FilmPlanPhotoUrlsProvider._(argument: tripId, from: this);

  @override
  String toString() => r'filmPlanPhotoUrlsProvider';
}
