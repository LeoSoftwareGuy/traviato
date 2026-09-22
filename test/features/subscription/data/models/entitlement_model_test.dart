import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/subscription/data/models/entitlement_model.dart';
import 'package:traviato/features/subscription/domain/entities/entitlement_entity.dart';

void main() {
  group('EntitlementModel.fromJson', () {
    test('maps a free row', () {
      final model = EntitlementModel.fromJson({
        'user_id': 'u1',
        'tier': 'free',
        'revenuecat_customer_id': null,
        'expires_at': null,
        'updated_at': '2026-01-01T00:00:00Z',
      });
      expect(model.tier, SubscriptionTier.free);
      expect(model.isPro, isFalse);
    });

    test('maps a pro row with an expiry', () {
      final model = EntitlementModel.fromJson({
        'user_id': 'u1',
        'tier': 'pro',
        'revenuecat_customer_id': 'rc_123',
        'expires_at': '2099-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      });
      expect(model.tier, SubscriptionTier.pro);
      expect(model.revenuecatCustomerId, 'rc_123');
      expect(model.expiresAt, DateTime.parse('2099-01-01T00:00:00Z'));
      expect(model.isPro, isTrue);
    });

    test('an unrecognized tier string defaults to free (defensive)', () {
      final model = EntitlementModel.fromJson({
        'user_id': 'u1',
        'tier': 'something_unexpected',
        'revenuecat_customer_id': null,
        'expires_at': null,
        'updated_at': '2026-01-01T00:00:00Z',
      });
      expect(model.tier, SubscriptionTier.free);
    });
  });

  test('EntitlementModel.free() is the free tier with no expiry', () {
    final model = EntitlementModel.free();
    expect(model.tier, SubscriptionTier.free);
    expect(model.expiresAt, isNull);
    expect(model.revenuecatCustomerId, isNull);
  });
}
