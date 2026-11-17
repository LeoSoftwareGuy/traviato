// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_stats_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Home's stats-bar totals and stars badge. Refetches whenever a
/// [StarsAwardedDispatched] event arrives — quest check-off, day-note
/// save, photo add, or bonus-task completion (issue #77) — so the badge
/// updates live instead of only on the next cold load. Also on
/// [TripDeletedDispatched]: a deleted memory takes its stars and its
/// counts with it (#247).

@ProviderFor(ProfileStatsController)
final profileStatsControllerProvider = ProfileStatsControllerProvider._();

/// Home's stats-bar totals and stars badge. Refetches whenever a
/// [StarsAwardedDispatched] event arrives — quest check-off, day-note
/// save, photo add, or bonus-task completion (issue #77) — so the badge
/// updates live instead of only on the next cold load. Also on
/// [TripDeletedDispatched]: a deleted memory takes its stars and its
/// counts with it (#247).
final class ProfileStatsControllerProvider
    extends $AsyncNotifierProvider<ProfileStatsController, ProfileStatsEntity> {
  /// Home's stats-bar totals and stars badge. Refetches whenever a
  /// [StarsAwardedDispatched] event arrives — quest check-off, day-note
  /// save, photo add, or bonus-task completion (issue #77) — so the badge
  /// updates live instead of only on the next cold load. Also on
  /// [TripDeletedDispatched]: a deleted memory takes its stars and its
  /// counts with it (#247).
  ProfileStatsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileStatsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileStatsControllerHash();

  @$internal
  @override
  ProfileStatsController create() => ProfileStatsController();
}

String _$profileStatsControllerHash() =>
    r'c12bf8d653276d4ad171f18e62fb8519e82107fa';

/// Home's stats-bar totals and stars badge. Refetches whenever a
/// [StarsAwardedDispatched] event arrives — quest check-off, day-note
/// save, photo add, or bonus-task completion (issue #77) — so the badge
/// updates live instead of only on the next cold load. Also on
/// [TripDeletedDispatched]: a deleted memory takes its stars and its
/// counts with it (#247).

abstract class _$ProfileStatsController
    extends $AsyncNotifier<ProfileStatsEntity> {
  FutureOr<ProfileStatsEntity> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ProfileStatsEntity>, ProfileStatsEntity>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ProfileStatsEntity>, ProfileStatsEntity>,
              AsyncValue<ProfileStatsEntity>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
