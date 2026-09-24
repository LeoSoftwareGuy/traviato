import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../../../core/events/global_event.dart';
import '../../../../core/events/global_event_bus.dart';
import '../../../home/presentation/providers/profile_stats_provider.dart';
import '../../../subscription/domain/entities/active_subscription_entity.dart';
import '../../../subscription/domain/entities/subscription_offering_entity.dart';
import '../../../subscription/presentation/controllers/entitlement_controller.dart';
import '../../../subscription/presentation/controllers/offerings_controller.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../../../trip/presentation/providers/trip_providers.dart';
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
    final tripRepo = ref.watch(tripRepositoryProvider);
    final subscriptionRepo = ref.watch(subscriptionRepositoryProvider);

    // Started concurrently — none of these depend on each other. Offerings
    // are fetched regardless of tier: Free's own "7 days free, then
    // $X/year" action-line copy needs a real price too, not just Pro's
    // renewal line (never hardcode either).
    final profileFuture = profileRepo.getProfile();
    final statsFuture = statsRepo.getStats();
    final tripCardsFuture = tripRepo.getTripCards();
    final entitlementFuture = ref.watch(entitlementControllerProvider.future);
    final offeringsFuture = _loadOfferings();

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
    final entitlement = await entitlementFuture;
    final offerings = await offeringsFuture;

    // Which memory has the most photos — the only one that could ever be
    // at/over the free-tier cap (#142's plan comment: Profile has no single
    // current-memory context). A failed read just means "unknown", not a
    // reason to block the whole page — same reasoning as the RevenueCat/
    // offerings reads.
    final photosInBusiestMemory = (await tripCardsFuture).fold(
      (_) => 0,
      (cards) => cards.isEmpty
          ? 0
          : cards.map((c) => c.photoCount).reduce((a, b) => a > b ? a : b),
    );

    // Live period + management URL, Pro only. A failure here is
    // supplementary display, not core profile data worth blocking the page
    // over — the renewal line just falls back to the date alone.
    ActiveSubscriptionEntity? activeSubscription;
    if (entitlement.isPro) {
      activeSubscription =
          (await subscriptionRepo.getActiveSubscriptionDetails()).fold(
            (_) => null,
            (a) => a,
          );
    }

    return ProfileState(
      profile: profile,
      stats: stats,
      achievements: achievements,
      entitlement: entitlement,
      photosInBusiestMemory: photosInBusiestMemory,
      activeSubscription: activeSubscription,
      offerings: offerings,
    );
  }

  Future<List<SubscriptionOfferingEntity>> _loadOfferings() async {
    try {
      return await ref.watch(offeringsControllerProvider.future);
    } catch (_) {
      return const [];
    }
  }

  // A logging action elsewhere (quest check-off, photo add, ...) can move
  // both the stats row and an achievement's progress/earned state — refetch
  // rather than try to reconcile locally, same call the shared stats
  // controller makes on this event.
  void _onEvent(GlobalEvent event) {
    switch (event) {
      case StarsAwardedDispatched():
        ref.invalidateSelf();
      case EntitlementUpdatedDispatched():
      // No explicit action needed: build() does
      // `ref.watch(entitlementControllerProvider.future)`, so this
      // controller already depends on EntitlementController's state and
      // rebuilds on its own once that event updates it — a purchase/restore
      // reached via Profile → paywall leaves this page's provider alive
      // underneath, and it picks up the new tier on pop through that
      // dependency, not a second invalidation here.
      case TripCreatedDispatched():
      case TripDeletedDispatched():
      case TripUpdatedDispatched():
      case WrapUpPublishedDispatched():
      // Not relevant to profile/stats/subscription display.
    }
  }

  /// Called by the edit-sheet mutation after a successful update.
  void applyProfileUpdated(ProfileEntity profile) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(profile: profile));
  }
}
