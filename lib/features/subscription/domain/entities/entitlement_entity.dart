import 'package:equatable/equatable.dart';

enum SubscriptionTier { free, pro }

/// Mirrors the `entitlements` table / `is_pro()` (#137) — the client-side
/// read of the same server-side source of truth. Never trust a locally
/// cached [isPro] for anything that gates a write; those checks run
/// server-side (M6-3).
class EntitlementEntity extends Equatable {
  const EntitlementEntity({
    required this.tier,
    this.revenuecatCustomerId,
    this.expiresAt,
  });

  static const free = EntitlementEntity(tier: SubscriptionTier.free);

  final SubscriptionTier tier;
  final String? revenuecatCustomerId;
  final DateTime? expiresAt;

  /// Same rule as `is_pro()`: pro tier AND (no expiry OR not yet expired).
  bool get isPro =>
      tier == SubscriptionTier.pro &&
      (expiresAt == null || expiresAt!.isAfter(DateTime.now()));

  @override
  List<Object?> get props => [tier, revenuecatCustomerId, expiresAt];
}
