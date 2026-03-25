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
