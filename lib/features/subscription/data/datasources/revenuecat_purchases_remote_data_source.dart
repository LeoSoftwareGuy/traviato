import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/active_subscription_model.dart';
import '../models/entitlement_model.dart';
import '../models/subscription_offering_model.dart';
import 'purchases_remote_data_source.dart';

/// RevenueCat-backed purchases. [isConfigured] says whether
/// `Purchases.configure` actually ran this session (`main.dart` skips it
/// when the platform's API key is missing from `.env`). Every SDK call is
/// guarded by it: an unconfigured RevenueCat SDK hits a native fatal error
/// (on iOS a Swift `fatalError`) that Dart cannot catch, so the call must
/// never be made at all (#156).
class RevenueCatPurchasesRemoteDataSource implements PurchasesRemoteDataSource {
  RevenueCatPurchasesRemoteDataSource({required bool isConfigured})
    : _isConfigured = isConfigured;

  final bool _isConfigured;

  /// What the store-facing calls throw when RevenueCat isn't set up — a
  /// normal typed failure the paywall/Profile already know how to show.
  static const unavailable = ServerException(
    message: "Purchases aren't available right now. Please try again later.",
  );

  void _requireConfigured() {
    if (!_isConfigured) throw unavailable;
  }

  @override
  Future<void> identify(String userId) async {
    // Identity sync is fire-and-forget on every auth change — with no store
    // configured there's no identity to keep in step, so it's a no-op.
    if (!_isConfigured) {
      debugPrint('RevenueCat not configured — skipping identify.');
      return;
    }
    try {
      await Purchases.logIn(userId);
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  @override
  Future<void> reset() async {
    // Runs on every sign-out: logout must always succeed, store or not.
    if (!_isConfigured) {
      debugPrint('RevenueCat not configured — skipping reset.');
      return;
    }
    try {
      await Purchases.logOut();
    } on PlatformException catch (e) {
      // Already anonymous is a safe no-op, not an error worth surfacing.
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.logOutWithAnonymousUserError) {
        return;
      }
      throw _mapPlatformException(e);
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  @override
  Future<List<SubscriptionOfferingModel>> getOfferings() async {
    _requireConfigured();
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) return const [];
      return current.availablePackages
          .map(SubscriptionOfferingModel.fromPackage)
          .whereType<SubscriptionOfferingModel>()
          .toList();
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  @override
  Future<EntitlementModel?> purchase(String offeringIdentifier) async {
    _requireConfigured();
    try {
      final offerings = await Purchases.getOfferings();
      final package = offerings.current?.availablePackages.firstWhereOrNull(
        (p) => p.identifier == offeringIdentifier,
      );
      if (package == null) {
        throw const ServerException(
          message: 'Selected plan is no longer available.',
        );
      }
      final result = await Purchases.purchase(PurchaseParams.package(package));
      return EntitlementModel.fromCustomerInfo(result.customerInfo);
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError) {
        return null;
      }
      throw _mapPlatformException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  @override
  Future<EntitlementModel> restore() async {
    _requireConfigured();
    try {
      final info = await Purchases.restorePurchases();
      return EntitlementModel.fromCustomerInfo(info);
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  @override
  Future<ActiveSubscriptionModel> getActiveSubscriptionDetails() async {
    _requireConfigured();
    try {
      final info = await Purchases.getCustomerInfo();
      return ActiveSubscriptionModel.fromCustomerInfo(info);
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  AppException _mapPlatformException(PlatformException e) {
    final code = PurchasesErrorHelper.getErrorCode(e);
    switch (code) {
      case PurchasesErrorCode.networkError:
      case PurchasesErrorCode.offlineConnectionError:
        return const NetworkException();
      case PurchasesErrorCode.purchaseNotAllowedError:
      case PurchasesErrorCode.invalidCredentialsError:
      case PurchasesErrorCode.insufficientPermissionsError:
        return PermissionException(
          message: e.message ?? 'Purchases are not allowed on this account.',
        );
      default:
        return ServerException(message: e.message ?? code.name);
    }
  }
}
