import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budgie_breeding_tracker/bootstrap.dart';
import 'package:budgie_breeding_tracker/core/constants/app_constants.dart';
import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/subscription_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/domain/services/payment/purchase_service.dart';
import 'package:budgie_breeding_tracker/data/models/profile_model.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';

part 'premium_notifier.dart';
part 'premium_plan_utilities.dart';
part 'premium_sync_helpers.dart';
part 'purchase_action_notifier.dart';

/// Singleton [PurchaseService] instance.
final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  return PurchaseService();
});

/// Whether user has premium subscription.
/// Combines profile database state with RevenueCat/SharedPreferences cache.
/// Primary source is the profile (server-synced); local cache is used only
/// as a fallback while profile is still loading. This prevents premium bypass
/// via SharedPreferences tampering on rooted/jailbroken devices.
/// Admin and founder roles always get premium access regardless of subscription.
final isPremiumProvider = Provider<bool>((ref) {
  // Primary source: profile from database (real-time)
  final profileAsync = ref.watch(userProfileProvider);

  // Admin/founder bypass: always grant premium access
  final profile = profileAsync.value;
  if (profile != null && (profile.isAdmin || profile.isFounder)) return true;

  // Fallback source: local cache (RevenueCat / SharedPreferences)
  final localPremium = ref.watch(localPremiumProvider);

  // Fallback logic: use local cache only while profile is loading.
  // Once profile has loaded, trust the server-side value exclusively.
  // This prevents premium bypass via SharedPreferences tampering.
  if (!profileAsync.hasValue) return localPremium;
  return profileAsync.value?.hasPremium ?? false;
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
/// Uses profile data (premiumExpiresAt) to detect grace period.
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

  // Check grace period via premiumExpiresAt
  final expiresAt = profile.premiumExpiresAt;
  if (expiresAt == null) return GracePeriodStatus.free;

  final daysSinceExpiry = DateTime.now().difference(expiresAt).inDays;
  if (daysSinceExpiry <= AppConstants.gracePeriodDays) {
    return GracePeriodStatus.gracePeriod;
  }

  return GracePeriodStatus.expired;
});

/// Whether the user has effective premium access (active OR grace period).
///
/// Use this provider for:
/// - Free tier limit checks in form notifiers
/// - Premium route guards
///
/// Do NOT use for:
/// - Ad visibility (use [isPremiumProvider] — grace period shows ads)
/// - Subscription info display (use [premiumGracePeriodProvider])
final effectivePremiumProvider = Provider<bool>((ref) {
  final status = ref.watch(premiumGracePeriodProvider);
  return status == GracePeriodStatus.active ||
      status == GracePeriodStatus.gracePeriod;
});
