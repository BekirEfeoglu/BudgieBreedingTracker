import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart' hide SubscriptionInfo;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/domain/services/payment/purchase_error_mapper.dart';
import 'package:budgie_breeding_tracker/domain/services/payment/purchase_initializer.dart';
import 'package:budgie_breeding_tracker/domain/services/payment/purchase_models.dart';

export 'package:budgie_breeding_tracker/domain/services/payment/purchase_models.dart';

/// Wraps RevenueCat for managing premium subscriptions.
///
/// Provides methods for initializing, purchasing, restoring, and
/// querying subscription status. Uses `purchases_flutter` under the hood.
class PurchaseService with PurchaseErrorMapper, PurchaseInitializer {
  static const String _entitlementId = 'premium';

  /// Returns whether the user currently has an active premium entitlement.
  Future<bool> isPremium() async {
    if (!isInitialized || isStoreUnavailableNow()) return false;

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      clearStoreUnavailableState();
      return customerInfo.entitlements.active.containsKey(_entitlementId);
    } on PlatformException catch (e) {
      if (markStoreUnavailableIfNeeded(e)) return false;
      AppLogger.warning(
        'Failed to check premium status: ${e.message ?? e.code}',
      );
      return false;
    } catch (e) {
      AppLogger.warning('Failed to check premium status: $e');
      return false;
    }
  }

  /// Fetches all available subscription offerings.
  ///
  /// Tries the "current" (default) offering first. If that is empty, falls
  /// back to the unique packages across [Offerings.all].
  Future<List<Package>> getOfferings() async {
    if (!isInitialized || isStoreUnavailableNow()) return [];

    try {
      final offerings = await Purchases.getOfferings();
      clearStoreUnavailableState();

      // Primary: current (default) offering
      final current = offerings.current?.availablePackages ?? [];
      if (current.isNotEmpty) return current;

      // Fallback: collect every available package instead of trusting map
      // order. A stale/legacy offering may be returned before the active
      // premium offering when RevenueCat has no current offering configured.
      final fallbackPackages = <Package>[];
      final seenPackages = <String>{};
      for (final offering in offerings.all.values) {
        for (final package in offering.availablePackages) {
          final packageKey =
              '${package.identifier}\u0000${package.storeProduct.identifier}';
          if (seenPackages.add(packageKey)) {
            fallbackPackages.add(package);
          }
        }
      }
      if (fallbackPackages.isNotEmpty) {
        AppLogger.info(
          'No current offering; using ${fallbackPackages.length} unique '
          'package(s) from ${offerings.all.length} offering(s)',
        );
        return fallbackPackages;
      }

      AppLogger.warning(
        'RevenueCat returned ${offerings.all.length} offering(s), '
        'none with packages. Current offering: '
        '${offerings.current?.identifier ?? 'null'}',
      );
      return [];
    } on PlatformException catch (e) {
      if (markStoreUnavailableIfNeeded(e)) return [];
      AppLogger.warning('Failed to get offerings: ${e.message ?? e.code}');
      return [];
    } catch (e) {
      AppLogger.warning('Failed to get offerings: $e');
      return [];
    }
  }

  /// Purchases a package by its identifier.
  ///
  /// Returns true if purchase succeeded.
  Future<bool> purchasePackage(Package package) async {
    if (!isInitialized) return false;
    if (isStoreUnavailableNow()) {
      throw PurchaseException(
        PurchaseErrorCodes.notAllowed,
        purchasesCode: PurchasesErrorCode.purchaseNotAllowedError,
        message: storeUnavailableReason,
      );
    }

    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      final isActive = result.customerInfo.entitlements.active.containsKey(
        _entitlementId,
      );
      if (!isActive) {
        AppLogger.warning(
          'Purchase completed but premium entitlement is still inactive',
        );
        throw const PurchaseException(PurchaseErrorCodes.notActivated);
      }
      AppLogger.info('Purchase result: premium=$isActive');
      return isActive;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      markStoreUnavailableIfNeeded(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        AppLogger.info('Purchase cancelled by user');
        return false;
      }

      if (errorCode == PurchasesErrorCode.productAlreadyPurchasedError) {
        return _handleAlreadyPurchased();
      }

      final mappedCode = mapPurchaseErrorCode(errorCode);
      AppLogger.warning('Purchase error [$mappedCode]: ${e.message ?? e.code}');
      Sentry.captureException(e, stackTrace: StackTrace.current);
      throw PurchaseException(
        mappedCode,
        purchasesCode: errorCode,
        message: e.message,
      );
    } on PurchaseException {
      rethrow;
    } catch (e, st) {
      AppLogger.error('Unexpected purchase error', e, st);
      Sentry.captureException(e, stackTrace: st);
      throw PurchaseException(
        PurchaseErrorCodes.genericError,
        message: e.toString(),
      );
    }
  }

  Future<bool> _handleAlreadyPurchased() async {
    AppLogger.warning('Product already purchased, attempting restore');
    try {
      final restored = await restorePurchases();
      if (restored || await isPremium()) return true;
    } on PurchaseException catch (restoreError) {
      AppLogger.warning(
        'Restore after already-owned purchase failed: ${restoreError.code}',
      );
      if (await isPremium()) return true;
    }
    return false;
  }

  /// Restores previous purchases. Returns true if premium is now active.
  ///
  /// Throws [PurchaseException] on restore failures (store/network/config).
  Future<bool> restorePurchases() async {
    if (!isInitialized) return false;
    if (isStoreUnavailableNow()) {
      throw PurchaseException(
        PurchaseErrorCodes.notAllowed,
        purchasesCode: PurchasesErrorCode.purchaseNotAllowedError,
        message: storeUnavailableReason,
      );
    }

    try {
      final customerInfo = await Purchases.restorePurchases();
      final isActive = customerInfo.entitlements.active.containsKey(
        _entitlementId,
      );
      AppLogger.info('Restore result: premium=$isActive');
      return isActive;
    } on PlatformException catch (e) {
      markStoreUnavailableIfNeeded(e);
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      final mappedCode = mapPurchaseErrorCode(errorCode);
      AppLogger.warning('Restore error [$mappedCode]: ${e.message ?? e.code}');
      Sentry.captureException(e, stackTrace: StackTrace.current);
      throw PurchaseException(
        mappedCode,
        purchasesCode: errorCode,
        message: e.message,
      );
    } catch (e, st) {
      AppLogger.warning('Restore failed: $e');
      Sentry.captureException(e, stackTrace: st);
      throw const PurchaseException(PurchaseErrorCodes.restoreFailed);
    }
  }

  /// Returns detailed subscription info.
  Future<SubscriptionInfo> getSubscriptionInfo() async {
    if (!isInitialized || isStoreUnavailableNow()) {
      return const SubscriptionInfo(isActive: false);
    }

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      clearStoreUnavailableState();
      final entitlement = customerInfo.entitlements.active[_entitlementId];

      return SubscriptionInfo(
        isActive: entitlement != null,
        expirationDate: entitlement?.expirationDate != null
            ? DateTime.tryParse(entitlement!.expirationDate!)
            : null,
        willRenew: entitlement?.willRenew ?? false,
        productId: entitlement?.productIdentifier,
        isTrial: entitlement?.periodType == PeriodType.trial,
      );
    } on PlatformException catch (e) {
      if (markStoreUnavailableIfNeeded(e)) {
        return const SubscriptionInfo(isActive: false);
      }
      AppLogger.warning(
        'Failed to get subscription info: ${e.message ?? e.code}',
      );
      return const SubscriptionInfo(isActive: false);
    } catch (e) {
      AppLogger.warning('Failed to get subscription info: $e');
      return const SubscriptionInfo(isActive: false);
    }
  }

  /// Clears temporary store-unavailable guard so callers can retry immediately.
  void clearStoreUnavailableCache() {
    clearStoreUnavailableState();
  }
}
