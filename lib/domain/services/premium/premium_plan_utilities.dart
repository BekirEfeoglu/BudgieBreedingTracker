part of 'premium_providers.dart';

/// Available premium plan types.
enum PremiumPlan {
  monthly,
  semiAnnual,
  yearly,
  lifetime;

  /// Resolves a [PremiumPlan] from a RevenueCat product identifier string.
  /// Returns `null` if the product ID doesn't match any known plan.
  static PremiumPlan? fromProductId(String productId) {
    final id = productId.toLowerCase();
    if (id.contains('lifetime') ||
        id.contains('life_time') ||
        id.contains('one_time') ||
        id.contains('onetime')) {
      return lifetime;
    }
    if (id.contains('semi_annual') ||
        id.contains('semi-annual') ||
        id.contains('semiannual') ||
        id.contains('6_month') ||
        id.contains('6month') ||
        id.contains('six_month') ||
        id.contains('six-month')) {
      return semiAnnual;
    }
    if (id.contains('monthly') ||
        id.contains('1_month') ||
        id.contains('1month') ||
        id.contains('_month') ||
        id.contains('month_')) {
      return monthly;
    }
    if (id.contains('yearly') || id.contains('annual') || id.contains('year')) {
      return yearly;
    }
    return null;
  }
}

enum PremiumPurchaseIssue {
  missingApiKey,
  offeringsUnavailable,
  iosDebugStoreKitRequired,
}

final premiumPurchaseIssueProvider = Provider<PremiumPurchaseIssue?>((ref) {
  if (shouldDeferRevenueCatOnDebugIosSimulator) {
    return PremiumPurchaseIssue.iosDebugStoreKitRequired;
  }

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
  // Offerings not yet resolved or loaded with packages → no issue
  if (packages == null || packages.isNotEmpty) return null;

  // Offerings resolved but empty → diagnose the issue

  return PremiumPurchaseIssue.offeringsUnavailable;
});

Package? matchPackageForPlan(List<Package> offerings, PremiumPlan plan) {
  final targetType = switch (plan) {
    PremiumPlan.monthly => PackageType.monthly,
    PremiumPlan.semiAnnual => PackageType.sixMonth,
    PremiumPlan.yearly => PackageType.annual,
    PremiumPlan.lifetime => PackageType.lifetime,
  };

  final typedMatches = <Package>[];
  for (final package in offerings) {
    if (package.packageType == targetType) {
      typedMatches.add(package);
    }
  }
  if (typedMatches.isNotEmpty) {
    return _preferActivePremiumPackage(typedMatches);
  }

  final planHints = switch (plan) {
    PremiumPlan.monthly => [
      'monthly',
      'month',
      '1_month',
      '1month',
      r'$rc_monthly',
      ':monthly',
    ],
    PremiumPlan.semiAnnual => [
      'semi_annual',
      'semi-annual',
      'semiannual',
      '6_month',
      '6month',
      'six_month',
      'six-month',
      r'$rc_six_month',
      r'$rc_six-month',
      ':six_month',
      ':six-month',
      ':semi-annual',
    ],
    PremiumPlan.yearly => [
      'annual',
      'yearly',
      'year',
      r'$rc_annual',
      ':yearly',
    ],
    PremiumPlan.lifetime => [
      'lifetime',
      'life_time',
      'one_time',
      'onetime',
      r'$rc_lifetime',
      ':lifetime',
    ],
  };

  // Exclusion patterns to prevent false matches (e.g., 'annual' in 'semi_annual')
  final exclusions = switch (plan) {
    PremiumPlan.monthly => [
      'semi_annual',
      'semi-annual',
      'semiannual',
      'six_month',
      'six-month',
      '6_month',
      '6month',
      'annual',
      'yearly',
      'year',
      'lifetime',
      'life_time',
      'one_time',
      'onetime',
    ],
    PremiumPlan.semiAnnual => [
      'monthly',
      '1_month',
      '1month',
      'lifetime',
      'life_time',
      'one_time',
      'onetime',
    ],
    PremiumPlan.yearly => [
      'semi_annual',
      'semi-annual',
      'semiannual',
      'six_month',
      'six-month',
      '6_month',
      '6month',
      'monthly',
      '1_month',
      '1month',
      'lifetime',
      'life_time',
      'one_time',
      'onetime',
    ],
    PremiumPlan.lifetime => [
      'monthly',
      '1_month',
      '1month',
      'semi_annual',
      'semi-annual',
      'semiannual',
      'six_month',
      'six-month',
      '6_month',
      '6month',
      'annual',
      'yearly',
      'year',
    ],
  };

  final hintedMatches = <Package>[];
  for (final package in offerings) {
    final identifier = package.identifier.toLowerCase();
    final productIdentifier = package.storeProduct.identifier.toLowerCase();

    // Skip packages that match an exclusion pattern
    final excluded = exclusions.any(
      (ex) => identifier.contains(ex) || productIdentifier.contains(ex),
    );
    if (excluded) continue;

    for (final hint in planHints) {
      final normalizedHint = hint.toLowerCase();
      if (identifier.contains(normalizedHint) ||
          productIdentifier.contains(normalizedHint)) {
        hintedMatches.add(package);
        break;
      }
    }
  }

  if (hintedMatches.isEmpty) return null;
  return _preferActivePremiumPackage(hintedMatches);
}

Package? _preferActivePremiumPackage(List<Package> packages) {
  for (final package in packages) {
    final productIdentifier = package.storeProduct.identifier.toLowerCase();
    if (productIdentifier.startsWith('budgie_premium_') ||
        productIdentifier.startsWith('premium_')) {
      return package;
    }
  }

  for (final package in packages) {
    if (!_isLegacyProPackage(package)) return package;
  }

  return null;
}

bool _isLegacyProPackage(Package package) {
  final packageIdentifier = package.identifier.toLowerCase();
  final productIdentifier = package.storeProduct.identifier.toLowerCase();
  return packageIdentifier.startsWith('budgie_pro_') ||
      packageIdentifier.startsWith('legacy_pro_') ||
      productIdentifier.startsWith('budgie_pro_') ||
      productIdentifier.contains('_pro_');
}
