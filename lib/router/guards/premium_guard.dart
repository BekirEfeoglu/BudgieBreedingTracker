import '../route_names.dart';

/// Guards premium-gated routes (statistics, genealogy, genetics).
///
/// Expects the caller to pass the user's **effective** premium access —
/// i.e. `true` when the user has an active subscription OR is within the
/// grace period. Callers should derive this from `effectivePremiumProvider`
/// (see `lib/domain/services/premium/premium_providers.dart`), not the
/// raw `isPremiumProvider`, so grace-period users are not bounced to the
/// paywall.
class PremiumGuard {
  /// Returns the premium paywall route if the user lacks effective access,
  /// or `null` to allow navigation.
  static String? redirect(bool hasEffectiveAccess) {
    if (!hasEffectiveAccess) return AppRoutes.premium;
    return null;
  }
}
