/// Defensive helpers for parsing untrusted Map payloads (remote API, OAuth
/// metadata, edge function responses).
///
/// Never use `map[key] as String` on payloads the app does not control —
/// malicious or malformed data can crash the app. Use these helpers instead.
library;

/// Returns `map[key]` as a non-empty [String], or `null` if the key is missing,
/// the value is not a [String], or the value is empty / whitespace only.
///
/// Unlike `map[key] as String?`, this does not throw if the value is a non-null
/// non-String (e.g. `int`, `bool`, `List`).
String? safeString(Map<dynamic, dynamic>? map, String key) {
  if (map == null) return null;
  final value = map[key];
  if (value is! String) return null;
  if (value.trim().isEmpty) return null;
  return value;
}

/// Returns `map[key]` as a typed [Map] or `null` if absent / wrong type.
Map<String, dynamic>? safeMap(Map<dynamic, dynamic>? map, String key) {
  if (map == null) return null;
  final value = map[key];
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

/// Returns `map[key]` as a [List] or empty list if absent / wrong type.
List<dynamic> safeList(Map<dynamic, dynamic>? map, String key) {
  if (map == null) return const [];
  final value = map[key];
  if (value is List) return value;
  return const [];
}

/// Casts [raw] to `Map<String, dynamic>` if possible, otherwise `null`.
///
/// Accepts `null`, `Map<String, dynamic>`, and `Map<dynamic, dynamic>`.
/// Returns `null` for any other type (including `List`, `String`, etc.).
Map<String, dynamic>? asStringMap(Object? raw) {
  if (raw == null) return null;
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return null;
}
