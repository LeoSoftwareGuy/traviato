import '../models/entitlement_model.dart';
import '../models/subscription_offering_model.dart';

/// Wraps `purchases_flutter` (RevenueCat) only — the one place that SDK is
/// imported (guidelines doc 04's "only place the SDK is imported" rule,
/// generalized to the second SDK this feature wraps).
abstract interface class PurchasesRemoteDataSource {
  /// Maps the RevenueCat app-user-id to the Supabase user id, so purchases
  /// follow the account across devices. Call on sign-in.
  Future<void> identify(String userId);

  /// Reverts RevenueCat to an anonymous id. Call on sign-out.
  Future<void> reset();

  Future<List<SubscriptionOfferingModel>> getOfferings();

  /// `null` return means the user dismissed the store sheet.
  Future<EntitlementModel?> purchase(String offeringIdentifier);

  Future<EntitlementModel> restore();
}
