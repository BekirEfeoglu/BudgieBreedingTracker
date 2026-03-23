import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/domain/services/payment/purchase_models.dart';

/// Store availability tracking and RevenueCat error code mapping.
///
/// Extracted from [PurchaseService] to keep the main service class
/// within the 300-line file limit. Mixed into [PurchaseService].
mixin PurchaseErrorMapper {
  static const Duration _storeUnavailableCooldown = Duration(seconds: 20);

  bool _storeUnavailable = false;
  String? _storeUnavailableReason;
  DateTime? _storeUnavailableMarkedAt;

  /// Whether the store is currently marked as unavailable.
  ///
  /// Returns `true` during the cooldown period after a billing error.
  bool isStoreUnavailableNow() {
    if (!_storeUnavailable) return false;
    final markedAt = _storeUnavailableMarkedAt;
    if (markedAt == null) return true;
    if (DateTime.now().difference(markedAt) < _storeUnavailableCooldown) {
      return true;
    }
    clearStoreUnavailableState();
    return false;
  }

  /// The reason the store was marked unavailable, if any.
  String? get storeUnavailableReason => _storeUnavailableReason;

  /// Clears temporary store-unavailable guard so callers can retry immediately.
  /// Useful after user fixes sandbox account / Store settings and taps retry.
  void clearStoreUnavailableState() {
    _storeUnavailable = false;
    _storeUnavailableReason = null;
    _storeUnavailableMarkedAt = null;
  }

  /// Checks if the error indicates the store/billing is unavailable
  /// and marks the service accordingly.
  ///
  /// Returns `true` if the error was a store-unavailable error.
  bool markStoreUnavailableIfNeeded(PlatformException e) {
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

  /// Maps a RevenueCat error code to a domain-specific error code string.
  String mapPurchaseErrorCode(PurchasesErrorCode errorCode) {
    return switch (errorCode) {
      PurchasesErrorCode.storeProblemError => PurchaseErrorCodes.storeProblem,
      PurchasesErrorCode.purchaseNotAllowedError =>
        PurchaseErrorCodes.notAllowed,
      PurchasesErrorCode.productNotAvailableForPurchaseError =>
        PurchaseErrorCodes.productUnavailable,
      PurchasesErrorCode.productAlreadyPurchasedError =>
        PurchaseErrorCodes.alreadyOwned,
      PurchasesErrorCode.paymentPendingError => PurchaseErrorCodes.pending,
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
