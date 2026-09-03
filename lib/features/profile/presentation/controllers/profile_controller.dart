import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../../../core/events/global_event.dart';
import '../../../../core/events/global_event_bus.dart';
import '../../../home/presentation/providers/profile_stats_provider.dart';
import '../../domain/entities/profile_entity.dart';
import '../providers/profile_providers.dart';
import 'profile_state.dart';

part 'profile_controller.g.dart';

@riverpod
class ProfileController extends _$ProfileController {
  @override
  Future<ProfileState> build() async {
    final sub = ref.watch(globalEventBusProvider).stream.listen(_onEvent);
    ref.onDispose(sub.cancel);

    final profileRepo = ref.watch(profileRepositoryProvider);
    final statsRepo = ref.watch(profileStatsRepositoryProvider);

    // Started concurrently — the profile row and the stats aggregate don't
    // depend on each other.
    final profileFuture = profileRepo.getProfile();
    final statsFuture = statsRepo.getStats();

    final profile = (await profileFuture).fold(
      (failure) => throw PresentationFailureException(failure),
      (p) => p,
    );
    final stats = (await statsFuture).fold(
      (failure) => throw PresentationFailureException(failure),
      (s) => s,
    );
    final achievements = (await profileRepo.getAchievements(stats)).fold(
      (failure) => throw PresentationFailureException(failure),
      (a) => a,
    );

    return ProfileState(
      profile: profile,
      stats: stats,
      achievements: achievements,
    );
  }

  // A logging action elsewhere (quest check-off, photo add, ...) can move
  // both the stats row and an achievement's progress/earned state — refetch
  // rather than try to reconcile locally, same call the shared stats
  // controller makes on this event.
  void _onEvent(GlobalEvent event) {
    if (event is StarsAwardedDispatched) ref.invalidateSelf();
  }

  /// Called by the edit-sheet mutation after a successful update.
  void applyProfileUpdated(ProfileEntity profile) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(profile: profile));
  }
}
