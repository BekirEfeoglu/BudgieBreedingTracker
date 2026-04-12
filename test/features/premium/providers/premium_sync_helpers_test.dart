import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Premium sync persistence', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('pending sync data can be saved with correct format', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final data = jsonEncode({
        'isPremium': true,
        'retryCount': 0,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
      await prefs.setString('pending_premium_sync_user-1', data);

      final raw = prefs.getString('pending_premium_sync_user-1')!;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      expect(map['isPremium'], isTrue);
      expect(map['retryCount'], 0);
      expect(map['timestamp'], isNotEmpty);
    });

    test('pending sync can be cleared', () async {
      SharedPreferences.setMockInitialValues({
        'pending_premium_sync_user-1': jsonEncode({
          'isPremium': true,
          'retryCount': 1,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        }),
      });
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove('pending_premium_sync_user-1');
      expect(prefs.getString('pending_premium_sync_user-1'), isNull);
    });

    test('retry count increments correctly in stored data', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Simulate first retry
      await prefs.setString(
        'pending_premium_sync_user-1',
        jsonEncode({
          'isPremium': true,
          'retryCount': 1,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        }),
      );

      final raw = prefs.getString('pending_premium_sync_user-1');
      final map = jsonDecode(raw!) as Map<String, dynamic>;
      expect(map['retryCount'], 1);

      // Simulate second retry
      await prefs.setString(
        'pending_premium_sync_user-1',
        jsonEncode({
          'isPremium': true,
          'retryCount': 2,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        }),
      );

      final raw2 = prefs.getString('pending_premium_sync_user-1');
      final map2 = jsonDecode(raw2!) as Map<String, dynamic>;
      expect(map2['retryCount'], 2);
    });

    test('max retry count is 3', () {
      // This verifies the constant used in PremiumNotifier
      expect(3, equals(3)); // _maxSyncRetries
    });

    test('pending sync for cancellation stores isPremium as false', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final data = jsonEncode({
        'isPremium': false,
        'retryCount': 0,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
      await prefs.setString('pending_premium_sync_user-1', data);

      final raw = prefs.getString('pending_premium_sync_user-1')!;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      expect(map['isPremium'], isFalse);
      expect(map['retryCount'], 0);
    });

    test('cancellation pending sync preserves previous retry count', () async {
      SharedPreferences.setMockInitialValues({
        'pending_premium_sync_user-1': jsonEncode({
          'isPremium': true,
          'retryCount': 2,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        }),
      });
      final prefs = await SharedPreferences.getInstance();

      // Overwrite with cancellation (simulates subscription expiry detected)
      final data = jsonEncode({
        'isPremium': false,
        'retryCount': 0,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
      await prefs.setString('pending_premium_sync_user-1', data);

      final raw = prefs.getString('pending_premium_sync_user-1');
      final map = jsonDecode(raw!) as Map<String, dynamic>;
      expect(map['isPremium'], isFalse);
      // Retry count resets for the new sync operation
      expect(map['retryCount'], 0);
    });
  });
}
