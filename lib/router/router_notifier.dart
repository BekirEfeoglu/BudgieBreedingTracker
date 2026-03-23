import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/providers/auth_providers.dart';
import '../features/admin/providers/admin_providers.dart';
import '../features/premium/providers/premium_providers.dart';
import '../features/auth/providers/two_factor_providers.dart';

/// Notifier that triggers GoRouter redirect re-evaluation when auth/init state changes.
///
/// This prevents creating a new GoRouter instance on every provider change.
/// Instead, [refreshListenable] notifies the existing router to re-run redirect.
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen(isAuthenticatedProvider, (_, __) => _scheduleNotify());
    _ref.listen(isAdminProvider, (_, __) => _scheduleNotify());
    _ref.listen(isPremiumProvider, (_, __) => _scheduleNotify());
    _ref.listen(appInitializationProvider, (_, __) => _scheduleNotify());
    _ref.listen(initSkippedProvider, (_, __) => _scheduleNotify());
    _ref.listen(pendingMfaFactorIdProvider, (_, __) => _scheduleNotify());
  }

  final Ref _ref;
  bool _scheduled = false;

  /// Coalesce multiple rapid provider changes into a single notification
  /// to prevent GoRouter key reservation conflicts during redirect.
  ///
  /// Uses [addPostFrameCallback] instead of [Future.microtask] to ensure
  /// the notification fires after the current frame's build/layout/paint
  /// phases are complete — preventing Navigator key reservation conflicts
  /// when multiple redirects fire during widget tree construction.
  void _scheduleNotify() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      notifyListeners();
    });
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

// Separate navigator keys for each shell to prevent GlobalKey collisions
final rootNavigatorKey = GlobalKey<NavigatorState>();
final mainShellNavigatorKey = GlobalKey<NavigatorState>();
final adminShellNavigatorKey = GlobalKey<NavigatorState>();
