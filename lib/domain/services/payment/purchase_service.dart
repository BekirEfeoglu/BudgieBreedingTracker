import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';

/// Wraps RevenueCat for managing premium subscriptions.
///
/// Provides methods for initializing, purchasing, restoring, and
/// querying subscription status. Uses `purchases_flutter` under the hood.
class PurchaseService {
  static const String _entitlementId = 'premium';
  static const Duration _storeUnavailableCooldown = Duration(seconds: 20);

  bool _initialized = false;
  Future<bool>? _initializationFuture;
  String? _configuredApiKey;
  String? _configuredUserId;
  bool _storeUnavailable = false;
  String? _storeUnavailableReason;
  DateTime? _storeUnavailableMarkedAt;

  /// Initializes RevenueCat with the API key and optional user ID.
  ///
  /// Call once at app startup. When [userId] is null or 'anonymous',
  /// RevenueCat creates its own anonymous ID ($RCAnonymousID), allowing
  /// guest users to purchase without signing in (Apple Guideline 5.1.1v).
  Future<bool> initialize({
    required String apiKey,
    String? userId,
  }) async {
    final effectiveUserId = (userId == 'anonymous') ? null : userId;

    if (_initialized &&
        _configuredApiKey == apiKey &&
        _configuredUserId == effectiveUserId) {
      return true;
    }
    if (_initializationFuture != null) {
      return _initializationFuture!;
    }

    final initialization = _initialized && _configuredApiKey == apiKey
        ? (effectiveUserId != null
            ? _switchUser(effectiveUserId)
            : Future.value(true))
        : _configure(apiKey: apiKey, userId: effectiveUserId);
    _initializationFuture = initialization;
    final success = await initialization;
    return success;
  }

  /// Logs in an identified user, merging any anonymous purchases.
  ///
  /// Call after a guest user signs in to transfer their purchases.
  Future<bool> logInIdentifiedUser(String userId) async {
    if (!_initialized) return false;
    return _switchUser(userId);
  }

  Future<bool> _configure({
    required String apiKey,
    String? userId,
  }) async {
    try {
      final config = PurchasesConfiguration(apiKey)..appUserID = userId;
      await Purchases.configure(config);
      _initialized = true;
      _configuredApiKey = apiKey;
      _configuredUserId = userId;
      _clearStoreUnavailable();
      AppLogger.info(
        'RevenueCat initialized for user: ${userId ?? 'anonymous'}',
      );
      return true;
    } catch (e) {
      _clearIdentity();
      AppLogger.error('RevenueCat init failed: $e');
      return false;
    } finally {
      _initializationFuture = null;
    }
  }

  Future<bool> _switchUser(String userId) async {
    try {
      await Purchases.logIn(userId);
      _configuredUserId = userId;
      _clearStoreUnavailable();
      AppLogger.info('RevenueCat switched to user: $userId');
      return true;
    } catch (e) {
      // User switch failed: clear in-memory identity to avoid stale entitlements
      // from the previous user leaking into subsequent checks.
      _clearIdentity();
      AppLogger.error('RevenueCat user switch failed: $e');
      return false;
    } finally {
      _initializationFuture = null;
    }
  }

