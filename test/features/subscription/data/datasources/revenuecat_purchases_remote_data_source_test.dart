import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/errors/exceptions.dart';
import 'package:traviato/features/subscription/data/datasources/revenuecat_api_key.dart';
import 'package:traviato/features/subscription/data/datasources/revenuecat_purchases_remote_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('revenueCatApiKey', () {
    test('no keys in .env means RevenueCat stays unconfigured', () {
      for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
        expect(
          revenueCatApiKey(platform: platform, env: const {}),
          isNull,
          reason: platform.name,
        );
      }
    });

    test('an empty key counts as missing', () {
      expect(
        revenueCatApiKey(
          platform: TargetPlatform.iOS,
          env: const {'REVENUECAT_IOS_API_KEY': ''},
        ),
        isNull,
      );
    });

    test('picks the key for the running platform', () {
      const env = {
        'REVENUECAT_IOS_API_KEY': 'appl_x',
        'REVENUECAT_ANDROID_API_KEY': 'goog_y',
      };
      expect(
        revenueCatApiKey(platform: TargetPlatform.iOS, env: env),
        'appl_x',
      );
      expect(
        revenueCatApiKey(platform: TargetPlatform.android, env: env),
        'goog_y',
      );
    });
  });

  // No RevenueCat platform channel is registered in unit tests, so any call
  // that actually reached the SDK would throw (MissingPluginException).
  // Completing cleanly therefore proves the guard kept us out of the SDK —
  // the call that, unguarded, is a native fatal error on iOS (#156).
  group('RevenueCatPurchasesRemoteDataSource when not configured', () {
    final source = RevenueCatPurchasesRemoteDataSource(isConfigured: false);

    test('logout sync (reset) succeeds without touching the SDK', () async {
      await expectLater(source.reset(), completes);
    });

    test('login sync (identify) is a no-op too', () async {
      await expectLater(source.identify('user-1'), completes);
    });

    test('store calls fail with a normal typed error, never the SDK', () async {
      final calls = <String, Future<Object?> Function()>{
        'getOfferings': source.getOfferings,
        'purchase': () => source.purchase('monthly'),
        'restore': source.restore,
        'getActiveSubscriptionDetails': source.getActiveSubscriptionDetails,
      };
      for (final MapEntry(key: name, value: call) in calls.entries) {
        await expectLater(
          call(),
          throwsA(
            isA<ServerException>().having(
              (e) => e.message,
              'message',
              RevenueCatPurchasesRemoteDataSource.unavailable.message,
            ),
          ),
          reason: name,
        );
      }
    });
  });

  test('when configured, calls do go to the SDK (guard is not a blanket '
      'no-op)', () async {
    final source = RevenueCatPurchasesRemoteDataSource(isConfigured: true);
    // Reaches the (absent) platform channel, which surfaces as an error —
    // the opposite of the unconfigured path above.
    await expectLater(source.reset(), throwsA(anything));
  });
}
