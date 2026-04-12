import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../route_names.dart';

/// Guard that restricts /admin/* routes to admin users.
class AdminGuard {
  /// Returns a redirect path if the user should not access admin routes.
  ///
  /// - Loading: redirects to splash (prevent unauthenticated access)
  /// - Error: redirects to home (cannot verify admin status)
  /// - Not admin: redirects to home
  /// - Admin: allows through (returns null)
  static String? redirect(AsyncValue<bool> isAdminAsync) {
    return isAdminAsync.when(
      loading: () => AppRoutes.splash,
      error: (_, __) => AppRoutes.home,
      data: (isAdmin) => isAdmin ? null : AppRoutes.home,
    );
  }
}
