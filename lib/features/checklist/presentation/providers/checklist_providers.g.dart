// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checklist_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(checklistRemoteDataSource)
final checklistRemoteDataSourceProvider = ChecklistRemoteDataSourceProvider._();

final class ChecklistRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          ChecklistRemoteDataSource,
          ChecklistRemoteDataSource,
          ChecklistRemoteDataSource
        >
    with $Provider<ChecklistRemoteDataSource> {
  ChecklistRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checklistRemoteDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checklistRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<ChecklistRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ChecklistRemoteDataSource create(Ref ref) {
    return checklistRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChecklistRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChecklistRemoteDataSource>(value),
    );
  }
}

String _$checklistRemoteDataSourceHash() =>
    r'b17c14c4180e708cfb09d1db96b59cec95e338f3';

@ProviderFor(checklistRepository)
final checklistRepositoryProvider = ChecklistRepositoryProvider._();

final class ChecklistRepositoryProvider
    extends
        $FunctionalProvider<
          ChecklistRepository,
          ChecklistRepository,
          ChecklistRepository
        >
    with $Provider<ChecklistRepository> {
  ChecklistRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checklistRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checklistRepositoryHash();

  @$internal
  @override
  $ProviderElement<ChecklistRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ChecklistRepository create(Ref ref) {
    return checklistRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChecklistRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChecklistRepository>(value),
    );
  }
}

String _$checklistRepositoryHash() =>
    r'99f967ec0f686abd9579d6cf0c3da9070cd3de5a';
