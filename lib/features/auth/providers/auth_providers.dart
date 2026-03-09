import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../bootstrap.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/services/notifications/notification_providers.dart';
import '../../../domain/services/sync/sync_providers.dart';
import '../../premium/providers/premium_providers.dart';
import 'two_factor_providers.dart';

// Import for internal use within this file.
import '../../../data/providers/auth_state_providers.dart';
import '../../../data/remote/supabase/supabase_client.dart';

// Re-export infrastructure auth providers from data layer so existing
// feature-level imports continue to work without changes.
export 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
export 'package:budgie_breeding_tracker/data/remote/supabase/supabase_client.dart'
    show supabaseClientProvider;
export 'auth_actions.dart';

/// Current Supabase [User] or null.
/// Returns null if Supabase is not initialized.
final currentUserProvider = Provider<User?>((ref) {
  final initialized = ref.watch(supabaseInitializedProvider);
  if (!initialized) return null;
  final client = ref.watch(supabaseClientProvider);
  return client.auth.currentUser;
});

/// Current initialization step for splash screen progress display.
enum InitStep { profile, services, ready }

/// Notifier for tracking which initialization step is currently running.
class InitStepNotifier extends Notifier<InitStep> {
  @override
  InitStep build() => InitStep.profile;
}

/// Tracks which initialization step is currently running.
final initStepProvider = NotifierProvider<InitStepNotifier, InitStep>(
  InitStepNotifier.new,
);

/// Notifier for whether the user chose to skip initialization.
class InitSkippedNotifier extends Notifier<bool> {
  @override
  bool build() => false;
}

/// Whether the user chose to skip initialization (continue offline on error).
final initSkippedProvider = NotifierProvider<InitSkippedNotifier, bool>(
  InitSkippedNotifier.new,
);

/// Global auth side effects.
///
/// Ensures premium-related local/session state is reset when the user becomes
/// anonymous (sign-out or expired session).
final authSessionSideEffectsProvider = Provider<void>((ref) {
  ref.listen<String>(currentUserIdProvider, (previous, next) {
    if (next != 'anonymous') return;
    unawaited(ref.read(purchaseServiceProvider).logout());
    unawaited(ref.read(localPremiumProvider.notifier).setPremium(false));
  }, fireImmediately: true);
});

/// App initialization provider.
/// Runs critical startup tasks (profile sync) then initializes notifications.
/// Data sync is deferred to background after splash resolves to avoid jank.
/// Watched by the router to show splash screen while loading.
final appInitializationProvider = FutureProvider<void>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == 'anonymous') return;

  // Yield to avoid synchronous state mutation during build phase.
  // Without this, the code before the first `await` runs synchronously
  // during provider creation and can trigger '!_dirty' assertion.
  await Future<void>.delayed(Duration.zero);

  // Step 1: Profile sync (critical - determines premium, role, etc.)
  ref.read(initStepProvider.notifier).state = InitStep.profile;
  final profileRepo = ref.read(profileRepositoryProvider);
  try {
    await profileRepo.pull(userId);
  } catch (e, st) {
    // Non-fatal: continue with cached local profile (or create one below).
    // A persistent network failure should NOT lock the splash screen.
    AppLogger.warning('[AppInit] Profile pull failed, continuing offline: $e');
    Sentry.captureException(e, stackTrace: st);
  }

  // Sync auth metadata (display_name/full_name) to profiles table if missing
  await _syncAuthMetadataToProfile(ref, userId);

  // Check if existing session needs 2FA verification (e.g., app restart with AAL1)
  await _checkPendingMfa(ref);

  // Step 2: RevenueCat init (non-blocking — runs in background)
  unawaited(_initRevenueCat(ref, userId));

  // Step 3: Notification init (relatively fast, needed for scheduled reminders)
  ref.read(initStepProvider.notifier).state = InitStep.services;
  await _initNotifications(ref);

  ref.read(initStepProvider.notifier).state = InitStep.ready;

  // Process any notification payloads that arrived before router was ready
  processPendingPayloads(ref);

  // Step 3: Defer full data sync to background — don't block splash
  // This runs AFTER the splash resolves and home screen renders.
  Future.microtask(() => _initDataSync(ref, userId));
});

