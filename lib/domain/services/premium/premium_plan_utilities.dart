part of 'premium_providers.dart';

/// Available premium plan types.
enum PremiumPlan {
  semiAnnual,
  yearly;

  /// Resolves a [PremiumPlan] from a RevenueCat product identifier string.
  /// Returns `null` if the product ID doesn't match any known plan.
  static PremiumPlan? fromProductId(String productId) {
    final id = productId.toLowerCase();
    if (id.contains('semi_annual') ||
        id.contains('semiannual') ||
        id.contains('6_month') ||
        id.contains('6month')) {
      return semiAnnual;
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
    PremiumPlan.semiAnnual => PackageType.sixMonth,
    PremiumPlan.yearly => PackageType.annual,
  };

  for (final package in offerings) {
    if (package.packageType == targetType) {
      return package;
    }
  }

  final planHints = switch (plan) {
    PremiumPlan.semiAnnual => [
      'semi_annual',
      'semiannual',
      '6_month',
      '6month',
      r'$rc_six_month',
      ':six_month',
    ],
    PremiumPlan.yearly => [
      'annual',
      'yearly',
      'year',
      r'$rc_annual',
      ':yearly',
    ],
  };

  // Exclusion patterns to prevent false matches (e.g., 'annual' in 'semi_annual')
  final exclusions = switch (plan) {
    PremiumPlan.yearly => ['semi_annual', 'semiannual', '6_month', '6month'],
    PremiumPlan.semiAnnual => <String>[],
  };

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
        return package;
      }
    }
  }

  return null;
}
