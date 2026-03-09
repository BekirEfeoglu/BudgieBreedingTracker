import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budgie_breeding_tracker/bootstrap.dart';
import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/domain/services/payment/purchase_service.dart';
import 'package:budgie_breeding_tracker/data/models/profile_model.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';

/// Singleton [PurchaseService] instance.
final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  return PurchaseService();
});

/// Whether user has premium subscription.
/// Combines profile database state with RevenueCat/SharedPreferences cache.
/// Syncs profile premium status to SharedPreferences for faster startup.
/// Admin and founder roles always get premium access regardless of subscription.
final isPremiumProvider = Provider<bool>((ref) {
  // Primary source: profile from database (real-time)
  final profileAsync = ref.watch(userProfileProvider);

  // Admin/founder bypass: always grant premium access
  final profile = profileAsync.value;
  if (profile != null && (profile.isAdmin || profile.isFounder)) return true;

  final profileHasPremium = profileAsync.hasValue
      ? (profileAsync.value?.hasPremium ?? false)
      : null;

  // Sync profile premium status to local cache for next startup
  ref.listen<AsyncValue<Profile?>>(userProfileProvider, (prev, next) {
    next.whenData((profile) {
      final hasPremium = profile?.hasPremium ?? false;
      ref.read(localPremiumProvider.notifier).setPremium(hasPremium);
    });
  });

  // Fallback source: local cache (RevenueCat / SharedPreferences)
  final localPremium = ref.watch(localPremiumProvider);

  return profileHasPremium ?? localPremium;
});

/// Local premium cache backed by SharedPreferences + RevenueCat.
/// Used by premium screen for purchase/restore actions.
final localPremiumProvider = NotifierProvider<PremiumNotifier, bool>(
  PremiumNotifier.new,
);

/// Notifier that manages premium subscription state with persistence
/// and RevenueCat integration.
class PremiumNotifier extends Notifier<bool> {
  @override
  bool build() {
    final userId = ref.watch(currentUserIdProvider);
    _load(userId);
    return false;
  }

  static String _cacheKey(String userId) => 'is_premium_$userId';

  Future<void> _load(String userId) async {
    final prefs = await SharedPreferences.getInstance();
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
      if (isPremium != state) {
        state = isPremium;
        await prefs.setBool(cacheKey, isPremium);
      }
    } catch (_) {
      // RevenueCat not initialized yet, use cached value
    }
  }

  /// Updates the premium status and persists to SharedPreferences.
  Future<void> setPremium(bool value) async {
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
  }

  /// Purchases a package via RevenueCat.
  Future<bool> purchase(Package package) async {
    final service = ref.read(purchaseServiceProvider);
    final success = await service.purchasePackage(package);
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
    try {
      final client = ref.read(supabaseClientProvider);
      final userId = ref.read(currentUserIdProvider);
      if (userId == 'anonymous') return;

      // Update profiles table (source of truth)
      await client
          .from(SupabaseConstants.profilesTable)
          .update({
            'is_premium': isPremium,
            'subscription_status': isPremium ? 'premium' : 'free',
          })
          .eq('id', userId);

      if (isPremium) {
        // Determine expiry from RevenueCat subscription info
        DateTime? expiresAt;
        try {
          final info = await ref
              .read(purchaseServiceProvider)
              .getSubscriptionInfo();
          expiresAt = info.expirationDate;
        } catch (_) {
          // RevenueCat info unavailable — proceed without expiry
        }

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
      }
    } catch (e) {
      if (_isSupabaseUnavailableError(e)) {
        AppLogger.info(
          '[PremiumNotifier] Skipping Supabase sync: Supabase is not initialized',
        );
      } else {
        AppLogger.warning(
          '[PremiumNotifier] Supabase sync failed (non-fatal): $e',
        );
      }
    }
  }

  bool _isSupabaseUnavailableError(Object error) {
    final message = error.toString();
    return message.contains('You must initialize the supabase instance') ||
        message.contains('provider that is in error state');
  }
}

/// Available premium plan types.
enum PremiumPlan { monthly, yearly, lifetime }

enum PremiumPurchaseIssue {
  missingApiKey,
  offeringsUnavailable,
  iosDebugStoreKitRequired,
}

final premiumPurchaseIssueProvider = Provider<PremiumPurchaseIssue?>((ref) {
  final apiKey = Platform.isIOS ? revenueCatApiKeyIos : revenueCatApiKeyAndroid;
  if (apiKey.isEmpty) {
    return PremiumPurchaseIssue.missingApiKey;
  }

  if (ref.watch(currentUserIdProvider) == 'anonymous') {
    return null;
  }

  final offerings = ref.watch(premiumOfferingsProvider);
  if (offerings.isLoading) {
    return null;
  }

  final packages = offerings.asData?.value;
  if (packages == null || packages.isNotEmpty) {
    return null;
  }

  if (Platform.isIOS && kDebugMode) {
    return PremiumPurchaseIssue.iosDebugStoreKitRequired;
  }

  return PremiumPurchaseIssue.offeringsUnavailable;
});

