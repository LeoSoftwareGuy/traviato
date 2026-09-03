// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(profileRemoteDataSource)
final profileRemoteDataSourceProvider = ProfileRemoteDataSourceProvider._();

final class ProfileRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          ProfileRemoteDataSource,
          ProfileRemoteDataSource,
          ProfileRemoteDataSource
        >
    with $Provider<ProfileRemoteDataSource> {
  ProfileRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileRemoteDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<ProfileRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProfileRemoteDataSource create(Ref ref) {
    return profileRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileRemoteDataSource>(value),
    );
  }
}

String _$profileRemoteDataSourceHash() =>
    r'cf3338cb39b2b4507563e88a77f9e7024cd96b74';

@ProviderFor(profileRepository)
final profileRepositoryProvider = ProfileRepositoryProvider._();

final class ProfileRepositoryProvider
    extends
        $FunctionalProvider<
          ProfileRepository,
          ProfileRepository,
          ProfileRepository
        >
    with $Provider<ProfileRepository> {
  ProfileRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProfileRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProfileRepository create(Ref ref) {
    return profileRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileRepository>(value),
    );
  }
}

String _$profileRepositoryHash() => r'e04acf9294fbabec957163ba2f02f8fad5ea4067';

/// Signs a stored avatar path for display — `avatars` is a private bucket.
/// Auto-dispose, cached per path (mirrors `coverImageUrlProvider`).

@ProviderFor(avatarImageUrl)
final avatarImageUrlProvider = AvatarImageUrlFamily._();

/// Signs a stored avatar path for display — `avatars` is a private bucket.
/// Auto-dispose, cached per path (mirrors `coverImageUrlProvider`).

final class AvatarImageUrlProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// Signs a stored avatar path for display — `avatars` is a private bucket.
  /// Auto-dispose, cached per path (mirrors `coverImageUrlProvider`).
  AvatarImageUrlProvider._({
    required AvatarImageUrlFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'avatarImageUrlProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$avatarImageUrlHash();

  @override
  String toString() {
    return r'avatarImageUrlProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    final argument = this.argument as String;
    return avatarImageUrl(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AvatarImageUrlProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$avatarImageUrlHash() => r'dbe185bf6bb8820e9d43d2edf5ffb71bfb9dbf0f';

/// Signs a stored avatar path for display — `avatars` is a private bucket.
/// Auto-dispose, cached per path (mirrors `coverImageUrlProvider`).

final class AvatarImageUrlFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String>, String> {
  AvatarImageUrlFamily._()
    : super(
        retry: null,
        name: r'avatarImageUrlProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Signs a stored avatar path for display — `avatars` is a private bucket.
  /// Auto-dispose, cached per path (mirrors `coverImageUrlProvider`).

  AvatarImageUrlProvider call(String storagePath) =>
      AvatarImageUrlProvider._(argument: storagePath, from: this);

  @override
  String toString() => r'avatarImageUrlProvider';
}
