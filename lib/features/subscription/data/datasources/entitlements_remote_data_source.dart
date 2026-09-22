import '../models/entitlement_model.dart';

/// Wraps `supabase_flutter` only — reads the caller's own row of the
/// `entitlements` table (#137), the durable source of truth.
abstract interface class EntitlementsRemoteDataSource {
  Future<EntitlementModel> getEntitlement();
}
