import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/entitlement_entity.dart';
import '../entities/subscription_offering_entity.dart';

abstract interface class SubscriptionRepository {
  /// Identifies (or signs out) the RevenueCat user so purchases map to the
  /// right Supabase account across devices. Call with the Supabase user id
  /// on sign-in, `null` on sign-out.
  Future<void> syncIdentity(String? userId);

  /// The caller's own `entitlements` row — the durable source of truth.
  Future<Either<Failure, EntitlementEntity>> getEntitlement();

  /// The store's available plans (monthly/annual), already localized.
  Future<Either<Failure, List<SubscriptionOfferingEntity>>> getOfferings();

  /// [offeringIdentifier] is [SubscriptionOfferingEntity.identifier] —
  /// opaque to callers, just passed back. `Right(null)` means the user
  /// dismissed the store sheet without buying — not a failure, same idiom as
  /// social sign-in's cancel handling. A non-null [EntitlementEntity] is
  /// built optimistically from the store's own purchase confirmation and
  /// reconciled against `entitlements` before being returned (see #138's
  /// plan comment).
  Future<Either<Failure, EntitlementEntity?>> purchase(
    String offeringIdentifier,
  );

  /// Always resolves to the caller's post-restore entitlement — a restore
  /// that finds nothing to restore is not a failure, just a free result.
  Future<Either<Failure, EntitlementEntity>> restore();
}
