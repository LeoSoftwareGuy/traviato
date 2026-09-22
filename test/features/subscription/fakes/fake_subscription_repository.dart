import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/subscription/domain/entities/entitlement_entity.dart';
import 'package:traviato/features/subscription/domain/entities/subscription_offering_entity.dart';
import 'package:traviato/features/subscription/domain/repositories/subscription_repository.dart';

/// Test double for [SubscriptionRepository]. Returns the configured result
/// (defaulting to free/empty) and records how many times each method was
/// called, mirroring `FakeTripRepository`.
class FakeSubscriptionRepository implements SubscriptionRepository {
  Either<Failure, EntitlementEntity>? entitlementResult;
  Either<Failure, List<SubscriptionOfferingEntity>>? offeringsResult;
  Either<Failure, EntitlementEntity?>? purchaseResult;
  Either<Failure, EntitlementEntity>? restoreResult;

  var getEntitlementCallCount = 0;
  var getOfferingsCallCount = 0;
  var purchaseCallCount = 0;
  var restoreCallCount = 0;
  var syncIdentityCallCount = 0;
  String? lastPurchasedOfferingIdentifier;
  String? lastSyncedUserId;
  var lastSyncCalledWithNull = false;

  @override
  Future<void> syncIdentity(String? userId) async {
    syncIdentityCallCount++;
    lastSyncedUserId = userId;
    lastSyncCalledWithNull = userId == null;
  }

  @override
  Future<Either<Failure, EntitlementEntity>> getEntitlement() async {
    getEntitlementCallCount++;
    return entitlementResult ?? const Right(EntitlementEntity.free);
  }

  @override
  Future<Either<Failure, List<SubscriptionOfferingEntity>>>
  getOfferings() async {
    getOfferingsCallCount++;
    return offeringsResult ?? const Right([]);
  }

  @override
  Future<Either<Failure, EntitlementEntity?>> purchase(
    String offeringIdentifier,
  ) async {
    purchaseCallCount++;
    lastPurchasedOfferingIdentifier = offeringIdentifier;
    return purchaseResult ?? const Right(null);
  }

  @override
  Future<Either<Failure, EntitlementEntity>> restore() async {
    restoreCallCount++;
    return restoreResult ?? const Right(EntitlementEntity.free);
  }
}

EntitlementEntity buildProEntitlement({
  DateTime? expiresAt,
  String revenuecatCustomerId = 'u1',
}) => EntitlementEntity(
  tier: SubscriptionTier.pro,
  revenuecatCustomerId: revenuecatCustomerId,
  expiresAt: expiresAt ?? DateTime.now().add(const Duration(days: 365)),
);

SubscriptionOfferingEntity buildOffering({
  String identifier = r'$rc_annual',
  SubscriptionPeriod period = SubscriptionPeriod.annual,
  String priceString = r'$44.99',
}) => SubscriptionOfferingEntity(
  identifier: identifier,
  period: period,
  priceString: priceString,
);
