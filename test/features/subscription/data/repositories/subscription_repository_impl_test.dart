import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/exceptions.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/subscription/data/models/entitlement_model.dart';
import 'package:traviato/features/subscription/data/repositories/subscription_repository_impl.dart';
import 'package:traviato/features/subscription/domain/entities/entitlement_entity.dart';

import '../../fakes/fake_entitlements_remote_data_source.dart';
import '../../fakes/fake_purchases_remote_data_source.dart';

SubscriptionRepositoryImpl _buildRepo({
  required FakePurchasesRemoteDataSource purchases,
  required FakeEntitlementsRemoteDataSource entitlements,
}) => SubscriptionRepositoryImpl(
  purchases: purchases,
  entitlements: entitlements,
  // Zero delay: the reconcile loop's real-world pacing isn't under test.
  reconcileDelay: Duration.zero,
);

void main() {
  group('purchase', () {
    test('returns Right(null) when the user cancels', () async {
      final purchases = FakePurchasesRemoteDataSource()..purchaseResult = null;
      final entitlements = FakeEntitlementsRemoteDataSource();
      final repo = _buildRepo(purchases: purchases, entitlements: entitlements);

      final result = await repo.purchase(r'$rc_annual');

      expect(result, const Right<Failure, EntitlementEntity?>(null));
      expect(entitlements.callCount, 0); // never reconciles a cancellation
    });

    test(
      'reconciles with entitlements once the webhook-written tier matches',
      () async {
        final optimistic = EntitlementModel(
          tier: SubscriptionTier.pro,
          expiresAt: DateTime(2099),
        );
        final confirmed = EntitlementModel(
          tier: SubscriptionTier.pro,
          revenuecatCustomerId: 'rc_1',
          expiresAt: DateTime(2099),
        );
        final purchases = FakePurchasesRemoteDataSource()
          ..purchaseResult = optimistic;
        final entitlements = FakeEntitlementsRemoteDataSource()
          ..results = [EntitlementModel.free(), confirmed];
        final repo = _buildRepo(
          purchases: purchases,
          entitlements: entitlements,
        );

        final result = await repo.purchase(r'$rc_annual');

        expect(result, Right<Failure, EntitlementEntity?>(confirmed));
        expect(entitlements.callCount, 2);
      },
    );

    test(
      'falls back to the optimistic entitlement if entitlements never '
      'catches up',
      () async {
        final optimistic = EntitlementModel(
          tier: SubscriptionTier.pro,
          expiresAt: DateTime(2099),
        );
        final purchases = FakePurchasesRemoteDataSource()
          ..purchaseResult = optimistic;
        final entitlements = FakeEntitlementsRemoteDataSource()
          ..results = [EntitlementModel.free()]; // stays free every read
        final repo = _buildRepo(
          purchases: purchases,
          entitlements: entitlements,
        );

        final result = await repo.purchase(r'$rc_annual');

        expect(result, Right<Failure, EntitlementEntity?>(optimistic));
        expect(entitlements.callCount, 3); // exhausted all attempts
      },
    );

    test('maps a network exception to NetworkFailure', () async {
      final purchases = FakePurchasesRemoteDataSource()
        ..purchaseError = const NetworkException();
      final repo = _buildRepo(
        purchases: purchases,
        entitlements: FakeEntitlementsRemoteDataSource(),
      );

      final result = await repo.purchase(r'$rc_annual');

      expect(result, const Left<Failure, EntitlementEntity?>(NetworkFailure()));
    });
  });

  group('restore', () {
    test('reconciles like purchase', () async {
      final confirmed = EntitlementModel(
        tier: SubscriptionTier.pro,
        expiresAt: DateTime(2099),
      );
      final purchases = FakePurchasesRemoteDataSource()
        ..restoreResult = EntitlementModel(
          tier: SubscriptionTier.pro,
          expiresAt: DateTime(2099),
        );
      final entitlements = FakeEntitlementsRemoteDataSource()
        ..results = [confirmed];
      final repo = _buildRepo(purchases: purchases, entitlements: entitlements);

      final result = await repo.restore();

      expect(result, Right<Failure, EntitlementEntity>(confirmed));
    });

    test('a free restore (nothing to restore) is not a failure', () async {
      final purchases = FakePurchasesRemoteDataSource()
        ..restoreResult = EntitlementModel.free();
      final entitlements = FakeEntitlementsRemoteDataSource();
      final repo = _buildRepo(purchases: purchases, entitlements: entitlements);

      final result = await repo.restore();

      // Equatable distinguishes EntitlementModel from EntitlementEntity by
      // runtimeType, so compare against the Model the fake actually returns.
      expect(
        result,
        Right<Failure, EntitlementEntity>(EntitlementModel.free()),
      );
    });
  });

  group('syncIdentity', () {
    test('identifies with the given user id', () async {
      final purchases = FakePurchasesRemoteDataSource();
      final repo = _buildRepo(
        purchases: purchases,
        entitlements: FakeEntitlementsRemoteDataSource(),
      );

      await repo.syncIdentity('u1');

      expect(purchases.identifyCallCount, 1);
      expect(purchases.lastIdentifiedUserId, 'u1');
      expect(purchases.resetCallCount, 0);
    });

    test('resets on null (sign-out)', () async {
      final purchases = FakePurchasesRemoteDataSource();
      final repo = _buildRepo(
        purchases: purchases,
        entitlements: FakeEntitlementsRemoteDataSource(),
      );

      await repo.syncIdentity(null);

      expect(purchases.resetCallCount, 1);
      expect(purchases.identifyCallCount, 0);
    });

    test('swallows a failure rather than throwing (fire-and-forget)', () async {
      // identify() itself doesn't support injected errors in the fake, so
      // exercise the swallow path via a data source that throws.
      final repo = _buildRepo(
        purchases: _ThrowingIdentifyDataSource(),
        entitlements: FakeEntitlementsRemoteDataSource(),
      );

      await expectLater(repo.syncIdentity('u1'), completes);
    });
  });
}

class _ThrowingIdentifyDataSource extends FakePurchasesRemoteDataSource {
  @override
  Future<void> identify(String userId) async {
    throw const UnknownException();
  }
}
