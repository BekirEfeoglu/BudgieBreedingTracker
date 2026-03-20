import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:budgie_breeding_tracker/domain/services/payment/purchase_service.dart';

const _channel = MethodChannel('purchases_flutter');

Map<String, dynamic> _entitlement({
  required bool isActive,
  required bool willRenew,
  required String productId,
  String? expirationDate,
}) {
  return {
    'identifier': 'premium',
    'isActive': isActive,
    'willRenew': willRenew,
    'latestPurchaseDate': '2026-01-01T00:00:00Z',
    'originalPurchaseDate': '2026-01-01T00:00:00Z',
    'productIdentifier': productId,
    'isSandbox': true,
    'ownershipType': 'PURCHASED',
    'store': 'APP_STORE',
    'periodType': 'NORMAL',
    'expirationDate': expirationDate,
    'verification': 'NOT_REQUESTED',
  };
}

Map<String, dynamic> _customerInfo({
  required bool premiumActive,
  bool willRenew = true,
  String productId = 'premium_monthly',
  String? expirationDate = '2026-12-31T00:00:00Z',
}) {
  final entitlement = _entitlement(
    isActive: premiumActive,
    willRenew: willRenew,
    productId: productId,
    expirationDate: expirationDate,
  );

  return {
    'entitlements': {
      'all': {'premium': entitlement},
      'active': premiumActive ? {'premium': entitlement} : <String, dynamic>{},
      'verification': 'NOT_REQUESTED',
    },
    'allPurchaseDates': {productId: '2026-01-01T00:00:00Z'},
    'activeSubscriptions': premiumActive ? [productId] : <String>[],
    'allPurchasedProductIdentifiers': [productId],
    'nonSubscriptionTransactions': <Map<String, dynamic>>[],
    'firstSeen': '2026-01-01T00:00:00Z',
    'originalAppUserId': 'user-1',
    'allExpirationDates': {productId: expirationDate},
    'requestDate': '2026-01-01T00:00:00Z',
  };
}

Map<String, dynamic> _monthlyPackageJson() {
  return {
    'identifier': 'monthly',
    'packageType': 'MONTHLY',
    'product': {
      'identifier': 'premium_monthly',
      'description': 'Monthly premium plan',
      'title': 'Premium Monthly',
      'price': 9.99,
      'priceString': '\$9.99',
      'currencyCode': 'USD',
      'productCategory': 'SUBSCRIPTION',
      'presentedOfferingContext': {
        'offeringIdentifier': 'default',
        'placementIdentifier': null,
        'targetingContext': null,
      },
    },
    'presentedOfferingContext': {
      'offeringIdentifier': 'default',
      'placementIdentifier': null,
      'targetingContext': null,
    },
  };
}

Map<String, dynamic> _transactionJson({
  String identifier = 'txn-123',
  String productId = 'premium_monthly',
  String purchaseDate = '2026-01-01T00:00:00Z',
}) {
  return {
    'transactionIdentifier': identifier,
    'productIdentifier': productId,
    'purchaseDate': purchaseDate,
  };
}

Map<String, dynamic> _offeringsJson() {
  final monthly = _monthlyPackageJson();
  return {
    'all': {
      'default': {
        'identifier': 'default',
        'serverDescription': 'Default offering',
        'metadata': <String, Object>{},
        'availablePackages': [monthly],
        'monthly': monthly,
      },
    },
    'current': {
      'identifier': 'default',
      'serverDescription': 'Default offering',
      'metadata': <String, Object>{},
      'availablePackages': [monthly],
      'monthly': monthly,
    },
  };
}

/// Offerings with no "current" set, but a named offering has packages.
Map<String, dynamic> _offeringsNoCurrent() {
  final monthly = _monthlyPackageJson();
  return {
    'all': {
      'premium_plans': {
        'identifier': 'premium_plans',
        'serverDescription': 'Premium plans offering',
        'metadata': <String, Object>{},
        'availablePackages': [monthly],
        'monthly': monthly,
      },
    },
    'current': null,
  };
}

