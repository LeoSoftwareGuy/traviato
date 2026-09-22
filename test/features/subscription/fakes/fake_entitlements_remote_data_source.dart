import 'package:traviato/features/subscription/data/datasources/entitlements_remote_data_source.dart';
import 'package:traviato/features/subscription/data/models/entitlement_model.dart';

class FakeEntitlementsRemoteDataSource implements EntitlementsRemoteDataSource {
  /// Successive results returned by [getEntitlement], one per call —
  /// simulates the webhook landing partway through the reconcile loop.
  /// Once exhausted, repeats the last entry.
  List<EntitlementModel> results = [EntitlementModel.free()];
  Object? error;
  var callCount = 0;

  @override
  Future<EntitlementModel> getEntitlement() async {
    if (error != null) throw error!;
    final index = callCount < results.length ? callCount : results.length - 1;
    callCount++;
    return results[index];
  }
}
