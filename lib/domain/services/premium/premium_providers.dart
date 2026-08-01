import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart' hide SubscriptionInfo;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budgie_breeding_tracker/bootstrap.dart';
import 'package:budgie_breeding_tracker/core/enums/subscription_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/providers/edge_function_provider.dart';
import 'package:budgie_breeding_tracker/domain/services/payment/purchase_service.dart';
import 'package:budgie_breeding_tracker/data/models/profile_model.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/profile_stream_providers.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';

export 'package:budgie_breeding_tracker/core/enums/subscription_enums.dart'
    show GracePeriodStatus;

part 'premium_notifier.dart';
part 'premium_plan_utilities.dart';
part 'premium_sync_helpers.dart';
part 'purchase_action_notifier.dart';

/// Singleton [PurchaseService] instance.
final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  return PurchaseService();
});

bool get isDebugIosSimulatorRuntime =>
    !kReleaseMode && Platform.isIOS && isIosSimulatorRuntime;

bool get shouldDeferAdsOnDebugIosSimulator =>
    !kReleaseMode && Platform.isIOS && isIosSimulatorRuntime;

/// Whether user has premium subscription.
/// Combines profile database state with RevenueCat/SharedPreferences cache.
/// Primary source is the profile (server-synced); local cache is used only
/// as a fallback while profile is still loading. This prevents premium bypass
/// via SharedPreferences tampering on rooted/jailbroken devices.
/// Admin and founder roles always get premium access regardless of subscription.
final isPremiumProvider = Provider<bool>((ref) {
  // Primary source: profile from database (real-time)
  final premiumProfile = ref.watch(
    userProfileProvider.select((profileAsync) {
      final profile = profileAsync.value;
      return (
        hasValue: profileAsync.hasValue,
        isPrivileged: profile != null && (profile.isAdmin || profile.isFounder),
        hasPremium: profile?.hasPremium ?? false,
      );
    }),
  );

  // Admin/founder bypass: always grant premium access
  if (premiumProfile.isPrivileged) return true;

  // Fallback source: local cache (RevenueCat / SharedPreferences)
  final localPremium = ref.watch(localPremiumProvider);

  // Fallback logic: use local cache only while profile is loading.
  // Once profile has loaded, trust the server-side value exclusively.
  // This prevents premium bypass via SharedPreferences tampering.
  if (!premiumProfile.hasValue) return localPremium;
  return premiumProfile.hasPremium;
});

/// Syncs profile premium status to local cache whenever profile changes.
/// Keep-alive so this runs for the lifetime of the app.
final premiumSyncProvider = Provider<void>((ref) {
  ref.keepAlive();
  ref.listen<AsyncValue<Profile?>>(userProfileProvider, (prev, next) {
    next.whenData((profile) {
      final hasPremium = profile?.hasPremium ?? false;
      ref.read(localPremiumProvider.notifier).setPremium(hasPremium);
    });
  });
});

/// Test seam for the pending-sync retry backoff wait.
///
/// Production waits the real exponential backoff (`2^retryCount` seconds,
/// capped) before retrying a failed premium sync. Tests override this to skip
/// real wall-clock waits — asserting the retry/increment behavior deterministically
/// instead of racing a real timer (see test-stability.md § Flaky Triage #3,
/// the `syncClockProvider` pattern). The production default is a plain
/// `Future.delayed`, so behavior is unchanged.
final premiumSyncBackoffProvider = Provider<Future<void> Function(Duration)>(
  (ref) =>
      (duration) => Future<void>.delayed(duration),
);

/// Test seam for the short post-purchase server reconciliation waits.
///
/// RevenueCat's SDK can return an active entitlement before the backend pull
/// used by `sync-premium-status` observes the same receipt. Production waits
/// briefly and retries; tests override this to avoid wall-clock delays.
final premiumActivationSyncDelayProvider =
    Provider<Future<void> Function(Duration)>(
      (ref) =>
          (duration) => Future<void>.delayed(duration),
    );

/// Injectable clock used by premium expiry calculations.
final premiumClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Local premium cache backed by SharedPreferences + RevenueCat.
/// Used by premium screen for purchase/restore actions.
final localPremiumProvider = NotifierProvider<PremiumNotifier, bool>(
  PremiumNotifier.new,
);

