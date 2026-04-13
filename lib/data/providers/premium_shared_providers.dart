/// Re-exports commonly cross-imported premium providers.
///
/// The full premium implementation remains in
/// `lib/features/premium/providers/premium_providers.dart`.
/// This file exists so other features can import premium symbols
/// without creating cross-feature import violations.
export 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart'
    show
        effectivePremiumProvider,
        isPremiumProvider,
        localPremiumProvider,
        premiumGracePeriodProvider,
        premiumOfferingsProvider,
        premiumSyncProvider,
        purchaseServiceProvider,
        purchaseServiceReadyProvider,
        shouldDeferAdsOnDebugIosSimulator,
        shouldDeferRevenueCatOnDebugIosSimulator,
        subscriptionInfoProvider;

export 'package:budgie_breeding_tracker/core/enums/subscription_enums.dart'
    show GracePeriodStatus;