/// Offerings where current exists but has no packages.
Map<String, dynamic> _offeringsCurrentEmpty() {
  final monthly = _monthlyPackageJson();
  return {
    'all': {
      'default': {
        'identifier': 'default',
        'serverDescription': 'Default offering',
        'metadata': <String, Object>{},
        'availablePackages': <Map<String, dynamic>>[],
      },
      'premium_plans': {
        'identifier': 'premium_plans',
        'serverDescription': 'Premium plans offering',
        'metadata': <String, Object>{},
        'availablePackages': [monthly],
        'monthly': monthly,
      },
    },
    'current': {
      'identifier': 'default',
      'serverDescription': 'Default offering',
      'metadata': <String, Object>{},
      'availablePackages': <Map<String, dynamic>>[],
    },
  };
}

/// All offerings exist but none have packages.
Map<String, dynamic> _offeringsAllEmpty() {
  return {
    'all': {
      'default': {
        'identifier': 'default',
        'serverDescription': 'Default offering',
        'metadata': <String, Object>{},
        'availablePackages': <Map<String, dynamic>>[],
      },
    },
    'current': {
      'identifier': 'default',
      'serverDescription': 'Default offering',
      'metadata': <String, Object>{},
      'availablePackages': <Map<String, dynamic>>[],
    },
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

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  group('PurchaseService', () {
    test('returns safe defaults when service is not initialized', () async {
      final service = PurchaseService();
      final package = Package.fromJson(_monthlyPackageJson());

      expect(await service.isPremium(), isFalse);
      expect(await service.getOfferings(), isEmpty);
      expect(await service.purchasePackage(package), isFalse);
      expect(await service.restorePurchases(), isFalse);

      final info = await service.getSubscriptionInfo();
      expect(info.isActive, isFalse);
      expect(info.expirationDate, isNull);
      expect(info.willRenew, isFalse);
      expect(info.productId, isNull);
    });

    test('initialize is idempotent and configures only once', () async {
      var setupCalls = 0;
      await _installHandler((call) async {
        if (call.method == 'setupPurchases') {
          setupCalls++;
          return null;
        }
        if (call.method == 'getCustomerInfo') {
          return _customerInfo(premiumActive: false);
        }
        return null;
      });

      final service = PurchaseService();

      await service.initialize(apiKey: 'test_key', userId: 'user-1');
      await service.initialize(apiKey: 'test_key', userId: 'user-1');

      expect(setupCalls, 1);
      expect(await service.isPremium(), isFalse);
    });

    test('initialize de-duplicates concurrent setup calls', () async {
      var setupCalls = 0;
      final setupCompleter = Completer<void>();

      await _installHandler((call) async {
        if (call.method == 'setupPurchases') {
          setupCalls++;
          await setupCompleter.future;
          return null;
        }
        return null;
      });

      final service = PurchaseService();
      final firstInit = service.initialize(
        apiKey: 'test_key',
        userId: 'user-1',
      );
      final secondInit = service.initialize(
        apiKey: 'test_key',
        userId: 'user-1',
      );

      await Future<void>.delayed(Duration.zero);
      expect(setupCalls, 1);

      setupCompleter.complete();

      expect(await firstInit, isTrue);
      expect(await secondInit, isTrue);
    });

    test(
      'initialize switches RevenueCat user when auth user changes',
      () async {
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

        final service = PurchaseService();

        expect(
          await service.initialize(apiKey: 'test_key', userId: 'user-1'),
          isTrue,
        );
        expect(
          await service.initialize(apiKey: 'test_key', userId: 'user-2'),
          isTrue,
        );

        expect(setupCalls, 1);
        expect(loginCalls, 1);
        expect(loggedInUserId, 'user-2');
      },
    );

    test('isPremium reads active entitlement from customer info', () async {
      await _installHandler((call) async {
        if (call.method == 'setupPurchases') return null;
        if (call.method == 'getCustomerInfo') {
          return _customerInfo(premiumActive: true);
        }
        return null;
      });

      final service = PurchaseService();
      await service.initialize(apiKey: 'test_key', userId: 'user-1');

      expect(await service.isPremium(), isTrue);
    });

    test('isPremium returns false when getCustomerInfo throws', () async {
      await _installHandler((call) async {
        if (call.method == 'setupPurchases') return null;
        if (call.method == 'getCustomerInfo') {
          throw PlatformException(code: '0', message: 'failure');
        }
        return null;
      });

      final service = PurchaseService();
      await service.initialize(apiKey: 'test_key', userId: 'user-1');

      expect(await service.isPremium(), isFalse);
    });

    test('getOfferings returns current available packages', () async {
      await _installHandler((call) async {
        if (call.method == 'setupPurchases') return null;
        if (call.method == 'getOfferings') return _offeringsJson();
        return null;
      });

      final service = PurchaseService();
      await service.initialize(apiKey: 'test_key', userId: 'user-1');

      final offerings = await service.getOfferings();
      expect(offerings, hasLength(1));
      expect(offerings.first.packageType, PackageType.monthly);
      expect(offerings.first.storeProduct.identifier, 'premium_monthly');
    });

    test(
      'getOfferings falls back to all offerings when current is null',
      () async {
        await _installHandler((call) async {
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'getOfferings') return _offeringsNoCurrent();
          return null;
        });

        final service = PurchaseService();
        await service.initialize(apiKey: 'test_key', userId: 'user-1');

        final offerings = await service.getOfferings();
        expect(offerings, hasLength(1));
        expect(offerings.first.storeProduct.identifier, 'premium_monthly');
      },
    );

    test(
      'getOfferings falls back to all offerings when current has no packages',
      () async {
        await _installHandler((call) async {
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'getOfferings') return _offeringsCurrentEmpty();
          return null;
        });

        final service = PurchaseService();
        await service.initialize(apiKey: 'test_key', userId: 'user-1');

        final offerings = await service.getOfferings();
        expect(offerings, hasLength(1));
        expect(offerings.first.storeProduct.identifier, 'premium_monthly');
      },
    );

    test('getOfferings returns empty when no offering has packages', () async {
      await _installHandler((call) async {
        if (call.method == 'setupPurchases') return null;
        if (call.method == 'getOfferings') return _offeringsAllEmpty();
        return null;
      });

      final service = PurchaseService();
      await service.initialize(apiKey: 'test_key', userId: 'user-1');

      expect(await service.getOfferings(), isEmpty);
    });

    test('getOfferings returns empty list on plugin errors', () async {
      await _installHandler((call) async {
        if (call.method == 'setupPurchases') return null;
        if (call.method == 'getOfferings') {
          throw PlatformException(code: '0', message: 'failure');
        }
        return null;
      });

      final service = PurchaseService();
      await service.initialize(apiKey: 'test_key', userId: 'user-1');

      expect(await service.getOfferings(), isEmpty);
    });

    test(
      'getOfferings disables repeated billing calls after not-allowed error',
      () async {
        var getOfferingsCalls = 0;
        await _installHandler((call) async {
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'getOfferings') {
            getOfferingsCalls++;
            throw PlatformException(
              code: PurchasesErrorCode.purchaseNotAllowedError.index.toString(),
              message: 'Billing service unavailable on device',
            );
          }
          return null;
        });

        final service = PurchaseService();
        await service.initialize(apiKey: 'test_key', userId: 'user-1');

        expect(await service.getOfferings(), isEmpty);
        expect(await service.getOfferings(), isEmpty);
        expect(getOfferingsCalls, 1);
      },
    );

    test(
      'clearStoreUnavailableCache allows retrying offerings after billing error',
      () async {
        var getOfferingsCalls = 0;
        var shouldFail = true;
        await _installHandler((call) async {
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'getOfferings') {
            getOfferingsCalls++;
            if (shouldFail) {
              throw PlatformException(
                code: PurchasesErrorCode.purchaseNotAllowedError.index
                    .toString(),
                message: 'Billing service unavailable on device',
              );
            }
            return _offeringsJson();
          }
          return null;
        });

        final service = PurchaseService();
        await service.initialize(apiKey: 'test_key', userId: 'user-1');

        expect(await service.getOfferings(), isEmpty);
        expect(getOfferingsCalls, 1);

        shouldFail = false;
        service.clearStoreUnavailableCache();

        final offerings = await service.getOfferings();
        expect(getOfferingsCalls, 2);
        expect(offerings, hasLength(1));
      },
    );

    test('purchasePackage returns true when premium becomes active', () async {
      await _installHandler((call) async {
        if (call.method == 'setupPurchases') return null;
        if (call.method == 'purchasePackage') {
          return {
            'customerInfo': _customerInfo(premiumActive: true),
            'transaction': _transactionJson(productId: 'premium_monthly'),
          };
        }
        return null;
      });

      final service = PurchaseService();
      final package = Package.fromJson(_monthlyPackageJson());
      await service.initialize(apiKey: 'test_key', userId: 'user-1');

      expect(await service.purchasePackage(package), isTrue);
    });

    test('purchasePackage returns false when user cancels purchase', () async {
      await _installHandler((call) async {
        if (call.method == 'setupPurchases') return null;
        if (call.method == 'purchasePackage') {
          throw PlatformException(
            code: PurchasesErrorCode.purchaseCancelledError.index.toString(),
            message: 'cancelled',
          );
        }
        return null;
      });

      final service = PurchaseService();
      final package = Package.fromJson(_monthlyPackageJson());
      await service.initialize(apiKey: 'test_key', userId: 'user-1');

      expect(await service.purchasePackage(package), isFalse);
    });

    test('purchasePackage restores already owned purchases', () async {
      await _installHandler((call) async {
        if (call.method == 'setupPurchases') return null;
        if (call.method == 'purchasePackage') {
          throw PlatformException(
            code: PurchasesErrorCode.productAlreadyPurchasedError.index
                .toString(),
            message: 'already purchased',
          );
        }
        if (call.method == 'restorePurchases') {
          return _customerInfo(premiumActive: true);
        }
        if (call.method == 'getCustomerInfo') {
          return _customerInfo(premiumActive: true);
        }
        return null;
      });

      final service = PurchaseService();
      final package = Package.fromJson(_monthlyPackageJson());
      await service.initialize(apiKey: 'test_key', userId: 'user-1');

      expect(await service.purchasePackage(package), isTrue);
    });

    test('purchasePackage throws mapped pending error', () async {
      await _installHandler((call) async {
        if (call.method == 'setupPurchases') return null;
        if (call.method == 'purchasePackage') {
          throw PlatformException(
            code: PurchasesErrorCode.paymentPendingError.index.toString(),
            message: 'pending',
          );
        }
        return null;
      });

      final service = PurchaseService();
      final package = Package.fromJson(_monthlyPackageJson());
      await service.initialize(apiKey: 'test_key', userId: 'user-1');

      expect(
        () => service.purchasePackage(package),
        throwsA(
          isA<PurchaseException>().having(
            (e) => e.code,
            'code',
            'purchase_pending',
          ),
        ),
      );
    });

    test('purchasePackage rethrows non-cancelled purchase errors', () async {
      await _installHandler((call) async {
        if (call.method == 'setupPurchases') return null;
        if (call.method == 'purchasePackage') {
          throw PlatformException(code: '2', message: 'not allowed');
        }
        return null;
      });

      final service = PurchaseService();
      final package = Package.fromJson(_monthlyPackageJson());
      await service.initialize(apiKey: 'test_key', userId: 'user-1');

      expect(
        () => service.purchasePackage(package),
        throwsA(
          isA<PurchaseException>().having(
            (e) => e.code,
            'code',
            'purchase_store_problem',
          ),
        ),
      );
    });

    test('purchasePackage throws when entitlement is not activated', () async {
      await _installHandler((call) async {
        if (call.method == 'setupPurchases') return null;
        if (call.method == 'purchasePackage') {
          return {
            'customerInfo': _customerInfo(premiumActive: false),
            'transaction': _transactionJson(productId: 'premium_monthly'),
          };
        }
        return null;
      });

      final service = PurchaseService();
      final package = Package.fromJson(_monthlyPackageJson());
      await service.initialize(apiKey: 'test_key', userId: 'user-1');

      expect(
        () => service.purchasePackage(package),
        throwsA(
          isA<PurchaseException>().having(
            (e) => e.code,
            'code',
            'purchase_not_activated',
          ),
        ),
      );
    });

    test('purchasePackage maps unexpected purchase errors', () async {
      await _installHandler((call) async {
        if (call.method == 'setupPurchases') return null;
        if (call.method == 'purchasePackage') {
          throw PlatformException(code: '999', message: 'unknown failure');
        }
        return null;
      });

      final service = PurchaseService();
      final package = Package.fromJson(_monthlyPackageJson());
      await service.initialize(apiKey: 'test_key', userId: 'user-1');

      expect(
        () => service.purchasePackage(package),
        throwsA(
          isA<PurchaseException>().having(
            (e) => e.code,
            'code',
            'purchase_error',
          ),
        ),
      );
    });

    test(
      'purchasePackage short-circuits when billing is unavailable in session',
      () async {
        var purchaseCalls = 0;
        await _installHandler((call) async {
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'getCustomerInfo') {
            throw PlatformException(
              code: PurchasesErrorCode.purchaseNotAllowedError.index.toString(),
              message: 'Billing service unavailable on device',
            );
          }
          if (call.method == 'purchasePackage') {
            purchaseCalls++;
            return {
              'customerInfo': _customerInfo(premiumActive: true),
              'transaction': _transactionJson(productId: 'premium_monthly'),
            };
          }
          return null;
        });

        final service = PurchaseService();
        final package = Package.fromJson(_monthlyPackageJson());
        await service.initialize(apiKey: 'test_key', userId: 'user-1');

        expect(await service.isPremium(), isFalse);
        expect(
          () => service.purchasePackage(package),
          throwsA(
            isA<PurchaseException>().having(
              (e) => e.code,
              'code',
              'purchase_not_allowed',
            ),
          ),
        );
        expect(purchaseCalls, 0);
      },
    );

    test('restorePurchases returns true when entitlement is active', () async {
      await _installHandler((call) async {
        if (call.method == 'setupPurchases') return null;
        if (call.method == 'restorePurchases') {
          return _customerInfo(premiumActive: true);
        }
        return null;
      });

      final service = PurchaseService();
      await service.initialize(apiKey: 'test_key', userId: 'user-1');

      expect(await service.restorePurchases(), isTrue);
    });

    test('restorePurchases throws mapped error when plugin throws', () async {
      await _installHandler((call) async {
        if (call.method == 'setupPurchases') return null;
        if (call.method == 'restorePurchases') {
          throw PlatformException(code: '0', message: 'failed');
        }
        return null;
      });

      final service = PurchaseService();
      await service.initialize(apiKey: 'test_key', userId: 'user-1');

      expect(
        () => service.restorePurchases(),
        throwsA(
          isA<PurchaseException>().having(
            (e) => e.code,
            'code',
            'purchase_error',
          ),
        ),
      );
    });

    test('getSubscriptionInfo parses entitlement details', () async {
      await _installHandler((call) async {
        if (call.method == 'setupPurchases') return null;
        if (call.method == 'getCustomerInfo') {
          return _customerInfo(
            premiumActive: true,
            willRenew: false,
            productId: 'premium_yearly',
            expirationDate: '2027-01-01T12:00:00Z',
          );
        }
        return null;
      });

      final service = PurchaseService();
      await service.initialize(apiKey: 'test_key', userId: 'user-1');

      final info = await service.getSubscriptionInfo();
      expect(info.isActive, isTrue);
      expect(info.willRenew, isFalse);
      expect(info.productId, 'premium_yearly');
      expect(info.expirationDate, DateTime.parse('2027-01-01T12:00:00Z'));
    });

    test(
      'getSubscriptionInfo handles invalid expiration date safely',
      () async {
        await _installHandler((call) async {
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'getCustomerInfo') {
            return _customerInfo(
              premiumActive: true,
              expirationDate: 'not-a-date',
            );
          }
          return null;
        });

        final service = PurchaseService();
        await service.initialize(apiKey: 'test_key', userId: 'user-1');

        final info = await service.getSubscriptionInfo();
        expect(info.isActive, isTrue);
        expect(info.expirationDate, isNull);
      },
    );

    test('initialize catches setup errors and keeps API safe', () async {
      await _installHandler((call) async {
        if (call.method == 'setupPurchases') {
          throw PlatformException(code: '0', message: 'init failed');
        }
        return null;
      });

      final service = PurchaseService();
      expect(
        await service.initialize(apiKey: 'test_key', userId: 'user-1'),
        isFalse,
      );

      expect(await service.isPremium(), isFalse);
      expect(await service.getOfferings(), isEmpty);
    });

    test('initialize logs in when user changes after first setup', () async {
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
        if (call.method == 'getCustomerInfo') {
          return _customerInfo(premiumActive: false);
        }
        return null;
      });

      final service = PurchaseService();
      await service.initialize(apiKey: 'test_key', userId: 'user-1');
      await service.initialize(apiKey: 'test_key', userId: 'user-2');

      expect(setupCalls, 1);
      expect(logInCalls, 1);
      expect(await service.isPremium(), isFalse);
    });

    test('initialize clears identity when user switch login fails', () async {
      var logInCalls = 0;
      await _installHandler((call) async {
        if (call.method == 'setupPurchases') return null;
        if (call.method == 'logIn') {
          logInCalls++;
          throw PlatformException(code: '0', message: 'logIn failed');
        }
        if (call.method == 'getCustomerInfo') {
          return _customerInfo(premiumActive: true);
        }
        return null;
      });

      final service = PurchaseService();
      await service.initialize(apiKey: 'test_key', userId: 'user-1');
      expect(await service.isPremium(), isTrue);

      await service.initialize(apiKey: 'test_key', userId: 'user-2');
      expect(logInCalls, 1);

      // Failed user switch must not keep stale ready state.
      expect(await service.isPremium(), isFalse);
    });

    test('logout clears initialized state after successful setup', () async {
      var logoutCalls = 0;
      await _installHandler((call) async {
        if (call.method == 'setupPurchases') return null;
        if (call.method == 'logOut') {
          logoutCalls++;
          return _customerInfo(premiumActive: false);
        }
        if (call.method == 'getCustomerInfo') {
          return _customerInfo(premiumActive: true);
        }
        return null;
      });

      final service = PurchaseService();
      await service.initialize(apiKey: 'test_key', userId: 'user-1');
      expect(await service.isPremium(), isTrue);

      await service.logout();
      expect(logoutCalls, 1);
      expect(await service.isPremium(), isFalse);
    });

    test('logout is a no-op before initialization', () async {
      var logoutCalls = 0;
      await _installHandler((call) async {
        if (call.method == 'logOut') logoutCalls++;
        return null;
      });

      final service = PurchaseService();

      expect(await service.isPremium(), isFalse);
      await service.logout();
      expect(logoutCalls, 0);
    });

    test('logout clears identity even when plugin logOut throws', () async {
      await _installHandler((call) async {
        if (call.method == 'setupPurchases') return null;
        if (call.method == 'getCustomerInfo') {
          return _customerInfo(premiumActive: true);
        }
        if (call.method == 'logOut') {
          throw PlatformException(code: '0', message: 'logout failed');
        }
        return null;
      });

      final service = PurchaseService();
      await service.initialize(apiKey: 'test_key', userId: 'user-1');
      expect(await service.isPremium(), isTrue);

      await service.logout();

      // Failed logout must still clear in-memory identity.
      expect(await service.isPremium(), isFalse);
    });
  });
}
