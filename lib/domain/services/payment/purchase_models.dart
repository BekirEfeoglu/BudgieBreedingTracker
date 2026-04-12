import 'package:purchases_flutter/purchases_flutter.dart';

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

/// Exception thrown by purchase operations.
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
