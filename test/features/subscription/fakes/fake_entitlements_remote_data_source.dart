import 'package:traviato/features/subscription/data/datasources/entitlements_remote_data_source.dart';
import 'package:traviato/features/subscription/data/models/entitlement_model.dart';

class FakeEntitlementsRemoteDataSource implements EntitlementsRemoteDataSource {
  /// Successive results returned by [getEntitlement], one per call —
  /// simulates the webhook landing partway through the reconcile loop.
  /// Once exhausted, repeats the last entry.
  List<EntitlementModel> results = [EntitlementModel.free()];
  Object? error;

  /// Thrown by [syncEntitlement] only — simulates sync_entitlement failing
  /// (not deployed, RevenueCat down) so callers fall back to a plain read.
  Object? syncError;

  /// Counts every row returned, whether by [getEntitlement] or a successful
  /// [syncEntitlement] — both read the same row, so they share [results].
  var callCount = 0;
  var syncCallCount = 0;

  @override
  Future<EntitlementModel> getEntitlement() async {
    if (error != null) throw error!;
    return _next();
  }

  @override
  Future<EntitlementModel> syncEntitlement() async {
    syncCallCount++;
    if (syncError != null) throw syncError!;
    if (error != null) throw error!;
    return _next();
  }

  EntitlementModel _next() {
    final index = callCount < results.length ? callCount : results.length - 1;
    callCount++;
    return results[index];
  }
}
