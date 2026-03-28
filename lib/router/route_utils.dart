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
