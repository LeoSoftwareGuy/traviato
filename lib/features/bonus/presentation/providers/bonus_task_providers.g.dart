// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bonus_task_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(bonusTaskRemoteDataSource)
final bonusTaskRemoteDataSourceProvider = BonusTaskRemoteDataSourceProvider._();

final class BonusTaskRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          BonusTaskRemoteDataSource,
          BonusTaskRemoteDataSource,
          BonusTaskRemoteDataSource
        >
    with $Provider<BonusTaskRemoteDataSource> {
  BonusTaskRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bonusTaskRemoteDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bonusTaskRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<BonusTaskRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BonusTaskRemoteDataSource create(Ref ref) {
    return bonusTaskRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BonusTaskRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BonusTaskRemoteDataSource>(value),
    );
  }
}

String _$bonusTaskRemoteDataSourceHash() =>
    r'8510631fb2992572d65b44a2ba926ef8c8616501';

@ProviderFor(bonusTaskRepository)
final bonusTaskRepositoryProvider = BonusTaskRepositoryProvider._();

final class BonusTaskRepositoryProvider
    extends
        $FunctionalProvider<
          BonusTaskRepository,
          BonusTaskRepository,
          BonusTaskRepository
        >
    with $Provider<BonusTaskRepository> {
  BonusTaskRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bonusTaskRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bonusTaskRepositoryHash();

  @$internal
  @override
  $ProviderElement<BonusTaskRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BonusTaskRepository create(Ref ref) {
    return bonusTaskRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BonusTaskRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BonusTaskRepository>(value),
    );
  }
}

String _$bonusTaskRepositoryHash() =>
    r'817b63ba4678d0b237a1ed06e389981911323e50';

@ProviderFor(ensureDailyTrayUseCase)
final ensureDailyTrayUseCaseProvider = EnsureDailyTrayUseCaseProvider._();

final class EnsureDailyTrayUseCaseProvider
    extends
        $FunctionalProvider<
          EnsureDailyTrayUseCase,
          EnsureDailyTrayUseCase,
          EnsureDailyTrayUseCase
        >
    with $Provider<EnsureDailyTrayUseCase> {
  EnsureDailyTrayUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ensureDailyTrayUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ensureDailyTrayUseCaseHash();

  @$internal
  @override
  $ProviderElement<EnsureDailyTrayUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EnsureDailyTrayUseCase create(Ref ref) {
    return ensureDailyTrayUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EnsureDailyTrayUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EnsureDailyTrayUseCase>(value),
    );
  }
}

String _$ensureDailyTrayUseCaseHash() =>
    r'040dbbc73d0552110263968fcdd911984a965cbe';
