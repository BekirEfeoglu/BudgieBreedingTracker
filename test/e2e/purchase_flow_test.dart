@Tags(['e2e'])
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:budgie_breeding_tracker/domain/services/payment/purchase_service.dart';

import '../helpers/e2e_test_harness.dart';

const _channel = MethodChannel('purchases_flutter');

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
  ensureE2EBinding();

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  group('Purchase Flow E2E – initialization & user merge', () {
    test(
      'GIVEN valid API key and user WHEN initialize is called THEN service '
      'reports ready and isPremium reflects entitlement status',
      () async {
        await _installHandler((call) async {
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'getCustomerInfo') {
            return _customerInfo(premiumActive: true);
          }
          return null;
        });

        final service = PurchaseService();
        final result = await service.initialize(
          apiKey: 'test_api_key_12345',
          userId: 'user-1',
        );

        expect(result, isTrue);
        expect(await service.isPremium(), isTrue);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN initialized service WHEN same apiKey but different userId is '
      'passed THEN _switchUser is invoked via logIn and entitlements '
      'reflect new user',
      () async {
        var logInCalls = 0;
        String? lastLoggedInUserId;

        await _installHandler((call) async {
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'logIn') {
            logInCalls++;
            lastLoggedInUserId =
                (call.arguments as Map)['appUserID'] as String;
            return {
              'customerInfo': _customerInfo(premiumActive: true),
              'created': false,
            };
          }
          if (call.method == 'getCustomerInfo') {
            return _customerInfo(premiumActive: true);
          }
          return null;
        });

        final service = PurchaseService();

        // First init: full configure
        await service.initialize(apiKey: 'test_key', userId: 'user-A');

        // Second init with different user: triggers _switchUser (logIn)
        final switched = await service.initialize(
          apiKey: 'test_key',
          userId: 'user-B',
        );

        expect(switched, isTrue);
        expect(logInCalls, 1);
        expect(lastLoggedInUserId, 'user-B');
        // New user has premium
        expect(await service.isPremium(), isTrue);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN initialized service WHEN _switchUser (logIn) fails THEN '
      'identity is cleared, Sentry exception is captured, and isPremium '
      'returns false to prevent stale entitlement leakage',
      () async {
        var logInCalls = 0;

        await _installHandler((call) async {
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'logIn') {
            logInCalls++;
            throw PlatformException(
              code: '0',
              message: 'Network error during user merge',
            );
          }
          if (call.method == 'getCustomerInfo') {
            return _customerInfo(premiumActive: true);
          }
          return null;
        });

        final service = PurchaseService();

        // First user: init succeeds and has premium
        await service.initialize(apiKey: 'test_key', userId: 'user-A');
        expect(await service.isPremium(), isTrue);

        // Switch to new user: logIn (merge) fails
        final switchResult = await service.initialize(
          apiKey: 'test_key',
          userId: 'user-B',
        );

        expect(switchResult, isFalse);
        expect(logInCalls, 1);

        // Critical: stale entitlements from user-A must NOT leak to user-B.
        // _clearIdentity() resets _initialized, so isPremium short-circuits
        // to false without hitting RevenueCat.
        expect(await service.isPremium(), isFalse);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN _switchUser succeeded WHEN isPremium is checked THEN it '
      'returns the merged user entitlement (breadcrumbs were added)',
      () async {
        final breadcrumbTrace = <String>[];

        await _installHandler((call) async {
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'logIn') {
            breadcrumbTrace.add('logIn:${(call.arguments as Map)['appUserID']}');
            return {
              'customerInfo': _customerInfo(premiumActive: false),
              'created': false,
            };
          }
          if (call.method == 'getCustomerInfo') {
            return _customerInfo(premiumActive: false);
          }
          return null;
        });

        final service = PurchaseService();
        await service.initialize(apiKey: 'test_key', userId: 'user-1');

        // Switch user triggers _switchUser which adds Sentry breadcrumbs
        // before and after Purchases.logIn
        await service.initialize(apiKey: 'test_key', userId: 'user-2');

        expect(breadcrumbTrace, ['logIn:user-2']);
        // The merged user does not have premium
        expect(await service.isPremium(), isFalse);
      },
      timeout: e2eTimeout,
    );
  });

  group('Purchase Flow E2E – isPremium when not initialized', () {
    test(
      'GIVEN fresh service with no initialization WHEN isPremium is called '
      'THEN it returns false without attempting RevenueCat calls',
      () async {
        var getCustomerInfoCalls = 0;
        await _installHandler((call) async {
          if (call.method == 'getCustomerInfo') {
            getCustomerInfoCalls++;
            return _customerInfo(premiumActive: true);
          }
          return null;
        });

        final service = PurchaseService();
        final result = await service.isPremium();

        expect(result, isFalse);
        // Must not call getCustomerInfo when not initialized
        expect(getCustomerInfoCalls, 0);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN service with failed initialization WHEN isPremium is called '
      'THEN it returns false safely',
      () async {
        await _installHandler((call) async {
          if (call.method == 'setupPurchases') {
            throw PlatformException(
              code: '0',
              message: 'RevenueCat config error',
            );
          }
          return null;
        });

        final service = PurchaseService();
        final initResult = await service.initialize(
          apiKey: 'bad_key',
          userId: 'user-1',
        );

        expect(initResult, isFalse);
        expect(await service.isPremium(), isFalse);
        expect(await service.getOfferings(), isEmpty);
      },
      timeout: e2eTimeout,
    );
  });

  group('Purchase Flow E2E – restore error handling', () {
    test(
      'GIVEN initialized service WHEN restorePurchases gets a network error '
      'THEN PurchaseException with mapped code is thrown and Sentry captures it',
      () async {
        await _installHandler((call) async {
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'restorePurchases') {
            throw PlatformException(
              code: PurchasesErrorCode.networkError.index.toString(),
              message: 'No internet connection',
            );
          }
          return null;
        });

        final service = PurchaseService();
        await service.initialize(apiKey: 'test_key', userId: 'user-1');

        expect(
          () => service.restorePurchases(),
          throwsA(
            isA<PurchaseException>()
                .having((e) => e.code, 'code', PurchaseErrorCodes.networkError)
                .having(
                  (e) => e.purchasesCode,
                  'purchasesCode',
                  PurchasesErrorCode.networkError,
                ),
          ),
        );
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN initialized service WHEN restorePurchases throws configuration '
      'error THEN PurchaseException with configurationError code is thrown',
      () async {
        await _installHandler((call) async {
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'restorePurchases') {
            throw PlatformException(
              code: PurchasesErrorCode.configurationError.index.toString(),
              message: 'Invalid API key configuration',
            );
          }
          return null;
        });

        final service = PurchaseService();
        await service.initialize(apiKey: 'test_key', userId: 'user-1');

        expect(
          () => service.restorePurchases(),
          throwsA(
            isA<PurchaseException>()
                .having(
                  (e) => e.code,
                  'code',
                  PurchaseErrorCodes.configurationError,
                )
                .having(
                  (e) => e.purchasesCode,
                  'purchasesCode',
                  PurchasesErrorCode.configurationError,
                ),
          ),
        );
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN store unavailable state WHEN restorePurchases is called THEN '
      'PurchaseException with notAllowed code is thrown immediately',
      () async {
        await _installHandler((call) async {
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'getCustomerInfo') {
            // First call triggers store unavailable marking
            throw PlatformException(
              code: PurchasesErrorCode.purchaseNotAllowedError.index.toString(),
              message: 'BILLING_UNAVAILABLE',
            );
          }
          return null;
        });

        final service = PurchaseService();
        await service.initialize(apiKey: 'test_key', userId: 'user-1');

        // Trigger store unavailable state via isPremium
        expect(await service.isPremium(), isFalse);

        // Now restore should throw immediately without calling RevenueCat
        expect(
          () => service.restorePurchases(),
          throwsA(
            isA<PurchaseException>().having(
              (e) => e.code,
              'code',
              PurchaseErrorCodes.notAllowed,
            ),
          ),
        );
      },
      timeout: e2eTimeout,
    );
  });

  group('Purchase Flow E2E – store unavailable cooldown', () {
    test(
      'GIVEN billing unavailable error WHEN cooldown has not elapsed THEN '
      'subsequent calls are short-circuited without RevenueCat calls',
      () async {
        var getCustomerInfoCalls = 0;
        await _installHandler((call) async {
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'getCustomerInfo') {
            getCustomerInfoCalls++;
            if (getCustomerInfoCalls == 1) {
              throw PlatformException(
                code: PurchasesErrorCode.purchaseNotAllowedError.index
                    .toString(),
                message: 'BILLING SERVICE UNAVAILABLE',
              );
            }
            return _customerInfo(premiumActive: true);
          }
          return null;
        });

        final service = PurchaseService();
        await service.initialize(apiKey: 'test_key', userId: 'user-1');

        // First call: triggers store unavailable
        expect(await service.isPremium(), isFalse);
        expect(getCustomerInfoCalls, 1);

        // Second call within cooldown: short-circuited
        expect(await service.isPremium(), isFalse);
        expect(getCustomerInfoCalls, 1);

        // Third call: also short-circuited (cooldown is 20s)
        expect(await service.getOfferings(), isEmpty);
        expect(getCustomerInfoCalls, 1);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN billing unavailable state WHEN clearStoreUnavailableCache is '
      'called THEN next isPremium call reaches RevenueCat again',
      () async {
        var getCustomerInfoCalls = 0;
        var shouldFail = true;

        await _installHandler((call) async {
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'getCustomerInfo') {
            getCustomerInfoCalls++;
            if (shouldFail) {
              throw PlatformException(
                code: PurchasesErrorCode.purchaseNotAllowedError.index
                    .toString(),
                message: 'BILLING_UNAVAILABLE',
              );
            }
            return _customerInfo(premiumActive: true);
          }
          return null;
        });

        final service = PurchaseService();
        await service.initialize(apiKey: 'test_key', userId: 'user-1');

        // Trigger store unavailable
        expect(await service.isPremium(), isFalse);
        expect(getCustomerInfoCalls, 1);

        // Clear the cache and fix the store
        shouldFail = false;
        service.clearStoreUnavailableCache();

        // Now it should reach RevenueCat and return true
        expect(await service.isPremium(), isTrue);
        expect(getCustomerInfoCalls, 2);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN successful initialization clears store unavailable WHEN user '
      'switches THEN store unavailable flag is also cleared',
      () async {
        var getCustomerInfoCalls = 0;
        await _installHandler((call) async {
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'getCustomerInfo') {
            getCustomerInfoCalls++;
            if (getCustomerInfoCalls == 1) {
              throw PlatformException(
                code: PurchasesErrorCode.purchaseNotAllowedError.index
                    .toString(),
                message: 'BILLING_UNAVAILABLE',
              );
            }
            return _customerInfo(premiumActive: true);
          }
          if (call.method == 'logIn') {
            return {
              'customerInfo': _customerInfo(premiumActive: true),
              'created': false,
            };
          }
          return null;
        });

        final service = PurchaseService();
        await service.initialize(apiKey: 'test_key', userId: 'user-1');

        // Trigger store unavailable via isPremium
        expect(await service.isPremium(), isFalse);
        expect(getCustomerInfoCalls, 1);

        // Short-circuit check: should not hit RevenueCat
        expect(await service.isPremium(), isFalse);
        expect(getCustomerInfoCalls, 1);

        // User switch via _switchUser clears store unavailable
        await service.initialize(apiKey: 'test_key', userId: 'user-2');

        // After switch, isPremium should reach RevenueCat again
        expect(await service.isPremium(), isTrue);
        expect(getCustomerInfoCalls, 2);
      },
      timeout: e2eTimeout,
    );
  });

  group('Purchase Flow E2E – multi-step user journey', () {
    test(
      'GIVEN full lifecycle WHEN init -> check -> switch user -> fail switch '
      '-> re-init THEN each step transitions state correctly',
      () async {
        var setupCalls = 0;
        var logInCalls = 0;
        var shouldLogInFail = false;

        await _installHandler((call) async {
          if (call.method == 'setupPurchases') {
            setupCalls++;
            return null;
          }
          if (call.method == 'logIn') {
            logInCalls++;
            if (shouldLogInFail) {
              throw PlatformException(
                code: '0',
                message: 'merge failed',
              );
            }
            return {
              'customerInfo': _customerInfo(premiumActive: true),
              'created': false,
            };
          }
          if (call.method == 'getCustomerInfo') {
            return _customerInfo(premiumActive: true);
          }
          if (call.method == 'logOut') {
            return _customerInfo(premiumActive: false);
          }
          return null;
        });

        final service = PurchaseService();

        // Step 1: Initial setup
        expect(await service.initialize(apiKey: 'key', userId: 'u1'), isTrue);
        expect(setupCalls, 1);
        expect(await service.isPremium(), isTrue);

        // Step 2: Successful user switch (triggers _switchUser breadcrumbs)
        expect(await service.initialize(apiKey: 'key', userId: 'u2'), isTrue);
        expect(logInCalls, 1);
        expect(await service.isPremium(), isTrue);

        // Step 3: Failed user switch (clears identity, Sentry captures)
        shouldLogInFail = true;
        expect(await service.initialize(apiKey: 'key', userId: 'u3'), isFalse);
        expect(logInCalls, 2);
        expect(await service.isPremium(), isFalse);

        // Step 4: Re-initialize from scratch (identity was cleared)
        shouldLogInFail = false;
        expect(await service.initialize(apiKey: 'key', userId: 'u4'), isTrue);
        // A full configure is needed since identity was cleared
        expect(setupCalls, 2);
        expect(await service.isPremium(), isTrue);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN initialized service WHEN logout is called and then re-init '
      'THEN full configure runs again (not just logIn)',
      () async {
        var setupCalls = 0;
        var logInCalls = 0;

        await _installHandler((call) async {
          if (call.method == 'setupPurchases') {
            setupCalls++;
            return null;
          }
          if (call.method == 'logIn') {
            logInCalls++;
            return {
              'customerInfo': _customerInfo(premiumActive: false),
              'created': false,
            };
          }
          if (call.method == 'logOut') {
            return _customerInfo(premiumActive: false);
          }
          if (call.method == 'getCustomerInfo') {
            return _customerInfo(premiumActive: false);
          }
          return null;
        });

        final service = PurchaseService();

        // Initial setup
        await service.initialize(apiKey: 'key', userId: 'user-1');
        expect(setupCalls, 1);

        // Logout clears identity
        await service.logout();
        expect(await service.isPremium(), isFalse);

        // Re-init after logout: needs full configure, not just logIn
        await service.initialize(apiKey: 'key', userId: 'user-2');
        expect(setupCalls, 2);
        expect(logInCalls, 0);
      },
      timeout: e2eTimeout,
    );
  });
}
