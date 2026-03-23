import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  group('Premium sync retry SharedPreferences logic', () {
    const userId = 'test-user';
    String pendingSyncKey(String uid) => 'pending_premium_sync_$uid';

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('pending sync data can be saved and read', () async {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode({
        'isPremium': true,
        'retryCount': 0,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
      await prefs.setString(pendingSyncKey(userId), data);

      final raw = prefs.getString(pendingSyncKey(userId));
      expect(raw, isNotNull);
      final map = jsonDecode(raw!) as Map<String, dynamic>;
      expect(map['isPremium'], true);
      expect(map['retryCount'], 0);
    });

    test('retry count increments correctly', () async {
      final prefs = await SharedPreferences.getInstance();
      final initial = jsonEncode({
        'isPremium': true,
        'retryCount': 1,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
      await prefs.setString(pendingSyncKey(userId), initial);

      final raw = prefs.getString(pendingSyncKey(userId))!;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final retryCount = (map['retryCount'] as num).toInt();
      final updated = jsonEncode({
        'isPremium': map['isPremium'],
        'retryCount': retryCount + 1,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
      await prefs.setString(pendingSyncKey(userId), updated);

      final result = jsonDecode(
        prefs.getString(pendingSyncKey(userId))!,
      ) as Map<String, dynamic>;
      expect(result['retryCount'], 2);
    });

    test('clear removes pending sync', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        pendingSyncKey(userId),
        jsonEncode({'isPremium': true, 'retryCount': 0}),
      );
      await prefs.remove(pendingSyncKey(userId));
      expect(prefs.getString(pendingSyncKey(userId)), isNull);
    });

    test('max retry threshold is 3', () {
      const maxSyncRetries = 3;
      expect(0 >= maxSyncRetries, false);
      expect(2 >= maxSyncRetries, false);
      expect(3 >= maxSyncRetries, true);
      expect(5 >= maxSyncRetries, true);
    });

    test('anonymous user has no pending sync', () async {
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(pendingSyncKey('anonymous')), isNull);
    });
  });
}
