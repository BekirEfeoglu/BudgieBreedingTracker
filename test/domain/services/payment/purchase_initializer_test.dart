import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:budgie_breeding_tracker/domain/services/payment/purchase_error_mapper.dart';
import 'package:budgie_breeding_tracker/domain/services/payment/purchase_initializer.dart';

const _channel = MethodChannel('purchases_flutter');

/// Concrete class to test [PurchaseInitializer] mixin.
/// PurchaseInitializer requires PurchaseErrorMapper, so we mix both in.
class _TestInitializer with PurchaseErrorMapper, PurchaseInitializer {}

Map<String, dynamic> _customerInfo({required bool premiumActive}) {
  final entitlement = {
    'identifier': 'premium',
    'isActive': premiumActive,
    'willRenew': true,
    'latestPurchaseDate': '2026-01-01T00:00:00Z',
    'originalPurchaseDate': '2026-01-01T00:00:00Z',
    'productIdentifier': 'premium_monthly',
    'isSandbox': true,
    'ownershipType': 'PURCHASED',
    'store': 'APP_STORE',
    'periodType': 'NORMAL',
    'expirationDate': '2026-12-31T00:00:00Z',
    'verification': 'NOT_REQUESTED',
  };

  return {
    'entitlements': {
      'all': {'premium': entitlement},
      'active':
          premiumActive ? {'premium': entitlement} : <String, dynamic>{},
      'verification': 'NOT_REQUESTED',
    },
    'allPurchaseDates': {'premium_monthly': '2026-01-01T00:00:00Z'},
    'activeSubscriptions':
        premiumActive ? ['premium_monthly'] : <String>[],
    'allPurchasedProductIdentifiers': ['premium_monthly'],
    'nonSubscriptionTransactions': <Map<String, dynamic>>[],
    'firstSeen': '2026-01-01T00:00:00Z',
    'originalAppUserId': 'user-1',
    'allExpirationDates': {'premium_monthly': '2026-12-31T00:00:00Z'},
    'requestDate': '2026-01-01T00:00:00Z',
  };
}