/// Ensures RevenueCat is initialized for the current authenticated user.
final purchaseServiceReadyProvider = FutureProvider<bool>((ref) async {
  final apiKey = Platform.isIOS ? revenueCatApiKeyIos : revenueCatApiKeyAndroid;
  if (apiKey.isEmpty) {
    AppLogger.warning('[Premium] RevenueCat API key missing');
    return false;
  }

  final userId = ref.watch(currentUserIdProvider);
  if (userId == 'anonymous') {
    AppLogger.warning(
      '[Premium] Purchase requested without authenticated user',
    );
    return false;
  }

  final service = ref.watch(purchaseServiceProvider);
  return service.initialize(apiKey: apiKey, userId: userId);
});

/// Available RevenueCat offerings.
///
/// If the first attempt returns an empty list (e.g. transient StoreKit
/// failure during app review), a single retry is performed after a short
/// delay so that sandbox products have time to become available.
final premiumOfferingsProvider = FutureProvider<List<Package>>((ref) async {
  final isReady = await ref.watch(purchaseServiceReadyProvider.future);
  if (!isReady) return [];

  final service = ref.watch(purchaseServiceProvider);
  final packages = await service.getOfferings();
  if (packages.isNotEmpty) return packages;

  // Single retry after a short delay — StoreKit sandbox can be slow
  // to respond on first launch or during App Review (iOS only).
  if (Platform.isIOS) {
    await Future<void>.delayed(const Duration(seconds: 2));
    return service.getOfferings();
  }

  return packages;
});

/// Detailed subscription info.
final subscriptionInfoProvider = FutureProvider<SubscriptionInfo>((ref) async {
  final isReady = await ref.watch(purchaseServiceReadyProvider.future);
  if (!isReady) {
    return const SubscriptionInfo(isActive: false);
  }

  final service = ref.watch(purchaseServiceProvider);
  return service.getSubscriptionInfo();
});

/// Determines the user's premium grace period status.
///
/// Uses only the server-verified `gracePeriodUntil` profile field to detect
/// grace. A plain expiration date never grants additional access.
/// Admin/founder roles always return [GracePeriodStatus.active].
///
/// Usage: Use this provider when you need to distinguish between
/// active premium, grace period, and expired states.
/// For simple "has access?" checks, use [effectivePremiumProvider] instead.
final premiumGracePeriodProvider = Provider<GracePeriodStatus>((ref) {
  final profileAsync = ref.watch(userProfileProvider);
  final profile = profileAsync.value;

  // No profile loaded yet — treat as unknown/free
  if (profile == null) return GracePeriodStatus.free;

  // Admin/founder always active
  if (profile.isAdmin || profile.isFounder) return GracePeriodStatus.active;

  // Currently premium (active subscription)
  if (profile.hasPremium) return GracePeriodStatus.active;

  // Grace is a server-owned billing decision. Never fabricate it from a plain
  // expiration timestamp on the client: cancellation and payment failure are
  // different states and only RevenueCat/server metadata can distinguish them.
  final gracePeriodEnd = profile.gracePeriodUntil;
  if (gracePeriodEnd == null) return GracePeriodStatus.free;

  final now = ref.watch(premiumClockProvider)();
  if (now.isBefore(gracePeriodEnd)) {
    final expiryTimer = Timer(
      gracePeriodEnd.difference(now),
      ref.invalidateSelf,
    );
    ref.onDispose(expiryTimer.cancel);
    return GracePeriodStatus.gracePeriod;
  }

  return GracePeriodStatus.expired;
});

/// Whether the user has effective premium access (active OR grace period).
///
/// Use this provider for:
/// - Free tier limit checks in form notifiers
/// - Premium route guards
/// - Ad visibility (banners and interstitials): a subscriber whose renewal is
///   still retrying inside the grace window is a paying customer and must not
///   see ads. This previously said the opposite, which left three of the five
///   ad surfaces on [isPremiumProvider] and showed ads to grace-period
///   subscribers on Birds/Breeding/Calendar but not on Chicks/More.
///
/// Do NOT use for:
/// - Subscription info display (use [premiumGracePeriodProvider])
final effectivePremiumProvider = Provider<bool>((ref) {
  final status = ref.watch(premiumGracePeriodProvider);
  return status == GracePeriodStatus.active ||
      status == GracePeriodStatus.gracePeriod;
});
