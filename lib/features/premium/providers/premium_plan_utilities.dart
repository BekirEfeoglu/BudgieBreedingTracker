part of 'premium_providers.dart';

/// Available premium plan types.
enum PremiumPlan {
  monthly,
  yearly,
  lifetime;

  /// Resolves a [PremiumPlan] from a RevenueCat product identifier string.
  /// Returns `null` if the product ID doesn't match any known plan.
  static PremiumPlan? fromProductId(String productId) {
    final id = productId.toLowerCase();
    if (id.contains('monthly') || id.contains('month')) return monthly;
    if (id.contains('yearly') || id.contains('annual') || id.contains('year')) {
      return yearly;
    }
    if (id.contains('lifetime') || id.contains('life')) return lifetime;
    return null;
  }
}

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
  // Offerings not yet resolved or loaded with packages → no issue
  if (packages == null || packages.isNotEmpty) return null;

  // Offerings resolved but empty → diagnose the issue

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
