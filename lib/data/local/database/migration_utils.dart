import 'package:flutter/foundation.dart' show visibleForTesting;

/// Regex for safe SQL identifiers (lowercase letters and underscores only).
/// Used by migration helpers to prevent SQL injection in PRAGMA queries.
final _identifierRegex = RegExp(r'^[a-z_]+$');

/// Validates that [value] is a safe SQL identifier (lowercase a-z and _).
///
/// Throws [ArgumentError] if the value contains characters outside [a-z_],
/// which could indicate a SQL injection attempt.
void assertSafeIdentifier(String value) {
  if (!_identifierRegex.hasMatch(value)) {
    throw ArgumentError(
      'Expected a safe SQL identifier (a-z, _), got: "$value"',
    );
  }
}

/// Returns true if [value] matches the safe SQL identifier pattern.
@visibleForTesting
bool isSafeIdentifier(String value) => _identifierRegex.hasMatch(value);
