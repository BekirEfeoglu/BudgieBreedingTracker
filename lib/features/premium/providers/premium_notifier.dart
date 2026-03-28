part of 'premium_providers.dart';

/// Notifier that manages premium subscription state with persistence
/// and RevenueCat integration.
class PremiumNotifier extends Notifier<bool> {
  int _loadSequence = 0;

  @override
  bool build() {
    final userId = ref.watch(currentUserIdProvider);
    _load(userId, ++_loadSequence);
    return false;
  }

  static String _cacheKey(String userId) => 'is_premium_$userId';
  static const int _maxSyncRetries = 3;
  static String _pendingSyncKey(String userId) => 'pending_premium_sync_$userId';

  Future<void> _load(String userId, int loadToken) async {
    final prefs = await SharedPreferences.getInstance();
    if (!_isLatestLoad(loadToken)) return;

    if (userId == 'anonymous') {
      state = false;
      try {
        await ref.read(purchaseServiceProvider).logout();
      } catch (_) {
        // Best-effort cleanup only.
      }
      await prefs.remove('is_premium');
      return;
    }

    final cacheKey = _cacheKey(userId);
    final legacyValue = prefs.getBool('is_premium');
    final cachedValue = prefs.getBool(cacheKey) ?? legacyValue ?? false;
    state = cachedValue;

    if (legacyValue != null && !prefs.containsKey(cacheKey)) {
      await prefs.setBool(cacheKey, legacyValue);
      await prefs.remove('is_premium');
    }

    // Also check RevenueCat if initialized
    final service = ref.read(purchaseServiceProvider);
    if (service.isInitialized) {
      try {
        final isPremium = await service.isPremium();
        if (!_isLatestLoad(loadToken)) return;
        if (isPremium != state) {
          state = isPremium;
          await prefs.setBool(cacheKey, isPremium);
        }
      } catch (_) {
        // RevenueCat query failed, use cached value
      }
    }

    // Retry any pending Supabase sync from a previous failed attempt
    await retryPendingSync(userId);
  }

  bool _isLatestLoad(int token) => ref.mounted && token == _loadSequence;

  /// Updates the premium status and persists to SharedPreferences.
  Future<void> setPremium(bool value) async {
    if (!ref.mounted) return;
    state = value;
    final prefs = await SharedPreferences.getInstance();
    final userId = ref.read(currentUserIdProvider);
    if (userId == 'anonymous') {
      await prefs.remove('is_premium');
      return;
    }

    await prefs.setBool(_cacheKey(userId), value);
    await prefs.remove('is_premium');
  }

  /// Re-checks premium status from RevenueCat (e.g., on app resume).
  ///
  /// Detects subscription renewals, expirations, or cancellations that
  /// happened while the app was in the background. No-op if not initialized.
  Future<void> refresh() async {
    final service = ref.read(purchaseServiceProvider);
    try {
      final isPremium = await service.isPremium();
      if (!ref.mounted) return;
      if (isPremium != state) {
        AppLogger.info(
          '[PremiumNotifier] Status changed on resume: $isPremium',
        );
        await setPremium(isPremium);
        if (!isPremium) {
          await syncPremiumToSupabase(isPremium: false);
        }
      }
    } catch (e) {
      AppLogger.warning('[PremiumNotifier] Refresh failed: $e');
    }

    // Retry any pending Supabase sync
    final userId = ref.read(currentUserIdProvider);
    await retryPendingSync(userId);
  }

  /// Purchases a package via RevenueCat.
  Future<bool> purchase(Package package) async {
    final service = ref.read(purchaseServiceProvider);
    final success = await service.purchasePackage(package);
    if (!ref.mounted) return success;
    if (success) {
      await setPremium(true);
      await syncPremiumToSupabase(isPremium: true, package: package);
    }
    return success;
  }

  /// Restores previous purchases.
  Future<bool> restore() async {
    final service = ref.read(purchaseServiceProvider);
    final success = await service.restorePurchases();
    if (!ref.mounted) return success;
    await setPremium(success);
    if (success) {
      await syncPremiumToSupabase(isPremium: true);
    }
    return success;
  }

  // Supabase sync operations are in premium_sync_helpers.dart (part file).
}
