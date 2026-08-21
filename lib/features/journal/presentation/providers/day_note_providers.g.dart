// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_note_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(dayNoteRemoteDataSource)
final dayNoteRemoteDataSourceProvider = DayNoteRemoteDataSourceProvider._();

final class DayNoteRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          DayNoteRemoteDataSource,
          DayNoteRemoteDataSource,
          DayNoteRemoteDataSource
        >
    with $Provider<DayNoteRemoteDataSource> {
  DayNoteRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dayNoteRemoteDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dayNoteRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<DayNoteRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DayNoteRemoteDataSource create(Ref ref) {
    return dayNoteRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DayNoteRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DayNoteRemoteDataSource>(value),
    );
  }
}

String _$dayNoteRemoteDataSourceHash() =>
    r'4f03554ddad29cd0238ccf934b69045e3e5a4dd9';

@ProviderFor(dayNoteRepository)
final dayNoteRepositoryProvider = DayNoteRepositoryProvider._();

final class DayNoteRepositoryProvider
    extends
        $FunctionalProvider<
          DayNoteRepository,
          DayNoteRepository,
          DayNoteRepository
        >
    with $Provider<DayNoteRepository> {
  DayNoteRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dayNoteRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dayNoteRepositoryHash();

  @$internal
  @override
  $ProviderElement<DayNoteRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DayNoteRepository create(Ref ref) {
    return dayNoteRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DayNoteRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DayNoteRepository>(value),
    );
  }
}

String _$dayNoteRepositoryHash() => r'932fef04de15e5209765209b05f2f3871b4670e6';
