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

  /// Initializes RevenueCat with the API key and user ID.
  ///
  /// Call once at app startup (after auth).
  /// [apiKey] should come from environment config, not hardcoded.
  Future<bool> initialize({
    required String apiKey,
    required String userId,
  }) async {
    if (_initialized &&
        _configuredApiKey == apiKey &&
        _configuredUserId == userId) {
      return true;
    }
    if (_initializationFuture != null) {
      return _initializationFuture!;
    }

    final initialization = _initialized && _configuredApiKey == apiKey
        ? _switchUser(userId)
        : _configure(apiKey: apiKey, userId: userId);
    _initializationFuture = initialization;
    final success = await initialization;
    return success;
  }

  Future<bool> _configure({
    required String apiKey,
    required String userId,
  }) async {
    try {
      final maskedKey =
          apiKey.length > 8 ? '${apiKey.substring(0, 8)}...' : '***';
      AppLogger.info('Configuring RevenueCat (key=$maskedKey, user=$userId)');
      final config = PurchasesConfiguration(apiKey)..appUserID = userId;
      await Purchases.configure(config);
      _initialized = true;
      _configuredApiKey = apiKey;
      _configuredUserId = userId;
      _clearStoreUnavailable();
      AppLogger.info('RevenueCat initialized for user: $userId');
      return true;
    } catch (e, st) {
      _clearIdentity();
      AppLogger.error('RevenueCat init failed', e, st);
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
  ///
  /// Tries the "current" (default) offering first. If that is empty, falls
  /// back to the first offering in [Offerings.all] that has packages.
  /// This handles RevenueCat configurations where a current offering is not
  /// explicitly set but named offerings exist.
  Future<List<Package>> getOfferings() async {
    if (!_initialized || _isStoreUnavailableNow()) return [];

    try {
      final offerings = await Purchases.getOfferings();
      _clearStoreUnavailable();

      // Primary: current (default) offering
      final current = offerings.current?.availablePackages ?? [];
      if (current.isNotEmpty) return current;

      // Fallback: first offering with packages from all offerings
      for (final offering in offerings.all.values) {
        if (offering.availablePackages.isNotEmpty) {
          AppLogger.info(
            'No current offering; using "${offering.identifier}" '
            '(${offering.availablePackages.length} packages)',
          );
          return offering.availablePackages;
        }
      }

      AppLogger.warning(
        'RevenueCat returned ${offerings.all.length} offering(s), '
        'none with packages. Current offering: '
        '${offerings.current?.identifier ?? 'null'}',
      );
      return [];
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
        PurchaseErrorCodes.notAllowed,
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
        throw const PurchaseException(PurchaseErrorCodes.notActivated);
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
        PurchaseErrorCodes.notAllowed,
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
      throw const PurchaseException(PurchaseErrorCodes.restoreFailed);
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
      PurchasesErrorCode.storeProblemError =>
        PurchaseErrorCodes.storeProblem,
      PurchasesErrorCode.purchaseNotAllowedError =>
        PurchaseErrorCodes.notAllowed,
      PurchasesErrorCode.productNotAvailableForPurchaseError =>
        PurchaseErrorCodes.productUnavailable,
      PurchasesErrorCode.productAlreadyPurchasedError =>
        PurchaseErrorCodes.alreadyOwned,
      PurchasesErrorCode.paymentPendingError =>
        PurchaseErrorCodes.pending,
      PurchasesErrorCode.networkError ||
      PurchasesErrorCode.offlineConnectionError =>
        PurchaseErrorCodes.networkError,
      PurchasesErrorCode.operationAlreadyInProgressError =>
        PurchaseErrorCodes.inProgress,
      PurchasesErrorCode.configurationError ||
      PurchasesErrorCode.invalidCredentialsError ||
      PurchasesErrorCode.invalidReceiptError ||
      PurchasesErrorCode.missingReceiptFileError ||
      PurchasesErrorCode.receiptAlreadyInUseError ||
      PurchasesErrorCode.receiptInUseByOtherSubscriberError =>
        PurchaseErrorCodes.configurationError,
      _ => PurchaseErrorCodes.genericError,
    };
  }
}

/// Centralized error code constants for purchase operations.
///
/// Used by [PurchaseService], [PurchaseActionNotifier], and premium UI
/// to keep error code strings in sync across layers.
abstract final class PurchaseErrorCodes {
  // Store/platform errors (mapped from RevenueCat)
  static const storeProblem = 'purchase_store_problem';
  static const notAllowed = 'purchase_not_allowed';
  static const productUnavailable = 'purchase_product_unavailable';
  static const alreadyOwned = 'purchase_already_owned';
  static const pending = 'purchase_pending';
  static const networkError = 'purchase_network_error';
  static const inProgress = 'purchase_in_progress';
  static const configurationError = 'purchase_configuration_error';
  static const notActivated = 'purchase_not_activated';
  static const genericError = 'purchase_error';

  // App-level errors
  static const cancelled = 'purchase_cancelled';
  static const noOfferings = 'no_offerings';
  static const packageNotFound = 'package_not_found';
  static const restoreNoPurchases = 'restore_no_purchases';
  static const restoreFailed = 'restore_failed';
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
