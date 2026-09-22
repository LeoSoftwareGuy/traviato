import 'package:json_annotation/json_annotation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../domain/entities/entitlement_entity.dart';
import '../revenuecat_identifiers.dart';

part 'entitlement_model.g.dart';

@JsonSerializable(createToJson: false)
class EntitlementModel extends EntitlementEntity {
  const EntitlementModel({
    required super.tier,
    super.revenuecatCustomerId,
    super.expiresAt,
  });

  factory EntitlementModel.fromJson(Map<String, dynamic> json) =>
      _$EntitlementModelFromJson(json);

  factory EntitlementModel.free() =>
      const EntitlementModel(tier: SubscriptionTier.free);

  /// The immediate, optimistic read of a purchase/restore result — built
  /// from RevenueCat's own [CustomerInfo], returned synchronously by the SDK
  /// before the webhook has necessarily reached `entitlements` yet (#138's
  /// plan comment: optimistic-then-confirm).
  factory EntitlementModel.fromCustomerInfo(CustomerInfo info) {
    final active =
        info.entitlements.active[RevenueCatIdentifiers.proEntitlement];
    if (active == null) return EntitlementModel.free();
    return EntitlementModel(
      tier: SubscriptionTier.pro,
      revenuecatCustomerId: info.originalAppUserId,
      expiresAt: active.expirationDate != null
          ? DateTime.parse(active.expirationDate!)
          : null,
    );
  }

  @JsonKey(name: 'tier', fromJson: _tierFromJson)
  @override
  SubscriptionTier get tier;

  @JsonKey(name: 'revenuecat_customer_id')
  @override
  String? get revenuecatCustomerId;

  @JsonKey(name: 'expires_at')
  @override
  DateTime? get expiresAt;
}

SubscriptionTier _tierFromJson(String value) => switch (value) {
  'pro' => SubscriptionTier.pro,
  _ => SubscriptionTier.free,
};
