import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/active_subscription_model.dart';
import '../models/entitlement_model.dart';
import '../models/subscription_offering_model.dart';
import 'purchases_remote_data_source.dart';

class RevenueCatPurchasesRemoteDataSource implements PurchasesRemoteDataSource {
  @override
  Future<void> identify(String userId) async {
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
