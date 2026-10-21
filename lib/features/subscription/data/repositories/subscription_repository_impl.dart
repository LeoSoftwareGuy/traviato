import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/active_subscription_entity.dart';
import '../../domain/entities/entitlement_entity.dart';
import '../../domain/entities/subscription_offering_entity.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/entitlements_remote_data_source.dart';
import '../datasources/purchases_remote_data_source.dart';
import '../models/entitlement_model.dart';

/// How many syncs/reads of `entitlements` to attempt after a purchase/
/// restore, giving the server (sync_entitlement, #267, or the RevenueCat
/// webhook, #138) a short window to confirm before we settle for the SDK's
/// own optimistic read.
const _defaultReconcileAttempts = 3;
const _defaultReconcileDelay = Duration(seconds: 2);

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  SubscriptionRepositoryImpl({
    required PurchasesRemoteDataSource purchases,
    required EntitlementsRemoteDataSource entitlements,
    int reconcileAttempts = _defaultReconcileAttempts,
    Duration reconcileDelay = _defaultReconcileDelay,
  }) : _purchases = purchases,
       _entitlements = entitlements,
       _reconcileAttempts = reconcileAttempts,
       _reconcileDelay = reconcileDelay;

  final PurchasesRemoteDataSource _purchases;
  final EntitlementsRemoteDataSource _entitlements;
  // Overridable only by tests, so the reconcile loop's real-world timing
  // doesn't force a multi-second wait on every purchase/restore test.
  final int _reconcileAttempts;
  final Duration _reconcileDelay;

  @override
  Future<void> syncIdentity(String? userId) async {
    try {
      if (userId == null) {
        await _purchases.reset();
      } else {
        await _purchases.identify(userId);
      }
    } catch (e) {
      // Fire-and-forget from a lifecycle controller with nothing to show a
      // failure to (guidelines doc 03) — log and degrade. A missed identify
      // just means the next purchase attempt (which does surface failures)
      // retries it implicitly via RevenueCat's own cached state.
    }
  }

  @override
  Future<Either<Failure, EntitlementEntity>> getEntitlement() async {
    try {
      return Right(await _entitlements.getEntitlement());
    } on AppException catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, EntitlementEntity>> refreshEntitlement() async {
    try {
      return Right(await _freshEntitlement());
    } on AppException catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, List<SubscriptionOfferingEntity>>>
  getOfferings() async {
    try {
      return Right(await _purchases.getOfferings());
    } on AppException catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, EntitlementEntity?>> purchase(
    String offeringIdentifier,
  ) async {
    try {
      final optimistic = await _purchases.purchase(offeringIdentifier);
      if (optimistic == null) return const Right(null); // cancelled
      return Right(await _reconcile(optimistic));
    } on AppException catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, EntitlementEntity>> restore() async {
    try {
      final optimistic = await _purchases.restore();
      return Right(await _reconcile(optimistic));
    } on AppException catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, ActiveSubscriptionEntity>>
  getActiveSubscriptionDetails() async {
    try {
      return Right(await _purchases.getActiveSubscriptionDetails());
    } on AppException catch (e) {
      return Left(_mapException(e));
    }
  }

  /// Tries a few short-delayed syncs of `entitlements` so the UI reflects
  /// the server-confirmed row as soon as it's repaired; otherwise keeps the
  /// SDK's own optimistic entitlement rather than blocking on it (#138's
  /// plan comment). The first attempt is immediate: sync_entitlement reads
  /// RevenueCat directly instead of waiting on the webhook (#267).
  Future<EntitlementEntity> _reconcile(EntitlementModel optimistic) async {
    for (var attempt = 0; attempt < _reconcileAttempts; attempt++) {
      if (attempt > 0) await Future<void>.delayed(_reconcileDelay);
      try {
        final confirmed = await _freshEntitlement();
        if (confirmed.tier == optimistic.tier) return confirmed;
      } catch (_) {
        // Keep trying/falling back to optimistic — this is a best-effort
        // reconciliation, not the user-facing result of the purchase.
      }
    }
    return optimistic;
  }

  /// The server-repaired row via sync_entitlement (#267). Falls back to a
  /// plain read if the sync itself fails (e.g. the function isn't deployed
  /// yet, or RevenueCat is down) — a stale answer beats none.
  Future<EntitlementModel> _freshEntitlement() async {
    try {
      return await _entitlements.syncEntitlement();
    } on AppException {
      return _entitlements.getEntitlement();
    }
  }

  Failure _mapException(AppException e) => switch (e) {
    AuthenticationException() => AuthenticationFailure(message: e.message),
    PermissionException() => PermissionFailure(message: e.message),
    NetworkException() => const NetworkFailure(),
    ServerException() => ServerFailure(message: e.message),
    _ => UnknownFailure(message: e.message),
  };
}
