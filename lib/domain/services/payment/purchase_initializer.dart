import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/domain/services/payment/purchase_error_mapper.dart';

/// RevenueCat SDK initialization and user switching logic.
///
/// Extracted from [PurchaseService] to keep the main service class
/// within the 300-line file limit. Mixed into [PurchaseService].
mixin PurchaseInitializer on PurchaseErrorMapper {
  bool _initialized = false;
  Future<bool>? _initializationFuture;
  String? _configuredApiKey;
  String? _configuredUserId;

  /// Whether RevenueCat has been successfully initialized.
  bool get isInitialized => _initialized;

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
      final maskedKey = apiKey.length > 4
          ? '${apiKey.substring(0, 4)}...'
          : '****';
      AppLogger.info('Configuring RevenueCat (key=$maskedKey, user=$userId)');
      final config = PurchasesConfiguration(apiKey)..appUserID = userId;
      await Purchases.configure(config);
      _initialized = true;
      _configuredApiKey = apiKey;
      _configuredUserId = userId;
      clearStoreUnavailableState();
      AppLogger.info('RevenueCat initialized for user: $userId');
      return true;
    } catch (e, st) {
      clearIdentity();
      AppLogger.error('RevenueCat init failed', e, st);
      Sentry.captureException(e, stackTrace: st);
      return false;
    } finally {
      _initializationFuture = null;
    }
  }

  Future<bool> _switchUser(String userId) async {
    try {
      Sentry.addBreadcrumb(Breadcrumb(
        message: 'PurchaseService: Merging identified user purchases',
        data: {'userId': userId},
        category: 'payment.merge',
        level: SentryLevel.info,
      ));
      await Purchases.logIn(userId);
      _configuredUserId = userId;
      clearStoreUnavailableState();
      Sentry.addBreadcrumb(Breadcrumb(
        message: 'PurchaseService: User merge completed',
        data: {'userId': userId},
        category: 'payment.merge',
        level: SentryLevel.info,
      ));
      AppLogger.info('RevenueCat switched to user: $userId');
      return true;
    } catch (e, st) {
      clearIdentity();
      AppLogger.error('RevenueCat user switch failed: $e');
      Sentry.captureException(e, stackTrace: st);
      return false;
    } finally {
      _initializationFuture = null;
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
      clearIdentity();
    }
  }

  /// Resets all in-memory identity state.
  void clearIdentity() {
    _initialized = false;
    _configuredApiKey = null;
    _configuredUserId = null;
    clearStoreUnavailableState();
  }
}