Future<void> _installHandler(
  Future<dynamic> Function(MethodCall call) handler,
) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, handler);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _TestInitializer initializer;

  setUp(() {
    initializer = _TestInitializer();
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  group('PurchaseInitializer', () {
    group('isInitialized', () {
      test('returns false before initialization', () {
        expect(initializer.isInitialized, isFalse);
      });

      test('returns true after successful initialization', () async {
        await _installHandler((call) async {
          if (call.method == 'setupPurchases') return null;
          return null;
        });

        await initializer.initialize(
          apiKey: 'test_api_key',
          userId: 'user-1',
        );

        expect(initializer.isInitialized, isTrue);
      });

      test('returns false after failed initialization', () async {
        await _installHandler((call) async {
          if (call.method == 'setupPurchases') {
            throw PlatformException(code: '0', message: 'init failed');
          }
          return null;
        });

        await initializer.initialize(
          apiKey: 'test_api_key',
          userId: 'user-1',
        );

        expect(initializer.isInitialized, isFalse);
      });
    });

    group('initialize - configure path', () {
      test('returns true on successful first-time setup', () async {
        await _installHandler((call) async {
          if (call.method == 'setupPurchases') return null;
          return null;
        });

        final result = await initializer.initialize(
          apiKey: 'test_api_key',
          userId: 'user-1',
        );

        expect(result, isTrue);
        expect(initializer.isInitialized, isTrue);
      });

      test('calls Purchases.configure with correct API key', () async {
        Map<dynamic, dynamic>? configArgs;
        await _installHandler((call) async {
          if (call.method == 'setupPurchases') {
            configArgs = call.arguments as Map<dynamic, dynamic>;
            return null;
          }
          return null;
        });

        await initializer.initialize(
          apiKey: 'rc_test_key_123',
          userId: 'user-42',
        );

        expect(configArgs, isNotNull);
        expect(configArgs!['apiKey'], 'rc_test_key_123');
      });

      test('returns false when Purchases.configure throws', () async {
        await _installHandler((call) async {
          if (call.method == 'setupPurchases') {
            throw PlatformException(
              code: 'CONFIG_ERROR',
              message: 'Invalid API key',
            );
          }
          return null;
        });

        final result = await initializer.initialize(
          apiKey: 'invalid_key',
          userId: 'user-1',
        );

        expect(result, isFalse);
        expect(initializer.isInitialized, isFalse);
      });

      test('clears identity on configuration failure', () async {
        // First succeed
        await _installHandler((call) async {
          if (call.method == 'setupPurchases') return null;
          return null;
        });
        await initializer.initialize(
          apiKey: 'key_v1',
          userId: 'user-1',
        );
        expect(initializer.isInitialized, isTrue);

        // Now try with a different key that fails
        await _installHandler((call) async {
          if (call.method == 'setupPurchases') {
            throw PlatformException(code: '0', message: 'config failed');
          }
          return null;
        });
        await initializer.initialize(
          apiKey: 'key_v2',
          userId: 'user-1',
        );

        expect(initializer.isInitialized, isFalse);
      });

      test('clears store unavailable state on successful configure', () async {
        // Mark store unavailable first
        final billingError = PlatformException(
          code: PurchasesErrorCode.purchaseNotAllowedError.index.toString(),
          message: 'BILLING_UNAVAILABLE',
        );
        initializer.markStoreUnavailableIfNeeded(billingError);
        expect(initializer.isStoreUnavailableNow(), isTrue);

        // Initialize should clear the state
        await _installHandler((call) async {
          if (call.method == 'setupPurchases') return null;
          return null;
        });
        await initializer.initialize(
          apiKey: 'test_key',
          userId: 'user-1',
        );

        expect(initializer.isStoreUnavailableNow(), isFalse);
      });
    });

    group('initialize - idempotent when same credentials', () {
      test('returns true immediately for same apiKey and userId', () async {
        var setupCalls = 0;
        await _installHandler((call) async {
          if (call.method == 'setupPurchases') {
            setupCalls++;
            return null;
          }
          return null;
        });

        await initializer.initialize(
          apiKey: 'test_key',
          userId: 'user-1',
        );
        final result = await initializer.initialize(
          apiKey: 'test_key',
          userId: 'user-1',
        );

        expect(result, isTrue);
        expect(setupCalls, 1);
      });
    });

    group('initialize - concurrent call deduplication', () {
      test('returns same future for concurrent calls', () async {
        var setupCalls = 0;
        final completer = Completer<void>();

        await _installHandler((call) async {
          if (call.method == 'setupPurchases') {
            setupCalls++;
            await completer.future;
            return null;
          }
          return null;
        });

        final first = initializer.initialize(
          apiKey: 'test_key',
          userId: 'user-1',
        );
        final second = initializer.initialize(
          apiKey: 'test_key',
          userId: 'user-1',
        );

        await Future<void>.delayed(Duration.zero);
        expect(setupCalls, 1);

        completer.complete();

        expect(await first, isTrue);
        expect(await second, isTrue);
      });

      test('clears initialization future after completion', () async {
        await _installHandler((call) async {
          if (call.method == 'setupPurchases') return null;
          return null;
        });

        await initializer.initialize(
          apiKey: 'test_key',
          userId: 'user-1',
        );

        // Second call with same credentials should be idempotent
        // (not use stale future)
        final result = await initializer.initialize(
          apiKey: 'test_key',
          userId: 'user-1',
        );
        expect(result, isTrue);
      });

      test('clears initialization future after failure', () async {
        var calls = 0;
        await _installHandler((call) async {
          if (call.method == 'setupPurchases') {
            calls++;
            if (calls == 1) {
              throw PlatformException(code: '0', message: 'fail');
            }
            return null;
          }
          return null;
        });

        // First call fails
        final first = await initializer.initialize(
          apiKey: 'test_key',
          userId: 'user-1',
        );
        expect(first, isFalse);

        // Second call should retry (not return stale future)
        final second = await initializer.initialize(
          apiKey: 'test_key',
          userId: 'user-1',
        );
        expect(second, isTrue);
        expect(calls, 2);
      });
    });

    group('initialize - user switch path', () {
      test('calls logIn when userId changes but apiKey is same', () async {
        var setupCalls = 0;
        var loginCalls = 0;
        String? loggedInUserId;

        await _installHandler((call) async {
          if (call.method == 'setupPurchases') {
            setupCalls++;
            return null;
          }
          if (call.method == 'logIn') {
            loginCalls++;
            loggedInUserId = (call.arguments as Map)['appUserID'] as String;
            return {
              'customerInfo': _customerInfo(premiumActive: false),
              'created': false,
            };
          }
          return null;
        });

        await initializer.initialize(
          apiKey: 'test_key',
          userId: 'user-1',
        );
        await initializer.initialize(
          apiKey: 'test_key',
          userId: 'user-2',
        );

        expect(setupCalls, 1);
        expect(loginCalls, 1);
        expect(loggedInUserId, 'user-2');
      });

      test('updates configured userId after successful switch', () async {
        await _installHandler((call) async {
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'logIn') {
            return {
              'customerInfo': _customerInfo(premiumActive: false),
              'created': false,
            };
          }
          return null;
        });

        await initializer.initialize(
          apiKey: 'test_key',
          userId: 'user-1',
        );
        final result = await initializer.initialize(
          apiKey: 'test_key',
          userId: 'user-2',
        );

        expect(result, isTrue);
        expect(initializer.isInitialized, isTrue);
      });

      test('clears store unavailable state on successful switch', () async {
        await _installHandler((call) async {
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'logIn') {
            return {
              'customerInfo': _customerInfo(premiumActive: false),
              'created': false,
            };
          }
          return null;
        });

        await initializer.initialize(
          apiKey: 'test_key',
          userId: 'user-1',
        );

        // Mark store unavailable
        final billingError = PlatformException(
          code: PurchasesErrorCode.purchaseNotAllowedError.index.toString(),
          message: 'BILLING_UNAVAILABLE',
        );
        initializer.markStoreUnavailableIfNeeded(billingError);
        expect(initializer.isStoreUnavailableNow(), isTrue);

        // Switch user
        await initializer.initialize(
          apiKey: 'test_key',
          userId: 'user-2',
        );

        expect(initializer.isStoreUnavailableNow(), isFalse);
      });

      test('clears identity when user switch fails', () async {
        await _installHandler((call) async {
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'logIn') {
            throw PlatformException(code: '0', message: 'login failed');
          }
          return null;
        });

        await initializer.initialize(
          apiKey: 'test_key',
          userId: 'user-1',
        );
        expect(initializer.isInitialized, isTrue);

        final result = await initializer.initialize(
          apiKey: 'test_key',
          userId: 'user-2',
        );

        expect(result, isFalse);
        expect(initializer.isInitialized, isFalse);
      });

      test('does full configure when apiKey changes', () async {
        var setupCalls = 0;
        var loginCalls = 0;

        await _installHandler((call) async {
          if (call.method == 'setupPurchases') {
            setupCalls++;
            return null;
          }
          if (call.method == 'logIn') {
            loginCalls++;
            return {
              'customerInfo': _customerInfo(premiumActive: false),
              'created': false,
            };
          }
          return null;
        });

        await initializer.initialize(
          apiKey: 'key_v1',
          userId: 'user-1',
        );
        await initializer.initialize(
          apiKey: 'key_v2',
          userId: 'user-1',
        );

        // Different apiKey should trigger full configure, not logIn
        expect(setupCalls, 2);
        expect(loginCalls, 0);
      });
    });

    group('logout', () {
      test('calls Purchases.logOut when initialized', () async {
        var logoutCalls = 0;
        await _installHandler((call) async {
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'logOut') {
            logoutCalls++;
            return _customerInfo(premiumActive: false);
          }
          return null;
        });

        await initializer.initialize(
          apiKey: 'test_key',
          userId: 'user-1',
        );
        await initializer.logout();

        expect(logoutCalls, 1);
      });

      test('is a no-op before initialization', () async {
        var logoutCalls = 0;
        await _installHandler((call) async {
          if (call.method == 'logOut') logoutCalls++;
          return null;
        });

        await initializer.logout();

        expect(logoutCalls, 0);
      });

      test('clears identity after successful logout', () async {
        await _installHandler((call) async {
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'logOut') {
            return _customerInfo(premiumActive: false);
          }
          return null;
        });

        await initializer.initialize(
          apiKey: 'test_key',
          userId: 'user-1',
        );
        expect(initializer.isInitialized, isTrue);

        await initializer.logout();

        expect(initializer.isInitialized, isFalse);
      });

      test('clears identity even when Purchases.logOut throws', () async {
        await _installHandler((call) async {
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'logOut') {
            throw PlatformException(code: '0', message: 'logout failed');
          }
          return null;
        });

        await initializer.initialize(
          apiKey: 'test_key',
          userId: 'user-1',
        );
        expect(initializer.isInitialized, isTrue);

        await initializer.logout();

        expect(initializer.isInitialized, isFalse);
      });

      test('clears store unavailable state on logout', () async {
        await _installHandler((call) async {
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'logOut') {
            return _customerInfo(premiumActive: false);
          }
          return null;
        });

        await initializer.initialize(
          apiKey: 'test_key',
          userId: 'user-1',
        );

        // Mark store unavailable
        final billingError = PlatformException(
          code: PurchasesErrorCode.purchaseNotAllowedError.index.toString(),
          message: 'BILLING_UNAVAILABLE',
        );
        initializer.markStoreUnavailableIfNeeded(billingError);
        expect(initializer.isStoreUnavailableNow(), isTrue);

        await initializer.logout();

        expect(initializer.isStoreUnavailableNow(), isFalse);
      });
    });

    group('clearIdentity', () {
      test('resets all identity state', () async {
        await _installHandler((call) async {
          if (call.method == 'setupPurchases') return null;
          return null;
        });

        await initializer.initialize(
          apiKey: 'test_key',
          userId: 'user-1',
        );
        expect(initializer.isInitialized, isTrue);

        initializer.clearIdentity();

        expect(initializer.isInitialized, isFalse);
      });

      test('clears store unavailable state', () async {
        final billingError = PlatformException(
          code: PurchasesErrorCode.purchaseNotAllowedError.index.toString(),
          message: 'BILLING_UNAVAILABLE',
        );
        initializer.markStoreUnavailableIfNeeded(billingError);
        expect(initializer.isStoreUnavailableNow(), isTrue);

        initializer.clearIdentity();

        expect(initializer.isStoreUnavailableNow(), isFalse);
      });

      test('is safe to call multiple times', () {
        initializer.clearIdentity();
        initializer.clearIdentity();

        expect(initializer.isInitialized, isFalse);
      });

      test('allows re-initialization after clearing', () async {
        var setupCalls = 0;
        await _installHandler((call) async {
          if (call.method == 'setupPurchases') {
            setupCalls++;
            return null;
          }
          return null;
        });

        await initializer.initialize(
          apiKey: 'test_key',
          userId: 'user-1',
        );
        expect(setupCalls, 1);

        initializer.clearIdentity();

        await initializer.initialize(
          apiKey: 'test_key',
          userId: 'user-1',
        );
        expect(setupCalls, 2);
        expect(initializer.isInitialized, isTrue);
      });
    });

    group('API key masking', () {
      test('configure succeeds with short API key', () async {
        await _installHandler((call) async {
          if (call.method == 'setupPurchases') return null;
          return null;
        });

        // API key <= 8 chars should use '***' mask
        final result = await initializer.initialize(
          apiKey: 'short',
          userId: 'user-1',
        );

        expect(result, isTrue);
      });

      test('configure succeeds with long API key', () async {
        await _installHandler((call) async {
          if (call.method == 'setupPurchases') return null;
          return null;
        });

        // API key > 8 chars should show first 8 chars + '...'
        final result = await initializer.initialize(
          apiKey: 'rc_test_api_key_very_long_12345',
          userId: 'user-1',
        );

        expect(result, isTrue);
      });
    });
  });
}
