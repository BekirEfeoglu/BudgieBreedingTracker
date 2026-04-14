import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/providers/auth_providers.dart';
import '../features/auth/providers/two_factor_providers.dart';
import 'route_names.dart';

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
  if (isLoggedIn && isAuthRoute && location != AppRoutes.twoFactorVerify) {
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
    return '${AppRoutes.twoFactorVerify}?factorId=$pendingFactorId';
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
    location == AppRoutes.premium ||
    location == AppRoutes.userGuide ||
    location == AppRoutes.privacyPolicy ||
    location == AppRoutes.termsOfService ||
    location == AppRoutes.communityGuidelines;
