import 'package:equatable/equatable.dart';

import '../../../home/domain/entities/profile_stats_entity.dart';
import '../../../subscription/domain/entities/active_subscription_entity.dart';
import '../../../subscription/domain/entities/entitlement_entity.dart';
import '../../../subscription/domain/entities/subscription_offering_entity.dart';
import '../../domain/entities/achievement_entity.dart';
import '../../domain/entities/profile_entity.dart';

class ProfileState extends Equatable {
  const ProfileState({
    required this.profile,
    required this.stats,
    required this.achievements,
    required this.entitlement,
    required this.photosInBusiestMemory,
    this.activeSubscription,
    this.offerings = const [],
  });

  final ProfileEntity profile;
  final ProfileStatsEntity stats;
  final List<AchievementEntity> achievements;

  /// Same read `EntitlementController` (M6-1) exposes everywhere else —
  /// Profile doesn't compute its own tier.
  final EntitlementEntity entitlement;

  /// The photo count of whichever of the caller's memories has the most —
  /// the only one that could ever be at/over the free 40-photo cap, and so
  /// the one meter row on Profile actually has something meaningful to show
  /// for "photos in this memory" (#142's plan comment — Profile has no
  /// single current-memory context).
  final int photosInBusiestMemory;

  /// Live period + management URL for an active Pro subscription. `null`
  /// for a free user, or when the live RevenueCat read failed — the
  /// renewal line degrades to just the date rather than blocking the page.
  final ActiveSubscriptionEntity? activeSubscription;

  /// The store's real, localized plans — same data the paywall (#141)
  /// shows. Used to price both Pro's renewal line (matched by
  /// [activeSubscription]'s period — never assume annual) and Free's
  /// trial-terms line, so neither hardcodes a price. Empty if the fetch
  /// failed; callers just omit the price rather than block the page.
  final List<SubscriptionOfferingEntity> offerings;

  int get earnedCount => achievements.where((a) => a.isEarned).length;

  /// The real price for [period], or `null` if that plan isn't in
  /// [offerings] (a failed/incomplete fetch).
  String? priceFor(SubscriptionPeriod period) {
    for (final offering in offerings) {
      if (offering.period == period) return offering.priceString;
    }
    return null;
  }

  ProfileState copyWith({ProfileEntity? profile}) => ProfileState(
    profile: profile ?? this.profile,
    stats: stats,
    achievements: achievements,
    entitlement: entitlement,
    photosInBusiestMemory: photosInBusiestMemory,
    activeSubscription: activeSubscription,
    offerings: offerings,
  );

  @override
  List<Object?> get props => [
    profile,
    stats,
    achievements,
    entitlement,
    photosInBusiestMemory,
    activeSubscription,
    offerings,
  ];
}
