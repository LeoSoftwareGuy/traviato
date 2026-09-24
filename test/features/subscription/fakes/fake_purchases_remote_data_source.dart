import 'package:traviato/features/subscription/data/datasources/purchases_remote_data_source.dart';
import 'package:traviato/features/subscription/data/models/active_subscription_model.dart';
import 'package:traviato/features/subscription/data/models/entitlement_model.dart';
import 'package:traviato/features/subscription/data/models/subscription_offering_model.dart';
import 'package:traviato/features/subscription/domain/entities/subscription_offering_entity.dart';

class FakePurchasesRemoteDataSource implements PurchasesRemoteDataSource {
  List<SubscriptionOfferingModel> offerings = const [];
  EntitlementModel? purchaseResult;
  Object? purchaseError;
  EntitlementModel restoreResult = EntitlementModel.free();
  Object? restoreError;
  ActiveSubscriptionModel activeSubscriptionResult =
      const ActiveSubscriptionModel(
        period: SubscriptionPeriod.annual,
        managementUrl: 'https://apps.apple.com/account/subscriptions',
      );
  Object? activeSubscriptionError;
  var identifyCallCount = 0;
  var resetCallCount = 0;
  var getActiveSubscriptionDetailsCallCount = 0;
  String? lastIdentifiedUserId;

  @override
  Future<void> identify(String userId) async {
    identifyCallCount++;
    lastIdentifiedUserId = userId;
  }

  @override
  Future<void> reset() async {
    resetCallCount++;
  }

  @override
  Future<List<SubscriptionOfferingModel>> getOfferings() async => offerings;

  @override
  Future<EntitlementModel?> purchase(String offeringIdentifier) async {
    if (purchaseError != null) throw purchaseError!;
    return purchaseResult;
  }

  @override
  Future<EntitlementModel> restore() async {
    if (restoreError != null) throw restoreError!;
    return restoreResult;
  }

  @override
  Future<ActiveSubscriptionModel> getActiveSubscriptionDetails() async {
    getActiveSubscriptionDetailsCallCount++;
    if (activeSubscriptionError != null) throw activeSubscriptionError!;
    return activeSubscriptionResult;
  }
}
