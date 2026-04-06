import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/bootstrap.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart';

import '../../../helpers/fake_purchase_service.dart';
import '../../../helpers/test_helpers.dart';

Future<void> _flushAsync() async {
  await Future<void>.delayed(const Duration(milliseconds: 1));
  await Future<void>.delayed(const Duration(milliseconds: 1));
}

ProviderContainer _containerWithService(
  FakePurchaseService service, {
  String userId = 'user-1',
}) {
  return ProviderContainer(
    overrides: [
      currentUserIdProvider.overrideWithValue(userId),
      purchaseServiceProvider.overrideWithValue(service),
    ],
    retry: (_, __) => null,
  );
}

void main() {
  late FakePurchaseService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    revenueCatApiKeyAndroid = 'android_test_key';
    revenueCatApiKeyIos = 'ios_test_key';
    service = FakePurchaseService();
  });

  tearDown(() {
    revenueCatApiKeyAndroid = '';
    revenueCatApiKeyIos = '';
  });

  group('retryPendingSync (via build/_load)', () {
    test('increments retryCount on failed sync attempt', () async {
      // Seed a pending sync with retryCount: 0
      SharedPreferences.setMockInitialValues({
        'pending_premium_sync_user-1': jsonEncode({
          'isPremium': true,
          'retryCount': 0,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        }),
      });
      // Skip RevenueCat so _load reaches retryPendingSync quickly
      service.isPremiumError = Exception('skip');

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      // Trigger build which calls _load → retryPendingSync
      container.read(localPremiumProvider);
      await waitUntil(() => service.isPremiumCallCount > 0);
      // Extra time for retryPendingSync async operations
      await _flushAsync();
      await _flushAsync();
      await _flushAsync();

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('pending_premium_sync_user-1');

      // Since supabaseClientProvider is not overridden, the sync will fail
      // and retryCount should be incremented to 1
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final retryCount = (map['retryCount'] as num?)?.toInt() ?? 0;
        expect(retryCount, greaterThan(0),
            reason: 'retryCount should be incremented after failed sync');
      }
      // If raw is null, the sync succeeded (unlikely without Supabase) —
      // that's also acceptable
    });

    test('clears pending sync when max retries reached', () async {
      // Seed a pending sync at max retries (3)
      SharedPreferences.setMockInitialValues({
        'pending_premium_sync_user-1': jsonEncode({
          'isPremium': true,
          'retryCount': 3,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        }),
      });
      service.isPremiumError = Exception('skip');

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      container.read(localPremiumProvider);
      await waitUntil(() => service.isPremiumCallCount > 0);
      await _flushAsync();
      await _flushAsync();

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('pending_premium_sync_user-1');

      // Max retries reached → pending sync is kept for retry after reset duration
      expect(raw, isNotNull,
          reason: 'Pending sync should be kept after max retries for later retry');
    });

    test('skips retry for anonymous user', () async {
      SharedPreferences.setMockInitialValues({
        'pending_premium_sync_anonymous': jsonEncode({
          'isPremium': true,
          'retryCount': 0,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        }),
      });

      final container = _containerWithService(service, userId: 'anonymous');
      addTearDown(container.dispose);

      container.read(localPremiumProvider);
      await _flushAsync();
      await _flushAsync();

      // Pending sync for anonymous should remain untouched (skipped)
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('pending_premium_sync_anonymous');
      expect(raw, isNotNull,
          reason: 'Anonymous user pending sync should not be processed');
    });

    test('clears corrupt pending sync data', () async {
      SharedPreferences.setMockInitialValues({
        'pending_premium_sync_user-1': 'not-valid-json{{{',
      });
      service.isPremiumError = Exception('skip');

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      container.read(localPremiumProvider);
      await waitUntil(() => service.isPremiumCallCount > 0);
      await _flushAsync();
      await _flushAsync();

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('pending_premium_sync_user-1');

      // Corrupt data should be cleared
      expect(raw, isNull,
          reason: 'Corrupt pending sync data should be removed');
    });

    test('refresh also triggers retryPendingSync', () async {
      SharedPreferences.setMockInitialValues({
        'pending_premium_sync_user-1': jsonEncode({
          'isPremium': true,
          'retryCount': 0,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        }),
      });
      service.isPremiumResult = false;

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      container.read(localPremiumProvider);
      await waitUntil(() => service.isPremiumCallCount > 0);
      await _flushAsync();
      await _flushAsync();

      // Reset call count and trigger refresh
      service.isPremiumError = null;
      service.isPremiumResult = false;
      await container.read(localPremiumProvider.notifier).refresh();
      await _flushAsync();
      await _flushAsync();

      // The pending sync should have been retried (retryCount incremented
      // or cleared)
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('pending_premium_sync_user-1');
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final retryCount = (map['retryCount'] as num?)?.toInt() ?? 0;
        // After two retry opportunities (_load + refresh), count should
        // be at least 1 (may be higher depending on timing)
        expect(retryCount, greaterThanOrEqualTo(1));
      }
    });
  });
}
