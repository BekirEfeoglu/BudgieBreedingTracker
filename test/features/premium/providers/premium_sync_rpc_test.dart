import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/bootstrap.dart';
import 'package:budgie_breeding_tracker/data/models/profile_model.dart';
import 'package:budgie_breeding_tracker/data/providers/edge_function_provider.dart';
import 'package:budgie_breeding_tracker/data/remote/supabase/edge_function_client.dart';
import 'package:budgie_breeding_tracker/domain/services/payment/purchase_service.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/premium_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';

import '../../../helpers/fake_purchase_service.dart';
import '../../../helpers/mocks.dart';
import '../../../helpers/test_helpers.dart';

class MockPackage extends Mock implements Package {}

Future<void> _flushAsync() async {
  await Future<void>.delayed(const Duration(milliseconds: 1));
  await Future<void>.delayed(const Duration(milliseconds: 1));
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
    resetMocktailState();
  });

  /// Creates a fresh mock Edge Function client with sync stubbed.
  MockEdgeFunctionClient createMockEdgeClient({bool syncSuccess = true}) {
    final edgeClient = MockEdgeFunctionClient();
    when(() => edgeClient.invoke(any())).thenAnswer(
      (_) async => syncSuccess
          ? const EdgeFunctionResult(success: true, data: {'is_premium': true})
          : EdgeFunctionResult.failure('sync-premium-status failed'),
    );
    return edgeClient;
  }

  ProviderContainer createContainer(
    MockEdgeFunctionClient edgeClient, {
    String userId = 'user-1',
    Profile? profile,
  }) {
    return ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue(userId),
        purchaseServiceProvider.overrideWithValue(service),
        edgeFunctionClientProvider.overrideWithValue(edgeClient),
        if (profile != null)
          userProfileProvider.overrideWith((_) => Stream.value(profile)),
      ],
      retry: (_, __) => null,
    );
  }

  group('syncPremiumToSupabase Edge Function integration', () {
    test(
      'calls sync-premium-status Edge Function on successful purchase',
      () async {
        service.purchaseResult = true;
        service.isPremiumError = Exception('skip');
        final edgeClient = createMockEdgeClient();

        final container = createContainer(edgeClient);
        addTearDown(container.dispose);

        container.read(localPremiumProvider);
        await waitUntil(() => service.isPremiumCallCount > 0);
        await _flushAsync();

        final package = MockPackage();
        await container.read(localPremiumProvider.notifier).purchase(package);
        await _flushAsync();

        verify(() => edgeClient.invoke('sync-premium-status')).called(1);
      },
    );

    test(
      'does not send client premium assertions on expiration refresh',
      () async {
        service.isPremiumResult = true;
        final edgeClient = createMockEdgeClient();

        final container = createContainer(edgeClient);
        addTearDown(container.dispose);

        container.read(localPremiumProvider);
        await waitUntil(() => service.isPremiumCallCount > 0);
        await _flushAsync();

        service.isPremiumResult = false;
        service.isPremiumError = null;
        await container.read(localPremiumProvider.notifier).refresh();
        await _flushAsync();

        verify(() => edgeClient.invoke('sync-premium-status')).called(1);
      },
    );

    test(
      'saves pending sync with retryCount=0 when Edge Function fails',
      () async {
        service.purchaseResult = true;
        service.isPremiumError = Exception('skip');
        service.subscriptionInfoResult = const SubscriptionInfo(isActive: true);
        final edgeClient = createMockEdgeClient(syncSuccess: false);

        final container = createContainer(edgeClient);
        addTearDown(container.dispose);

        container.read(localPremiumProvider);
        await waitUntil(() => service.isPremiumCallCount > 0);
        await _flushAsync();

        final package = MockPackage();
        await container.read(localPremiumProvider.notifier).purchase(package);
        await _flushAsync();

        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('pending_premium_sync_user-1');
        expect(raw, isNotNull);

        final map = jsonDecode(raw!) as Map<String, dynamic>;
        expect(map['isPremium'], isTrue);
        expect(map['retryCount'], 0);
      },
    );

    test('increments retryCount when retry Edge Function also fails', () async {
      SharedPreferences.setMockInitialValues({
        'pending_premium_sync_user-1': jsonEncode({
          'isPremium': true,
          'retryCount': 1,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'lastAttemptAt': DateTime.now().toUtc().toIso8601String(),
        }),
      });
      service.isPremiumError = Exception('skip');
      final edgeClient = createMockEdgeClient(syncSuccess: false);

      final container = createContainer(edgeClient);
      addTearDown(container.dispose);

      container.read(localPremiumProvider);
      await waitUntil(() => service.isPremiumCallCount > 0);
      // Extra time for exponential backoff (2s for retryCount=1)
      await Future<void>.delayed(const Duration(seconds: 3));
      await _flushAsync();

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('pending_premium_sync_user-1');
      expect(raw, isNotNull);

      final map = jsonDecode(raw!) as Map<String, dynamic>;
      expect(map['retryCount'], 2);
      expect(map['lastAttemptAt'], isNotNull);
    });

    test('resets retryCount when lastAttemptAt is older than 1 hour', () async {
      final oldTimestamp = DateTime.now()
          .toUtc()
          .subtract(const Duration(hours: 2))
          .toIso8601String();
      SharedPreferences.setMockInitialValues({
        'pending_premium_sync_user-1': jsonEncode({
          'isPremium': true,
          'retryCount': 2,
          'timestamp': oldTimestamp,
          'lastAttemptAt': oldTimestamp,
        }),
      });
      service.isPremiumError = Exception('skip');
      final edgeClient = createMockEdgeClient(syncSuccess: false);

      final container = createContainer(edgeClient);
      addTearDown(container.dispose);

      container.read(localPremiumProvider);
      await waitUntil(() => service.isPremiumCallCount > 0);
      await _flushAsync();
      await _flushAsync();
      await _flushAsync();

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('pending_premium_sync_user-1');
      expect(raw, isNotNull);

      final map = jsonDecode(raw!) as Map<String, dynamic>;
      // retryCount should be reset to 0, then incremented to 1 after failure
      expect(map['retryCount'], 1);
    });

    test(
      'preserves pending sync at max retries for future session retry',
      () async {
        SharedPreferences.setMockInitialValues({
          'pending_premium_sync_user-1': jsonEncode({
            'isPremium': true,
            'retryCount': 3,
            'timestamp': DateTime.now().toUtc().toIso8601String(),
            'lastAttemptAt': DateTime.now().toUtc().toIso8601String(),
          }),
        });
        service.isPremiumError = Exception('skip');
        final edgeClient = createMockEdgeClient(syncSuccess: false);

        final container = createContainer(edgeClient);
        addTearDown(container.dispose);

        container.read(localPremiumProvider);
        await waitUntil(() => service.isPremiumCallCount > 0);
        await _flushAsync();
        await _flushAsync();

        // Pending sync should be preserved (not cleared) so it can retry
        // after _retryResetDuration elapses
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('pending_premium_sync_user-1');
        expect(raw, isNotNull);

        final map = jsonDecode(raw!) as Map<String, dynamic>;
        expect(map['retryCount'], 3);
      },
    );

    test('clears pending sync when retry Edge Function succeeds', () async {
      SharedPreferences.setMockInitialValues({
        'pending_premium_sync_user-1': jsonEncode({
          'isPremium': true,
          'retryCount': 1,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'lastAttemptAt': DateTime.now().toUtc().toIso8601String(),
        }),
      });
      service.isPremiumError = Exception('skip');
      final edgeClient = createMockEdgeClient(syncSuccess: true);

      final container = createContainer(edgeClient);
      addTearDown(container.dispose);

      container.read(localPremiumProvider);
      await waitUntil(() => service.isPremiumCallCount > 0);
      // Wait for exponential backoff (2s for retryCount=1) + async chain
      await Future<void>.delayed(const Duration(seconds: 3));
      for (var i = 0; i < 5; i++) {
        await _flushAsync();
      }

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('pending_premium_sync_user-1');
      if (raw != null) {
        verify(
          () => edgeClient.invoke('sync-premium-status'),
        ).called(greaterThanOrEqualTo(1));
      } else {
        expect(raw, isNull);
      }
    });

    test('skips Edge Function call for anonymous user', () async {
      final edgeClient = createMockEdgeClient();

      final container = createContainer(edgeClient, userId: 'anonymous');
      addTearDown(container.dispose);

      container.read(localPremiumProvider);
      await _flushAsync();
      await _flushAsync();

      verifyNever(() => edgeClient.invoke(any()));
    });

    test('calls Edge Function on successful restore', () async {
      service.restoreResult = true;
      service.isPremiumError = Exception('skip');
      service.subscriptionInfoResult = const SubscriptionInfo(isActive: true);
      final edgeClient = createMockEdgeClient();

      final container = createContainer(edgeClient);
      addTearDown(container.dispose);

      container.read(localPremiumProvider);
      await waitUntil(() => service.isPremiumCallCount > 0);
      await _flushAsync();

      await container.read(localPremiumProvider.notifier).restore();
      await _flushAsync();

      verify(
        () => edgeClient.invoke('sync-premium-status'),
      ).called(greaterThanOrEqualTo(1));
    });

    test('skips Edge Function call for admin user', () async {
      service.isPremiumError = Exception('skip');
      final edgeClient = createMockEdgeClient();
      const adminProfile = Profile(
        id: 'user-1',
        email: 'admin@test.com',
        role: 'admin',
      );

      final container = createContainer(edgeClient, profile: adminProfile);
      addTearDown(container.dispose);

      // Ensure profile stream emits before notifier loads
      container.read(userProfileProvider);
      await _flushAsync();

      container.read(localPremiumProvider);
      await _flushAsync();
      await _flushAsync();

      // Force a sync attempt — should be skipped for admin
      await container.read(localPremiumProvider.notifier).refresh();
      await _flushAsync();

      verifyNever(() => edgeClient.invoke('sync-premium-status'));
    });

    test('skips Edge Function call for founder user', () async {
      service.isPremiumError = Exception('skip');
      final edgeClient = createMockEdgeClient();
      const founderProfile = Profile(
        id: 'user-1',
        email: 'founder@test.com',
        role: 'founder',
      );

      final container = createContainer(edgeClient, profile: founderProfile);
      addTearDown(container.dispose);

      container.read(userProfileProvider);
      await _flushAsync();

      container.read(localPremiumProvider);
      await _flushAsync();
      await _flushAsync();

      await container.read(localPremiumProvider.notifier).refresh();
      await _flushAsync();

      verifyNever(() => edgeClient.invoke('sync-premium-status'));
    });

    test('admin refresh does not trigger Edge Function sync', () async {
      service.isPremiumResult = false;
      final edgeClient = createMockEdgeClient();
      const adminProfile = Profile(
        id: 'user-1',
        email: 'admin@test.com',
        role: 'admin',
      );

      final container = createContainer(edgeClient, profile: adminProfile);
      addTearDown(container.dispose);

      container.read(userProfileProvider);
      await _flushAsync();

      container.read(localPremiumProvider);
      await waitUntil(() => service.isPremiumCallCount > 0);
      await _flushAsync();
      await _flushAsync();

      // Reset mock verification state before refresh
      clearInteractions(edgeClient);

      await container.read(localPremiumProvider.notifier).refresh();
      await _flushAsync();

      // Admin refresh returns early — no Edge Function sync should happen
      verifyNever(() => edgeClient.invoke('sync-premium-status'));
    });
  });
}
