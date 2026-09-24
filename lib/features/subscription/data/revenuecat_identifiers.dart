/// RevenueCat dashboard identifiers this app is configured with — the client
/// analog of `core/constants/supabase_constants.dart` for the one third-party
/// SDK this feature wraps. Never hard-code these strings elsewhere.
abstract class RevenueCatIdentifiers {
  /// The single entitlement every product in both stores unlocks (#137/#138).
  static const proEntitlement = 'pro';

  /// This app's own RevenueCat product-id naming convention (e.g.
  /// `traviato_pro_annual`, see the `revenuecat_webhook` test fixtures) —
  /// the only way to tell a live entitlement's billing period apart, since
  /// `EntitlementInfo` carries a product id but not a period (#142).
  static const monthlyProductSuffix = '_monthly';
  static const annualProductSuffix = '_annual';
}
