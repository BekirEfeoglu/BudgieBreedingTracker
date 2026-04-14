import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../route_names.dart';

/// Guard that restricts routes to founder users only.
class FounderGuard {
  /// Returns a redirect path if the user is not a founder.
  ///
  /// - Loading: redirects to splash (prevent unauthenticated access)
  /// - Error: redirects to home (cannot verify founder status)
  /// - Not founder: redirects to home
  /// - Founder: allows through (returns null)
  static String? redirect(AsyncValue<bool> isFounderAsync) {
    return isFounderAsync.when(
      loading: () => AppRoutes.splash,
      error: (_, __) => AppRoutes.home,
      data: (isFounder) => isFounder ? null : AppRoutes.home,
    );
  }
}
