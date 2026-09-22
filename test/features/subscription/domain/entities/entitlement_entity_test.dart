import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/subscription/domain/entities/entitlement_entity.dart';

void main() {
  group('EntitlementEntity.isPro', () {
    test('is false for the free tier', () {
      expect(EntitlementEntity.free.isPro, isFalse);
    });

    test('is true for pro with no expiry (lifetime)', () {
      const entitlement = EntitlementEntity(tier: SubscriptionTier.pro);
      expect(entitlement.isPro, isTrue);
    });

    test('is true for pro with a future expiry', () {
      final entitlement = EntitlementEntity(
        tier: SubscriptionTier.pro,
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );
      expect(entitlement.isPro, isTrue);
    });

    test('is false for pro with a past expiry — lapsed reads as free', () {
      final entitlement = EntitlementEntity(
        tier: SubscriptionTier.pro,
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(entitlement.isPro, isFalse);
    });
  });
}
