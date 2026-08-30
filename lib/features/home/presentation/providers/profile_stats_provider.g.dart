// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_stats_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(profileStatsRemoteDataSource)
final profileStatsRemoteDataSourceProvider =
    ProfileStatsRemoteDataSourceProvider._();

final class ProfileStatsRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          ProfileStatsRemoteDataSource,
          ProfileStatsRemoteDataSource,
          ProfileStatsRemoteDataSource
        >
    with $Provider<ProfileStatsRemoteDataSource> {
  ProfileStatsRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileStatsRemoteDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileStatsRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<ProfileStatsRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProfileStatsRemoteDataSource create(Ref ref) {
    return profileStatsRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileStatsRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileStatsRemoteDataSource>(value),
    );
  }
}

String _$profileStatsRemoteDataSourceHash() =>
    r'2131357e2a040be4db133fd574585c06fb6fbf60';

@ProviderFor(profileStatsRepository)
final profileStatsRepositoryProvider = ProfileStatsRepositoryProvider._();

final class ProfileStatsRepositoryProvider
    extends
        $FunctionalProvider<
          ProfileStatsRepository,
          ProfileStatsRepository,
          ProfileStatsRepository
        >
    with $Provider<ProfileStatsRepository> {
  ProfileStatsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileStatsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileStatsRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProfileStatsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProfileStatsRepository create(Ref ref) {
    return profileStatsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileStatsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileStatsRepository>(value),
    );
  }
}

String _$profileStatsRepositoryHash() =>
    r'326a14ae9bc1271652ee772b33ea44fffe93a554';