Package? matchPackageForPlan(List<Package> offerings, PremiumPlan plan) {
  final targetType = switch (plan) {
    PremiumPlan.monthly => PackageType.monthly,
    PremiumPlan.yearly => PackageType.annual,
    PremiumPlan.lifetime => PackageType.lifetime,
  };

  for (final package in offerings) {
    if (package.packageType == targetType) {
      return package;
    }
  }

  final planHints = switch (plan) {
    PremiumPlan.monthly => ['monthly', 'month', r'$rc_monthly', ':monthly'],
    PremiumPlan.yearly => [
      'annual',
      'yearly',
      'year',
      r'$rc_annual',
      ':yearly',
    ],
    PremiumPlan.lifetime => ['lifetime', 'life', r'$rc_lifetime'],
  };

  for (final package in offerings) {
    final identifier = package.identifier.toLowerCase();
    final productIdentifier = package.storeProduct.identifier.toLowerCase();
    for (final hint in planHints) {
      final normalizedHint = hint.toLowerCase();
      if (identifier.contains(normalizedHint) ||
          productIdentifier.contains(normalizedHint)) {
        return package;
      }
    }
  }

  return null;
}

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
final premiumOfferingsProvider = FutureProvider<List<Package>>((ref) async {
  final isReady = await ref.watch(purchaseServiceReadyProvider.future);
  if (!isReady) return [];

  final service = ref.watch(purchaseServiceProvider);
  return service.getOfferings();
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

/// State for purchase/restore actions with loading and error tracking.
class PurchaseActionState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;
  final PremiumPlan? purchasingPlan;

  const PurchaseActionState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.purchasingPlan,
  });

  PurchaseActionState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    PremiumPlan? purchasingPlan,
  }) => PurchaseActionState(
    isLoading: isLoading ?? this.isLoading,
    error: error,
    isSuccess: isSuccess ?? this.isSuccess,
    purchasingPlan: purchasingPlan,
  );
}

/// Manages purchase/restore action lifecycle (loading, success, error).
class PurchaseActionNotifier extends Notifier<PurchaseActionState> {
  @override
  PurchaseActionState build() => const PurchaseActionState();

  /// Purchases a plan via RevenueCat offerings.
  Future<void> purchasePlan(PremiumPlan plan) async {
    state = PurchaseActionState(isLoading: true, purchasingPlan: plan);

    try {
      final isReady = await ref.read(purchaseServiceReadyProvider.future);
      if (!isReady) {
        AppLogger.warning('Purchase service is not ready');
        state = const PurchaseActionState(error: 'no_offerings');
        return;
      }

      final offerings = await ref.read(premiumOfferingsProvider.future);

      if (offerings.isEmpty) {
        AppLogger.warning('No RevenueCat offerings available');
        state = const PurchaseActionState(error: 'no_offerings');
        return;
      }

      // Find matching package by plan type
      final package = matchPackageForPlan(offerings, plan);
      if (package == null) {
        state = const PurchaseActionState(error: 'package_not_found');
        return;
      }

      final success = await ref
          .read(localPremiumProvider.notifier)
          .purchase(package);
      if (success) {
        state = const PurchaseActionState(isSuccess: true);
      } else {
        state = const PurchaseActionState(error: 'purchase_cancelled');
      }
    } on PurchaseException catch (e, st) {
      AppLogger.error('Purchase failed', e, st);
      state = PurchaseActionState(error: e.code);
    } catch (e, st) {
      AppLogger.error('Purchase failed', e, st);
      state = PurchaseActionState(error: e.toString());
    }
  }

  /// Restores previous purchases via RevenueCat.
  Future<void> restorePurchases() async {
    state = const PurchaseActionState(isLoading: true);

    try {
      final isReady = await ref.read(purchaseServiceReadyProvider.future);
      if (!isReady) {
        AppLogger.warning('Purchase service is not ready for restore');
        state = const PurchaseActionState(error: 'no_offerings');
        return;
      }

      final success = await ref.read(localPremiumProvider.notifier).restore();
      if (success) {
        state = const PurchaseActionState(isSuccess: true);
      } else {
        state = const PurchaseActionState(error: 'restore_no_purchases');
      }
    } catch (e, st) {
      AppLogger.error('Restore failed', e, st);
      state = PurchaseActionState(error: e.toString());
    }
  }

  /// Resets the action state.
  void reset() => state = const PurchaseActionState();
}

/// Provider for purchase/restore action state.
final purchaseActionProvider =
    NotifierProvider<PurchaseActionNotifier, PurchaseActionState>(
      PurchaseActionNotifier.new,
    );
