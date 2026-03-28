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
  Future<void> syncPremiumToSupabase({
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
        // Update status to 'cancelled' instead of deleting — preserves history
        final existing = await client
            .from(SupabaseConstants.userSubscriptionsTable)
            .select('id')
            .eq('user_id', userId)
            .maybeSingle();
        if (existing != null) {
          await client
              .from(SupabaseConstants.userSubscriptionsTable)
              .update({
                'status': 'cancelled',
                'updated_at': DateTime.now().toUtc().toIso8601String(),
              })
              .eq('user_id', userId);
        }
      }

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
        await savePendingSync(userId, isPremium);
      }
    }
  }

  bool isSupabaseUnavailableError(Object error) {
    final message = error.toString();
    return message.contains('You must initialize the supabase instance') ||
        message.contains('provider that is in error state');
  }

  Future<void> savePendingSync(String userId, bool isPremium) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode({
      'isPremium': isPremium,
      'retryCount': 0,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
    await prefs.setString(PremiumNotifier._pendingSyncKey(userId), data);
    AppLogger.info('[PremiumNotifier] Saved pending sync for user $userId');
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
    } catch (_) {
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

    try {
      await syncPremiumToSupabase(isPremium: isPremium);
      // syncPremiumToSupabase clears pending on success
    } catch (_) {
      final newData = jsonEncode({
        'isPremium': isPremium,
        'retryCount': retryCount + 1,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
      await prefs.setString(PremiumNotifier._pendingSyncKey(userId), newData);
    }
  }
}