/// Checks if the current session needs 2FA verification (AAL1 → AAL2).
/// Sets [pendingMfaFactorIdProvider] so the router can redirect to verify screen.
Future<void> _checkPendingMfa(Ref ref) async {
  try {
    final service = ref.read(twoFactorServiceProvider);
    final needs2FA = await service.needsVerification();
    if (needs2FA) {
      final factors = await service.getFactors();
      if (factors.isNotEmpty) {
        ref.read(pendingMfaFactorIdProvider.notifier).state = factors.first.id;
      }
    }
  } catch (e, st) {
    AppLogger.warning('[AppInit] MFA check failed, continuing: $e');
    Sentry.captureException(e, stackTrace: st);
  }
}

/// Syncs auth user metadata (display_name, full_name) to the profiles table.
/// This ensures the name entered during registration is persisted in profiles.
Future<void> _syncAuthMetadataToProfile(Ref ref, String userId) async {
  try {
    final client = ref.read(supabaseClientProvider);
    final user = client.auth.currentUser;
    if (user == null) return;

    final metadata = user.userMetadata;
    if (metadata == null || metadata.isEmpty) return;

    final metaDisplayName = metadata['display_name'] as String?;
    final metaFullName = metadata['full_name'] as String?;
    final resolvedName = metaFullName ?? metaDisplayName;
    if (resolvedName == null || resolvedName.trim().isEmpty) return;

    final profileRepo = ref.read(profileRepositoryProvider);
    final profile = await profileRepo.getById(userId);
    if (profile == null) {
      // No profile yet — create one with auth metadata
      final newProfile = Profile(
        id: userId,
        email: user.email ?? '',
        fullName: resolvedName,
      );
      await profileRepo.save(newProfile);
      // Try immediate push so name is visible on next pull
      try {
        await profileRepo.push(newProfile);
      } catch (_) {
        // Will be retried by SyncOrchestrator
      }
      return;
    }

    // Only update if fullName is missing or blank
    if (profile.fullName != null && profile.fullName!.trim().isNotEmpty) return;

    final updated = profile.copyWith(fullName: resolvedName);
    await profileRepo.save(updated);
    // Try immediate push so name is visible on next pull
    try {
      await profileRepo.push(updated);
    } catch (_) {
      // Will be retried by SyncOrchestrator
    }
  } catch (e) {
    AppLogger.warning('[AppInit] Auth metadata sync to profile failed: $e');
  }
}

/// Initializes local + push notification services and rate limiter.
Future<void> _initNotifications(Ref ref) async {
  try {
    final notifService = ref.read(notificationServiceProvider);
    await notifService.init();
    // Request Android 13+ POST_NOTIFICATIONS permission and track result
    final granted = await notifService.requestAndroidPermission();
    if (!granted) {
      ref.read(notificationPermissionGrantedProvider.notifier).state = false;
    }
    // Verify exact alarm permission (Android 12+) — warns if not granted
    await notifService.checkExactAlarmPermission();
  } catch (e, st) {
    AppLogger.warning('[AppInit] Local notification init failed: $e');
    Sentry.captureException(e, stackTrace: st);
  }
  // Ensure rate limiter DND / rate-limit data is loaded before scheduling
  try {
    await ref.read(rateLimiterReadyProvider.future);
  } catch (e) {
    AppLogger.warning('[AppInit] Rate limiter prefs load failed: $e');
  }
}

/// Initializes RevenueCat with the platform-specific API key and user ID.
/// Runs in the background — does NOT block splash screen.
Future<void> _initRevenueCat(Ref ref, String userId) async {
  final apiKey = Platform.isIOS ? revenueCatApiKeyIos : revenueCatApiKeyAndroid;
  if (apiKey.isEmpty) {
    AppLogger.warning(
      '[AppInit] RevenueCat API key not configured, skipping init',
    );
    return;
  }
  try {
    final purchaseService = ref.read(purchaseServiceProvider);
    await purchaseService.initialize(apiKey: apiKey, userId: userId);
  } catch (e) {
    AppLogger.warning('[AppInit] RevenueCat init failed: $e');
  }
}

/// Triggers a full data sync from Supabase to local DB.
///
/// Periodic and network-aware sync providers are watched by [MainShell]
/// to ensure their timers and listeners stay alive for the session.
Future<void> _initDataSync(Ref ref, String userId) async {
  try {
    final syncOrchestrator = ref.read(syncOrchestratorProvider);
    await syncOrchestrator.fullSync();
  } catch (_) {
    // Non-critical: offline data is still available
  }
}
