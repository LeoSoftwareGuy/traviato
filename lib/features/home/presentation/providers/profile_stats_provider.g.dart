// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_stats_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Stubbed until `profile_stats_view` lands (data-model.md, milestone 3).
/// This is the single place that will swap to a real repository call.

@ProviderFor(profileStats)
final profileStatsProvider = ProfileStatsProvider._();

/// Stubbed until `profile_stats_view` lands (data-model.md, milestone 3).
/// This is the single place that will swap to a real repository call.

final class ProfileStatsProvider
    extends $FunctionalProvider<ProfileStats, ProfileStats, ProfileStats>
    with $Provider<ProfileStats> {
  /// Stubbed until `profile_stats_view` lands (data-model.md, milestone 3).
  /// This is the single place that will swap to a real repository call.
  ProfileStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileStatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileStatsHash();

  @$internal
  @override
  $ProviderElement<ProfileStats> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ProfileStats create(Ref ref) {
    return profileStats(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileStats value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileStats>(value),
    );
  }
}

String _$profileStatsHash() => r'b5e70d9062fa62ce903a2ffd9fbc651588753730';
