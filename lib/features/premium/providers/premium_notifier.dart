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

    // Also check RevenueCat if available
    final service = ref.read(purchaseServiceProvider);
    try {
      final isPremium = await service.isPremium();
      if (!_isLatestLoad(loadToken)) return;
      if (isPremium != state) {
        state = isPremium;
        await prefs.setBool(cacheKey, isPremium);
      }
    } catch (_) {
      // RevenueCat not initialized yet, use cached value
    }

    // Retry any pending Supabase sync from a previous failed attempt
    await _retryPendingSync(userId);
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
          await _syncPremiumToSupabase(isPremium: false);
        }
      }
    } catch (e) {
      AppLogger.warning('[PremiumNotifier] Refresh failed: $e');
    }

    // Retry any pending Supabase sync
    final userId = ref.read(currentUserIdProvider);
    await _retryPendingSync(userId);
  }

  /// Purchases a package via RevenueCat.
  Future<bool> purchase(Package package) async {
    final service = ref.read(purchaseServiceProvider);
    final success = await service.purchasePackage(package);
    if (!ref.mounted) return success;
    if (success) {
      await setPremium(true);
      await _syncPremiumToSupabase(isPremium: true, package: package);
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
      await _syncPremiumToSupabase(isPremium: true);
    }
    return success;
  }

  /// Syncs premium status to Supabase profiles and user_subscriptions tables.
  /// Non-fatal: errors are logged but do not throw.
  Future<void> _syncPremiumToSupabase({
    required bool isPremium,
    Package? package,
  }) async {
    if (!ref.mounted) return;
    try {
      final client = ref.read(supabaseClientProvider);
      final userId = ref.read(currentUserIdProvider);
      if (userId == 'anonymous') return;

      // Determine expiry from RevenueCat subscription info
      DateTime? expiresAt;
      if (isPremium) {
        try {
          if (!ref.mounted) return;
          final info = await ref
              .read(purchaseServiceProvider)
              .getSubscriptionInfo();
          expiresAt = info.expirationDate;
        } catch (_) {
          // RevenueCat info unavailable — proceed without expiry
        }
      }

      // Update profiles table (source of truth)
      await client
          .from(SupabaseConstants.profilesTable)
          .update({
            'is_premium': isPremium,
            'subscription_status': isPremium ? 'premium' : 'free',
            'premium_expires_at':
                isPremium ? expiresAt?.toIso8601String() : null,
          })
          .eq('id', userId);

      if (isPremium) {
        final now = DateTime.now().toUtc().toIso8601String();
        final existing = await client
            .from(SupabaseConstants.userSubscriptionsTable)
            .select('id')
            .eq('user_id', userId)
            .maybeSingle();

        final data = <String, dynamic>{
          'user_id': userId,
          'plan': 'premium',
          'status': 'active',
          'updated_at': now,
          if (expiresAt != null)
            'current_period_end': expiresAt.toIso8601String(),
        };

        if (existing != null) {
          await client
              .from(SupabaseConstants.userSubscriptionsTable)
              .update(data)
              .eq('user_id', userId);
        } else {
          await client
              .from(SupabaseConstants.userSubscriptionsTable)
              .insert(data);
        }
      } else {
        await client
            .from(SupabaseConstants.userSubscriptionsTable)
            .delete()
            .eq('user_id', userId);
      }

      // Sync succeeded — clear any pending retry
      await _clearPendingSync(userId);
    } catch (e) {
      if (_isSupabaseUnavailableError(e)) {
        AppLogger.info(
          '[PremiumNotifier] Skipping Supabase sync: Supabase is not initialized',
        );
      } else {
        AppLogger.warning(
          '[PremiumNotifier] Supabase sync failed (non-fatal): $e',
        );
        // Save for retry on next app resume
        final userId = ref.read(currentUserIdProvider);
        await _savePendingSync(userId, isPremium);
      }
    }
  }

  bool _isSupabaseUnavailableError(Object error) {
    final message = error.toString();
    return message.contains('You must initialize the supabase instance') ||
        message.contains('provider that is in error state');
  }

  Future<void> _savePendingSync(String userId, bool isPremium) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode({
      'isPremium': isPremium,
      'retryCount': 0,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
    await prefs.setString(_pendingSyncKey(userId), data);
    AppLogger.info('[PremiumNotifier] Saved pending sync for user $userId');
  }

  Future<void> _clearPendingSync(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingSyncKey(userId));
  }

  Future<void> _retryPendingSync(String userId) async {
    if (userId == 'anonymous') return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingSyncKey(userId));
    if (raw == null) return;

    int retryCount = 0;
    bool isPremium = true;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      retryCount = (map['retryCount'] as num?)?.toInt() ?? 0;
      isPremium = map['isPremium'] as bool? ?? true;
    } catch (_) {
      await _clearPendingSync(userId);
      return;
    }

    if (retryCount >= _maxSyncRetries) {
      AppLogger.warning(
        '[PremiumNotifier] Max sync retries ($retryCount) reached for $userId',
      );
      Sentry.captureException(
        Exception(
          'Premium Supabase sync failed after $_maxSyncRetries retries',
        ),
        stackTrace: StackTrace.current,
      );
      await _clearPendingSync(userId);
      return;
    }

    AppLogger.info(
      '[PremiumNotifier] Retrying pending sync '
      '(attempt ${retryCount + 1}/$_maxSyncRetries)',
    );

    try {
      await _syncPremiumToSupabase(isPremium: isPremium);
      // _syncPremiumToSupabase clears pending on success
    } catch (_) {
      final newData = jsonEncode({
        'isPremium': isPremium,
        'retryCount': retryCount + 1,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
      await prefs.setString(_pendingSyncKey(userId), newData);
    }
  }
}
