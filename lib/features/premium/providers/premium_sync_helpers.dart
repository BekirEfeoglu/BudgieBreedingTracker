part of 'premium_providers.dart';

/// Extension on [PremiumNotifier] for Supabase sync operations.
///
/// Extracted from premium_notifier.dart to keep file under 300 lines.
/// Handles syncing premium status to profiles/user_subscriptions tables,
/// pending sync persistence, and retry logic.
///
/// Private extension: only accessible within the premium_providers library
/// to prevent external code from triggering arbitrary sync operations.
extension _PremiumSyncHelpers on PremiumNotifier {
  /// Syncs premium status to Supabase profiles and user_subscriptions tables.
  /// Non-fatal: errors are logged but do not throw.
  ///
  /// [currentRetryCount] is used internally by [retryPendingSync] to preserve
  /// the retry counter when saving a failed sync for later retry.
  Future<void> syncPremiumToSupabase({
    required bool isPremium,
    Package? package,
    int currentRetryCount = -1,
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
        } catch (e) {
          AppLogger.warning(
            '[PremiumNotifier] RevenueCat info unavailable, proceeding without expiry: $e',
          );
        }
      }

      // Atomic sync via RPC — updates both profiles and user_subscriptions
      // in a single transaction, preventing partial state.
      await client.rpc('sync_premium_status', params: {
        'p_is_premium': isPremium,
        'p_subscription_status': isPremium ? 'premium' : 'free',
        'p_premium_expires_at': expiresAt?.toIso8601String(),
        'p_plan': 'premium',
        'p_current_period_end': expiresAt?.toIso8601String(),
      });

      // Sync succeeded — clear any pending retry
      await clearPendingSync(userId);
    } catch (e) {
      if (isSupabaseUnavailableError(e)) {
        AppLogger.info(
          '[PremiumNotifier] Skipping Supabase sync: Supabase is not initialized',
        );
      } else {
        AppLogger.warning(
          '[PremiumNotifier] Supabase sync failed (non-fatal): $e',
        );
        // Save for retry on next app resume
        if (!ref.mounted) return;
        final userId = ref.read(currentUserIdProvider);
        // When called from retryPendingSync, increment the retry count.
        // When called fresh (not a retry), start at 0.
        final nextRetry = currentRetryCount >= 0 ? currentRetryCount + 1 : 0;
        await savePendingSync(userId, isPremium, retryCount: nextRetry);
      }
    }
  }

  bool isSupabaseUnavailableError(Object error) {
    final message = error.toString();
    return message.contains('You must initialize the supabase instance') ||
        message.contains('provider that is in error state');
  }

  Future<void> savePendingSync(
    String userId,
    bool isPremium, {
    int retryCount = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode({
      'isPremium': isPremium,
      'retryCount': retryCount,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
    await prefs.setString(PremiumNotifier._pendingSyncKey(userId), data);
    AppLogger.info(
      '[PremiumNotifier] Saved pending sync for user $userId '
      '(retryCount: $retryCount)',
    );
  }

  Future<void> clearPendingSync(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(PremiumNotifier._pendingSyncKey(userId));
  }

  Future<void> retryPendingSync(String userId) async {
    if (userId == 'anonymous') return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(PremiumNotifier._pendingSyncKey(userId));
    if (raw == null) return;

    int retryCount = 0;
    bool isPremium = true;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      retryCount = (map['retryCount'] as num?)?.toInt() ?? 0;
      isPremium = map['isPremium'] as bool? ?? true;
    } catch (e) {
      AppLogger.warning('[PremiumNotifier] Corrupt pending sync data: $e');
      await clearPendingSync(userId);
      return;
    }

    if (retryCount >= PremiumNotifier._maxSyncRetries) {
      AppLogger.warning(
        '[PremiumNotifier] Max sync retries ($retryCount) reached for $userId',
      );
      Sentry.captureException(
        Exception(
          'Premium Supabase sync failed after ${PremiumNotifier._maxSyncRetries} retries',
        ),
        stackTrace: StackTrace.current,
      );
      await clearPendingSync(userId);
      return;
    }

    AppLogger.info(
      '[PremiumNotifier] Retrying pending sync '
      '(attempt ${retryCount + 1}/${PremiumNotifier._maxSyncRetries})',
    );

    // Delegate to syncPremiumToSupabase with the current retryCount.
    // On success it clears pending sync. On failure it saves with
    // retryCount + 1 (handled via the currentRetryCount parameter).
    await syncPremiumToSupabase(isPremium: isPremium, currentRetryCount: retryCount);
  }
}
