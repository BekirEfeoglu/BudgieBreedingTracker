import '../route_names.dart';

/// Guards premium-gated routes (statistics, genealogy, genetics).
/// Redirects non-premium users to the paywall screen.
class PremiumGuard {
  /// Returns the premium paywall route if user is not premium,
  /// or null to allow navigation.
  static String? redirect(bool isPremium) {
    if (!isPremium) return AppRoutes.premium;
    return null;
  }
}
