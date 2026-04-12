part of 'budgie_color_resolver.dart';

/// Detects and resolves pied pattern modifiers.
///
/// Returns non-null with modified colors if any pied variant is present
/// and the phenotype is not Dark-Eyed Clear.
({Color body, Color piedPatch, Color wingFill})? _detectAndApplyPied({
  required Set<String> ids,
  required String lower,
  required bool isDarkEyedClear,
  required Color body,
  required Color mask,
  required Color wingFill,
}) {
  if (isDarkEyedClear) return null;

  final hasRecessivePied =
      ids.contains('recessive_pied') || lower.contains('recessive pied');
  final hasDominantPied =
      ids.contains('dominant_pied') || lower.contains('dominant pied');
  final hasClearflightPied =
      ids.contains('clearflight_pied') || lower.contains('clearflight pied');
  final hasDutchPied =
      ids.contains('dutch_pied') || lower.contains('dutch pied');

  if (!(hasRecessivePied ||
      hasDominantPied ||
      hasClearflightPied ||
      hasDutchPied)) {
    return null;
  }

  var modBody = body;
  var modWingFill = wingFill;
  if (hasRecessivePied) modBody = _mix(body, mask, 0.10);
  if (hasClearflightPied) modWingFill = mask.withValues(alpha: 0.28);

  return (
    body: modBody,
    piedPatch: _mix(mask, body, 0.30),
    wingFill: modWingFill,
  );
}
