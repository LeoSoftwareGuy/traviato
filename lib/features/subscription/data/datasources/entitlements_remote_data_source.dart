import '../models/entitlement_model.dart';

/// Wraps `supabase_flutter` only — reads the caller's own row of the
/// `entitlements` table (#137), the durable source of truth.
abstract interface class EntitlementsRemoteDataSource {
  Future<EntitlementModel> getEntitlement();

  /// Asks `sync_entitlement` (#267) to pull the caller's live state from
  /// RevenueCat and repair the row if it's stale, then returns the row.
  Future<EntitlementModel> syncEntitlement();
}
