import 'package:go_router/go_router.dart';

import 'route_names.dart';

/// Validates that a route parameter looks like a valid UUID v4.
///
/// Prevents injection attacks via deep links with malformed IDs.
/// Used by route builders to validate path parameters before passing
/// them to detail/form screens.
bool isValidRouteId(String? id) {
  if (id == null || id.isEmpty) return false;
  return RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  ).hasMatch(id);
}

/// Extracts the `editId` query parameter and returns it only when it parses
/// as a valid route id. Returns null otherwise (form screens then open in
/// create mode), which is preferred over a NotFoundScreen flicker — the user
/// likely landed via a crafted/stale deep link, not a real attack.
String? validEditIdOrNull(GoRouterState state) =>
    validEditIdFromQuery(state.uri.queryParameters);

/// Same as [validEditIdOrNull] but takes the query map directly so it can be
/// unit-tested without constructing a [GoRouterState].
String? validEditIdFromQuery(Map<String, String> queryParameters) {
  final id = queryParameters['editId'];
  if (id == null) return null;
  return isValidRouteId(id) ? id : null;
}

/// Validates that an email query parameter has a safe, well-formed format.
///
/// Prevents injection of malicious content via deep link email parameters.
/// Only allows standard email characters; rejects control chars and scripts.
bool isValidRouteEmail(String? email) {
  if (email == null || email.isEmpty) return false;
  if (email.length > 254) return false;
  return RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  ).hasMatch(email);
}

/// Returns a safe in-app destination that may be restored after auth.
///
/// Only absolute application paths are accepted. Schemes, authorities,
/// protocol-relative URLs, control characters, auth routes, and excessively
/// long values are rejected so a crafted `returnTo` cannot become an open
/// redirect or an authentication redirect loop.
String? validPostAuthDestination(String? value) {
  if (value == null || value.isEmpty || value.length > 2048) return null;
  if (value.contains(RegExp(r'[\x00-\x1F\x7F]')) || value.contains(r'\')) {
    return null;
  }

  final uri = Uri.tryParse(value);
  if (uri == null ||
      uri.hasScheme ||
      uri.hasAuthority ||
      uri.hasFragment ||
      !uri.path.startsWith('/') ||
      uri.path.startsWith('//')) {
    return null;
  }

  const blockedPaths = {
    AppRoutes.login,
    AppRoutes.register,
    AppRoutes.authCallback,
    AppRoutes.oauthCallback,
    AppRoutes.emailVerification,
    AppRoutes.forgotPassword,
    AppRoutes.twoFactorVerify,
    AppRoutes.splash,
    AppRoutes.maintenance,
  };
  if (blockedPaths.contains(uri.path)) return null;

  return uri.toString();
}

/// Reads and validates a `returnTo` query value from [location].
String? postAuthDestinationFromLocation(String? location) {
  final uri = location == null ? null : Uri.tryParse(location);
  return validPostAuthDestination(uri?.queryParameters['returnTo']);
}

/// Builds a local route with an optional, validated post-auth destination.
String routeWithPostAuthDestination(String route, String? destination) {
  final safeDestination = validPostAuthDestination(destination);
  if (safeDestination == null || safeDestination == AppRoutes.home) {
    return route;
  }
  return Uri(
    path: route,
    queryParameters: {'returnTo': safeDestination},
  ).toString();
}

String loginLocationFor(String? destination) =>
    routeWithPostAuthDestination(AppRoutes.login, destination);

String twoFactorVerificationLocation(String factorId, {String? destination}) {
  final query = <String, String>{'factorId': factorId};
  final safeDestination = validPostAuthDestination(destination);
  if (safeDestination != null && safeDestination != AppRoutes.home) {
    query['returnTo'] = safeDestination;
  }
  return Uri(
    path: AppRoutes.twoFactorVerify,
    queryParameters: query,
  ).toString();
}