  /// Returns whether the user currently has an active premium entitlement.
  Future<bool> isPremium() async {
    if (!_initialized || _isStoreUnavailableNow()) return false;

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _clearStoreUnavailable();
      return customerInfo.entitlements.active.containsKey(_entitlementId);
    } on PlatformException catch (e) {
      if (_markStoreUnavailableIfNeeded(e)) {
        return false;
      }
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
  Future<List<Package>> getOfferings() async {
    if (!_initialized || _isStoreUnavailableNow()) return [];

    try {
      final offerings = await Purchases.getOfferings();
      _clearStoreUnavailable();
      return offerings.current?.availablePackages ?? [];
    } on PlatformException catch (e) {
      if (_markStoreUnavailableIfNeeded(e)) {
        return [];
      }
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
    if (!_initialized) return false;
    if (_isStoreUnavailableNow()) {
      throw PurchaseException(
        'purchase_not_allowed',
        purchasesCode: PurchasesErrorCode.purchaseNotAllowedError,
        message: _storeUnavailableReason,
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
        throw const PurchaseException('purchase_not_activated');
      }
      AppLogger.info('Purchase result: premium=$isActive');
      return isActive;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      _markStoreUnavailableIfNeeded(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        AppLogger.info('Purchase cancelled by user');
        return false;
      }

      if (errorCode == PurchasesErrorCode.productAlreadyPurchasedError) {
        AppLogger.warning('Product already purchased, attempting restore');
        try {
          final restored = await restorePurchases();
          if (restored || await isPremium()) {
            return true;
          }
        } on PurchaseException catch (restoreError) {
          AppLogger.warning(
            'Restore after already-owned purchase failed: ${restoreError.code}',
          );
          if (await isPremium()) {
            return true;
          }
        }
      }

      final mappedCode = _mapPurchaseErrorCode(errorCode);
      AppLogger.warning('Purchase error [$mappedCode]: ${e.message ?? e.code}');
      throw PurchaseException(
        mappedCode,
        purchasesCode: errorCode,
        message: e.message,
      );
    }
  }

  /// Restores previous purchases. Returns true if premium is now active.
  ///
  /// Throws [PurchaseException] on restore failures (store/network/config).
  Future<bool> restorePurchases() async {
    if (!_initialized) return false;
    if (_isStoreUnavailableNow()) {
      throw PurchaseException(
        'purchase_not_allowed',
        purchasesCode: PurchasesErrorCode.purchaseNotAllowedError,
        message: _storeUnavailableReason,
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
      _markStoreUnavailableIfNeeded(e);
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      final mappedCode = _mapPurchaseErrorCode(errorCode);
      AppLogger.warning('Restore error [$mappedCode]: ${e.message ?? e.code}');
      throw PurchaseException(
        mappedCode,
        purchasesCode: errorCode,
        message: e.message,
      );
    } catch (e) {
      AppLogger.warning('Restore failed: $e');
      throw const PurchaseException('restore_failed');
    }
  }

  /// Returns detailed subscription info.
  Future<SubscriptionInfo> getSubscriptionInfo() async {
    if (!_initialized || _isStoreUnavailableNow()) {
      return const SubscriptionInfo(isActive: false);
    }

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _clearStoreUnavailable();
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
      if (_markStoreUnavailableIfNeeded(e)) {
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

  /// Logs out the current user from RevenueCat.
  Future<void> logout() async {
    if (!_initialized) return;

    try {
      await Purchases.logOut();
    } catch (e) {
      AppLogger.warning('RevenueCat logout failed: $e');
    } finally {
      _clearIdentity();
    }
  }

  void _clearIdentity() {
    _initialized = false;
    _configuredApiKey = null;
    _configuredUserId = null;
    _clearStoreUnavailable();
  }

  /// Clears temporary store-unavailable guard so callers can retry immediately.
  /// Useful after user fixes sandbox account / Store settings and taps retry.
  void clearStoreUnavailableCache() {
    _clearStoreUnavailable();
  }

  bool _isStoreUnavailableNow() {
    if (!_storeUnavailable) return false;
    final markedAt = _storeUnavailableMarkedAt;
    if (markedAt == null) return true;
    if (DateTime.now().difference(markedAt) < _storeUnavailableCooldown) {
      return true;
    }
    _clearStoreUnavailable();
    return false;
  }

  void _clearStoreUnavailable() {
    _storeUnavailable = false;
    _storeUnavailableReason = null;
    _storeUnavailableMarkedAt = null;
  }

  bool _markStoreUnavailableIfNeeded(PlatformException e) {
    final errorCode = PurchasesErrorHelper.getErrorCode(e);
    final message = (e.message ?? e.code).toUpperCase();
    final unavailable =
        errorCode == PurchasesErrorCode.purchaseNotAllowedError ||
        message.contains('BILLING_UNAVAILABLE') ||
        message.contains('BILLING SERVICE UNAVAILABLE');

    if (!unavailable) return false;

    if (!_storeUnavailable) {
      _storeUnavailable = true;
      _storeUnavailableReason = e.message ?? e.code;
      _storeUnavailableMarkedAt = DateTime.now();
      AppLogger.warning(
        'Billing is unavailable on this device; purchase checks are paused temporarily',
      );
    }
    return true;
  }

  String _mapPurchaseErrorCode(PurchasesErrorCode errorCode) {
    return switch (errorCode) {
      PurchasesErrorCode.storeProblemError => 'purchase_store_problem',
      PurchasesErrorCode.purchaseNotAllowedError => 'purchase_not_allowed',
      PurchasesErrorCode.productNotAvailableForPurchaseError =>
        'purchase_product_unavailable',
      PurchasesErrorCode.productAlreadyPurchasedError =>
        'purchase_already_owned',
      PurchasesErrorCode.paymentPendingError => 'purchase_pending',
      PurchasesErrorCode.networkError ||
      PurchasesErrorCode.offlineConnectionError => 'purchase_network_error',
      PurchasesErrorCode.operationAlreadyInProgressError =>
        'purchase_in_progress',
      PurchasesErrorCode.configurationError ||
      PurchasesErrorCode.invalidCredentialsError ||
      PurchasesErrorCode.invalidReceiptError ||
      PurchasesErrorCode.missingReceiptFileError ||
      PurchasesErrorCode.receiptAlreadyInUseError ||
      PurchasesErrorCode.receiptInUseByOtherSubscriberError =>
        'purchase_configuration_error',
      _ => 'purchase_error',
    };
  }
}

class PurchaseException implements Exception {
  final String code;
  final PurchasesErrorCode? purchasesCode;
  final String? message;

  const PurchaseException(this.code, {this.purchasesCode, this.message});

  @override
  String toString() => message?.isNotEmpty == true ? '$code: $message' : code;
}

/// Immutable subscription status info.
class SubscriptionInfo {
  final bool isActive;
  final DateTime? expirationDate;
  final bool willRenew;
  final String? productId;
  final bool isTrial;

  const SubscriptionInfo({
    required this.isActive,
    this.expirationDate,
    this.willRenew = false,
    this.productId,
    this.isTrial = false,
  });
}
