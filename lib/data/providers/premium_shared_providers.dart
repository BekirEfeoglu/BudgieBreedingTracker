/// Re-exports commonly cross-imported premium providers.
///
/// The full premium implementation lives in the domain service layer.
library;
export 'package:budgie_breeding_tracker/domain/services/premium/premium_providers.dart'
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
