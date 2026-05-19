import 'package:go_router/go_router.dart';

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
