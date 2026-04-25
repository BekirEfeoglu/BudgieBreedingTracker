import 'dart:collection';

import 'package:flutter/foundation.dart';

@visibleForTesting
class LocalAiCache {
  LocalAiCache({
    required this.maxEntries,
    required this.ttl,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final int maxEntries;
  final Duration ttl;
  final DateTime Function() _now;
  final LinkedHashMap<String, _CacheEntry> _entries =
      LinkedHashMap<String, _CacheEntry>();

  Map<String, dynamic>? get(String key) {
    final entry = _entries[key];
    if (entry == null) return null;
    if (_now().difference(entry.createdAt) > ttl) {
      _entries.remove(key);
      return null;
    }
    _entries.remove(key);
    _entries[key] = entry;
    return entry.value;
  }

  void put(String key, Map<String, dynamic> value) {
    _entries.remove(key);
    _entries[key] = _CacheEntry(value: value, createdAt: _now());
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }

  void clear() => _entries.clear();

  int get length => _entries.length;
}

class _CacheEntry {
  const _CacheEntry({required this.value, required this.createdAt});
  final Map<String, dynamic> value;
  final DateTime createdAt;
}
