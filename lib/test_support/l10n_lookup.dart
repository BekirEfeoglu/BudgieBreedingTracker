import 'dart:convert';
import 'dart:io';

final Map<String, Map<String, dynamic>> _l10nCache = {};

Map<String, dynamic> _loadLocale(String locale) {
  return _l10nCache.putIfAbsent(locale, () {
    final file = File('assets/translations/$locale.json');
    final raw = file.readAsStringSync();
    return jsonDecode(raw) as Map<String, dynamic>;
  });
}

Object? _resolveKey(Map<String, dynamic> source, String key) {
  Object? current = source;
  for (final part in key.split('.')) {
    if (current is! Map<String, dynamic>) return null;
    current = current[part];
  }
  return current;
}

String l10n(String key, {String locale = 'tr'}) {
  // Most widget tests in this repo do not mount EasyLocalization.
  // Returning the raw key keeps them stable while centralizing lookup sites
  // for future migration to full translated assertions.
  _loadLocale(locale);
  return key;
}

String l10nContains(String key, {String locale = 'tr'}) {
  return l10n(key, locale: locale);
}

String resolvedL10n(String key, {String locale = 'tr'}) {
  final resolved = _resolveKey(_loadLocale(locale), key);
  return resolved is String ? resolved : key;
}

String resolvedL10nContains(String key, {String locale = 'tr'}) {
  return resolvedL10n(key, locale: locale);
}
