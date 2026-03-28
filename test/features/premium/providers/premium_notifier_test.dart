
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/bootstrap.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart';

import '../../../helpers/fake_purchase_service.dart';
import '../../../helpers/test_helpers.dart';

class MockPackage extends Mock implements Package {}

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

  group('PremiumNotifier.build', () {
    test('initial state is false before async load completes', () {
      final container = _containerWithService(service);
      addTearDown(container.dispose);

      expect(container.read(localPremiumProvider), isFalse);
    });

    test('loads cached value from SharedPreferences after async', () async {
      SharedPreferences.setMockInitialValues({'is_premium_user-1': true});
      service.isPremiumError = Exception('skip RC');

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      // Trigger the provider and wait for _load to complete
      container.read(localPremiumProvider);
      await waitUntil(() => service.isPremiumCallCount > 0);
      await _flushAsync();

      expect(container.read(localPremiumProvider), isTrue);
    });

    test('syncs with RevenueCat result when it differs from cache', () async {
      SharedPreferences.setMockInitialValues({'is_premium_user-1': false});
      service.isPremiumResult = true;

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      container.read(localPremiumProvider);
      await waitUntil(() => service.isPremiumCallCount > 0);
      await _flushAsync();

      expect(container.read(localPremiumProvider), isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('is_premium_user-1'), isTrue);
    });

    test('handles RevenueCat error gracefully, uses cached value', () async {
      SharedPreferences.setMockInitialValues({'is_premium_user-1': true});
      service.isPremiumError = Exception('RevenueCat unavailable');

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      container.read(localPremiumProvider);
      await waitUntil(() => service.isPremiumCallCount > 0);
      await _flushAsync();

      expect(container.read(localPremiumProvider), isTrue);
    });
  });

  group('PremiumNotifier anonymous user', () {
    test('sets state to false for anonymous user', () async {
      SharedPreferences.setMockInitialValues({'is_premium': true});

      final container = _containerWithService(service, userId: 'anonymous');
      addTearDown(container.dispose);

      container.read(localPremiumProvider);
      await _flushAsync();
      expect(container.read(localPremiumProvider), isFalse);
    });

    test('calls logout on purchase service for anonymous user', () async {
      final container = _containerWithService(service, userId: 'anonymous');
      addTearDown(container.dispose);

      container.read(localPremiumProvider);
      await waitUntil(() => service.logoutCallCount > 0);

      expect(service.logoutCallCount, 1);
    });

    test('removes legacy is_premium key for anonymous user', () async {
      SharedPreferences.setMockInitialValues({'is_premium': true});

      final container = _containerWithService(service, userId: 'anonymous');
      addTearDown(container.dispose);

      container.read(localPremiumProvider);
      await waitUntil(() => service.logoutCallCount > 0);
      await _flushAsync();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('is_premium'), isNull);
    });
  });

  group('PremiumNotifier legacy key migration', () {
    test('migrates legacy is_premium to per-user key', () async {
      SharedPreferences.setMockInitialValues({'is_premium': true});
      service.isPremiumError = Exception('skip RC');

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      container.read(localPremiumProvider);
      await waitUntil(() => service.isPremiumCallCount > 0);
      await _flushAsync();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('is_premium_user-1'), isTrue);
      expect(prefs.getBool('is_premium'), isNull);
    });

    test('does not overwrite existing per-user key with legacy', () async {
      SharedPreferences.setMockInitialValues({
        'is_premium': true,
        'is_premium_user-1': false,
      });
      service.isPremiumError = Exception('skip RC');

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      container.read(localPremiumProvider);
      await waitUntil(() => service.isPremiumCallCount > 0);
      await _flushAsync();

      expect(container.read(localPremiumProvider), isFalse);
    });
  });

  group('PremiumNotifier.setPremium', () {
    test('updates state and persists to SharedPreferences', () async {
      final container = _containerWithService(service);
      addTearDown(container.dispose);

      // Wait for initial _load to complete before calling setPremium
      container.read(localPremiumProvider);
      await waitUntil(() => service.isPremiumCallCount > 0);

      await container.read(localPremiumProvider.notifier).setPremium(true);

      expect(container.read(localPremiumProvider), isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('is_premium_user-1'), isTrue);
    });

    test('removes legacy key on setPremium', () async {
      SharedPreferences.setMockInitialValues({'is_premium': true});

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      container.read(localPremiumProvider);
      await waitUntil(() => service.isPremiumCallCount > 0);

      await container.read(localPremiumProvider.notifier).setPremium(false);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('is_premium'), isNull);
    });

    test('skips persist for anonymous user', () async {
      final container = _containerWithService(service, userId: 'anonymous');
      addTearDown(container.dispose);

      container.read(localPremiumProvider);
      await _flushAsync();

      await container.read(localPremiumProvider.notifier).setPremium(true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('is_premium'), isNull);
    });
  });

  group('PremiumNotifier.purchase', () {
    test('returns true and sets premium on successful purchase', () async {
      service.purchaseResult = true;
      service.isPremiumError = Exception('skip');
      final package = MockPackage();

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      container.read(localPremiumProvider);
      await waitUntil(() => service.isPremiumCallCount > 0);

      final success = await container
          .read(localPremiumProvider.notifier)
          .purchase(package);

      expect(success, isTrue);
      expect(container.read(localPremiumProvider), isTrue);
      expect(service.lastPurchasedPackage, same(package));
    });

    test('returns false and does not set premium on failed purchase', () async {
      service.purchaseResult = false;
      service.isPremiumError = Exception('skip');
      final package = MockPackage();

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      container.read(localPremiumProvider);
      await waitUntil(() => service.isPremiumCallCount > 0);

      final success = await container
          .read(localPremiumProvider.notifier)
          .purchase(package);

      expect(success, isFalse);
      expect(container.read(localPremiumProvider), isFalse);
    });
  });

  group('PremiumNotifier.restore', () {
    test('returns true and sets premium on successful restore', () async {
      service.restoreResult = true;
      service.isPremiumError = Exception('skip');

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      container.read(localPremiumProvider);
      await waitUntil(() => service.isPremiumCallCount > 0);

      final success = await container
          .read(localPremiumProvider.notifier)
          .restore();

      expect(success, isTrue);
      expect(container.read(localPremiumProvider), isTrue);
    });

    test('returns false and clears premium on failed restore', () async {
      service.restoreResult = false;

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      container.read(localPremiumProvider);
      await waitUntil(() => service.isPremiumCallCount > 0);

      await container.read(localPremiumProvider.notifier).setPremium(true);
      expect(container.read(localPremiumProvider), isTrue);

      final success = await container
          .read(localPremiumProvider.notifier)
          .restore();

      expect(success, isFalse);
      expect(container.read(localPremiumProvider), isFalse);
    });
  });

  group('PremiumNotifier.refresh', () {
    test('updates state when RevenueCat status changes', () async {
      service.isPremiumResult = false;

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      container.read(localPremiumProvider);
      await waitUntil(() => service.isPremiumCallCount > 0);
      await _flushAsync();
      expect(container.read(localPremiumProvider), isFalse);

      // Simulate status change
      service.isPremiumResult = true;
      service.isPremiumError = null;
      await container.read(localPremiumProvider.notifier).refresh();

      expect(container.read(localPremiumProvider), isTrue);
    });

    test('handles refresh errors gracefully without changing state', () async {
      service.isPremiumResult = false;

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      container.read(localPremiumProvider);
      await waitUntil(() => service.isPremiumCallCount > 0);
      await _flushAsync();

      service.isPremiumError = Exception('network error');
      // Should not throw
      await container.read(localPremiumProvider.notifier).refresh();
      // State should remain unchanged
      expect(container.read(localPremiumProvider), isFalse);
    });
  });

  group('PremiumNotifier per-user isolation', () {
    test('different users have independent premium states', () async {
      SharedPreferences.setMockInitialValues({
        'is_premium_user-1': false,
        'is_premium_user-2': true,
      });
      service.isPremiumError = Exception('skip');

      final container = _containerWithService(service, userId: 'user-1');
      addTearDown(container.dispose);

      container.read(localPremiumProvider);
      await waitUntil(() => service.isPremiumCallCount > 0);
      await _flushAsync();

      expect(container.read(localPremiumProvider), isFalse);
    });

    test('only reads own user cache key', () async {
      SharedPreferences.setMockInitialValues({'is_premium_user-2': true});
      service.isPremiumError = Exception('skip');

      final container = _containerWithService(service, userId: 'user-1');
      addTearDown(container.dispose);

      container.read(localPremiumProvider);
      await waitUntil(() => service.isPremiumCallCount > 0);
      await _flushAsync();

      expect(container.read(localPremiumProvider), isFalse);
    });
  });
}
