import 'package:purchases_flutter/purchases_flutter.dart';

import '../../domain/entities/subscription_offering_entity.dart';

/// Built from a RevenueCat [Package], not JSON — the SDK object itself is
/// the source, same non-JSON-factory idiom `UserModel.fromSupabaseUser` uses
/// for the Supabase auth user (guidelines doc 04).
class SubscriptionOfferingModel extends SubscriptionOfferingEntity {
  const SubscriptionOfferingModel({
    required super.identifier,
    required super.period,
    required super.priceString,
  });

  /// `null` for any package type other than monthly/annual — the only two
  /// plans this app sells (docs/design/M6_MONETIZATION_SPEC.md §2).
  static SubscriptionOfferingModel? fromPackage(Package package) {
    final period = switch (package.packageType) {
      PackageType.monthly => SubscriptionPeriod.monthly,
      PackageType.annual => SubscriptionPeriod.annual,
      _ => null,
    };
    if (period == null) return null;
    return SubscriptionOfferingModel(
      identifier: package.identifier,
      period: period,
      priceString: package.storeProduct.priceString,
    );
  }
}
