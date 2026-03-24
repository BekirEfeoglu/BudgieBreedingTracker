part of 'backup_restorer.dart';

const _helperTag = '[BackupRestorer]';

/// A typed restore step that captures generics via closure.
typedef _RestoreStep = Future<int> Function(
  Map<String, dynamic> data,
  String userId,
  void Function() onError,
);

/// Creates a typed [_RestoreStep] for a given entity.
_RestoreStep _step<T>(
  String key,
  T Function(Map<String, dynamic>) fromJson,
  Future<void> Function(List<T>) saveAll,
) {
  return (data, userId, onError) => _restoreEntity<T>(
    data: data,
    userId: userId,
    key: key,
    fromJson: (json) => fromJson(json as Map<String, dynamic>),
    saveAll: saveAll,
    onError: onError,
  );
}

/// Checks whether [content] looks encrypted (i.e. not valid JSON).
///
/// Valid JSON backup files always start with `{` (possibly after whitespace).
/// Encrypted content is Base64-encoded and will not start with `{`.
bool _looksEncrypted(String content) {
  return !content.trimLeft().startsWith('{');
}

/// Helper to restore a single entity type from backup data.
///
/// Returns the number of successfully restored records.
Future<int> _restoreEntity<T>({
  required Map<String, dynamic> data,
  required String userId,
  required String key,
  required T Function(dynamic json) fromJson,
  required Future<void> Function(List<T> items) saveAll,
  required void Function() onError,
}) async {
  if (!data.containsKey(key)) return 0;

  try {
    final jsonList = data[key] as List;
    if (jsonList.isEmpty) return 0;

    AppLogger.info('$_helperTag Restoring ${jsonList.length} $key');

    final items = <T>[];
    for (final jsonItem in jsonList) {
      try {
        items.add(fromJson(_normalizeUserScope(jsonItem, userId)));
      } catch (e) {
        AppLogger.warning('$_helperTag Failed to parse $key item: $e');
      }
    }

    if (items.isNotEmpty) {
      await saveAll(items);
    }

    AppLogger.info('$_helperTag Restored ${items.length}/${jsonList.length} $key');
    return items.length;
  } catch (e, st) {
    AppLogger.error('$_helperTag Failed to restore $key', e, st);
    onError();
    return 0;
  }
}

/// Forces entity-level `user_id` to match the active restore target.
///
/// This prevents silent cross-account imports when backup payloads contain
/// stale or foreign user ids.
dynamic _normalizeUserScope(dynamic jsonItem, String userId) {
  if (jsonItem is! Map<String, dynamic>) return jsonItem;
  if (!jsonItem.containsKey('user_id')) return jsonItem;
  return <String, dynamic>{...jsonItem, 'user_id': userId};
}
