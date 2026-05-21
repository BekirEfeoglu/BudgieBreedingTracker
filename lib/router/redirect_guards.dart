import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/providers/auth_providers.dart';
import '../features/auth/providers/two_factor_providers.dart';
import 'route_names.dart';
import 'route_utils.dart';

/// Session lock guard — forces login when session is locked.
String? sessionLockRedirect(Ref ref, String location) {
  final isSessionLocked = ref.read(sessionLockedProvider);
  final isAuthRoute = _isAuthRoute(location);
  if (isSessionLocked && !isAuthRoute) return AppRoutes.login;
  return null;
}

/// Auth guard — redirects unauthenticated users to login, and
/// authenticated users away from auth screens.
String? authRedirect(Ref ref, String location) {
  final isLoggedIn = ref.read(isAuthenticatedProvider);
  final isAuthRoute = _isAuthRoute(location);

  if (!isLoggedIn && !isAuthRoute && !isAnonymousAllowedRoute(location)) {
    return AppRoutes.login;
  }
  final isSessionLocked = ref.read(sessionLockedProvider);
  if (isLoggedIn &&
      isAuthRoute &&
      !isSessionLocked &&
      location != AppRoutes.twoFactorVerify) {
    return AppRoutes.home;
  }
  return null;
}

/// 2FA guard — redirects to verify screen if MFA verification is pending.
String? twoFactorRedirect(Ref ref, String location) {
  final isLoggedIn = ref.read(isAuthenticatedProvider);
  final pendingFactorId = ref.read(pendingMfaFactorIdProvider);
  if (isLoggedIn &&
      pendingFactorId != null &&
      location != AppRoutes.twoFactorVerify) {
    // Validate the factor id is a real UUID before threading it into the
    // verify-route URL. The sentinel value `'mfa-required'` is set by the
    // MFA check failure path (auth_providers.dart) when factor lookup
    // throws; passing it through would poison the per-user MFA lockout
    // prefs key on the verify screen and let MFA verification land under
    // a shared key namespace. Force the user back to login instead.
    if (!isValidRouteId(pendingFactorId)) {
      return AppRoutes.login;
    }
    return '${AppRoutes.twoFactorVerify}?factorId='
        '${Uri.encodeQueryComponent(pendingFactorId)}';
  }
  return null;
}

/// Whether the given location is an authentication route.
bool _isAuthRoute(String location) =>
    location == AppRoutes.login ||
    location == AppRoutes.register ||
    location == AppRoutes.authCallback ||
    location == AppRoutes.oauthCallback ||
    location == AppRoutes.emailVerification ||
    location == AppRoutes.forgotPassword ||
    location == AppRoutes.twoFactorVerify;

/// Routes accessible without authentication.
bool isAnonymousAllowedRoute(String location) =>
    location == AppRoutes.maintenance ||
    location == AppRoutes.premium ||
    location == AppRoutes.userGuide ||
    location == AppRoutes.privacyPolicy ||
    location == AppRoutes.termsOfService ||
    location == AppRoutes.communityGuidelines;
