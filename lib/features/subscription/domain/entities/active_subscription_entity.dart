import 'package:equatable/equatable.dart';

import 'subscription_offering_entity.dart';

/// Live details about the caller's active Pro subscription — read straight
/// from RevenueCat's SDK (not the `entitlements` table, which only tracks
/// tier/expiry), for the one screen (Profile, #142) that needs to show which
/// plan the user is actually on and let them manage it.
class ActiveSubscriptionEntity extends Equatable {
  const ActiveSubscriptionEntity({
    required this.period,
    required this.managementUrl,
  });

  /// `null` when the active product id doesn't match this app's own
  /// `_monthly`/`_annual` naming convention — display code falls back to a
  /// period-agnostic label rather than guessing.
  final SubscriptionPeriod? period;

  /// RevenueCat's platform-correct deep link to the store's subscription
  /// management page. `null` when RevenueCat has none for this account (e.g.
  /// a manually-granted/promotional entitlement, or no active subscription).
  final String? managementUrl;

  @override
  List<Object?> get props => [period, managementUrl];
}
