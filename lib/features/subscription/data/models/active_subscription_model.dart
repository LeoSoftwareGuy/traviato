import 'package:purchases_flutter/purchases_flutter.dart';

import '../../domain/entities/active_subscription_entity.dart';
import '../../domain/entities/subscription_offering_entity.dart';
import '../revenuecat_identifiers.dart';

/// Built from RevenueCat's own [CustomerInfo] (a live SDK call), not JSON —
/// same non-JSON-factory idiom as [SubscriptionOfferingModel] (#142).
class ActiveSubscriptionModel extends ActiveSubscriptionEntity {
  const ActiveSubscriptionModel({
    required super.period,
    required super.managementUrl,
  });

  factory ActiveSubscriptionModel.fromCustomerInfo(CustomerInfo info) {
    final active =
        info.entitlements.active[RevenueCatIdentifiers.proEntitlement];
    return ActiveSubscriptionModel(
      period: _periodFromProductId(active?.productIdentifier),
      managementUrl: info.managementURL,
    );
  }

  static SubscriptionPeriod? _periodFromProductId(String? productId) {
    if (productId == null) return null;
    if (productId.endsWith(RevenueCatIdentifiers.annualProductSuffix)) {
      return SubscriptionPeriod.annual;
    }
    if (productId.endsWith(RevenueCatIdentifiers.monthlyProductSuffix)) {
      return SubscriptionPeriod.monthly;
    }
    return null;
  }
}
