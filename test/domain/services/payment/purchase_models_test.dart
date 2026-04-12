import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/payment/purchase_models.dart';

void main() {
  group('PurchaseErrorCodes', () {
    test('all constants are non-empty strings', () {
      final codes = [
        PurchaseErrorCodes.storeProblem,
        PurchaseErrorCodes.notAllowed,
        PurchaseErrorCodes.productUnavailable,
        PurchaseErrorCodes.alreadyOwned,
        PurchaseErrorCodes.pending,
        PurchaseErrorCodes.networkError,
        PurchaseErrorCodes.inProgress,
        PurchaseErrorCodes.configurationError,
        PurchaseErrorCodes.notActivated,
        PurchaseErrorCodes.genericError,
        PurchaseErrorCodes.cancelled,
        PurchaseErrorCodes.noOfferings,
        PurchaseErrorCodes.packageNotFound,
        PurchaseErrorCodes.restoreNoPurchases,
        PurchaseErrorCodes.restoreFailed,
      ];

      for (final code in codes) {
        expect(code, isNotEmpty, reason: 'Error code should not be empty');
      }
    });

    test('all constants are unique', () {
      final codes = {
        PurchaseErrorCodes.storeProblem,
        PurchaseErrorCodes.notAllowed,
        PurchaseErrorCodes.productUnavailable,
        PurchaseErrorCodes.alreadyOwned,
        PurchaseErrorCodes.pending,
        PurchaseErrorCodes.networkError,
        PurchaseErrorCodes.inProgress,
        PurchaseErrorCodes.configurationError,
        PurchaseErrorCodes.notActivated,
        PurchaseErrorCodes.genericError,
        PurchaseErrorCodes.cancelled,
        PurchaseErrorCodes.noOfferings,
        PurchaseErrorCodes.packageNotFound,
        PurchaseErrorCodes.restoreNoPurchases,
        PurchaseErrorCodes.restoreFailed,
      };
      expect(codes.length, 15, reason: 'All error codes should be unique');
    });
  });

  group('PurchaseException', () {
    test('stores code', () {
      const exception = PurchaseException('test_code');
      expect(exception.code, 'test_code');
      expect(exception.purchasesCode, isNull);
      expect(exception.message, isNull);
    });

    test('stores optional message', () {
      const exception = PurchaseException(
        'test_code',
        message: 'Something went wrong',
      );
      expect(exception.message, 'Something went wrong');
    });

    test('toString with message includes code and message', () {
      const exception = PurchaseException(
        'purchase_error',
        message: 'Network timeout',
      );
      expect(exception.toString(), 'purchase_error: Network timeout');
    });

    test('toString without message returns just code', () {
      const exception = PurchaseException('purchase_error');
      expect(exception.toString(), 'purchase_error');
    });

    test('toString with empty message returns just code', () {
      const exception = PurchaseException('purchase_error', message: '');
      expect(exception.toString(), 'purchase_error');
    });

    test('implements Exception', () {
      const exception = PurchaseException('code');
      expect(exception, isA<Exception>());
    });
  });

  group('SubscriptionInfo', () {
    test('creates with required fields', () {
      const info = SubscriptionInfo(isActive: true);
      expect(info.isActive, isTrue);
      expect(info.expirationDate, isNull);
      expect(info.willRenew, isFalse);
      expect(info.productId, isNull);
      expect(info.isTrial, isFalse);
    });

    test('creates with all fields', () {
      final expDate = DateTime(2026, 1, 1);
      final info = SubscriptionInfo(
        isActive: true,
        expirationDate: expDate,
        willRenew: true,
        productId: 'premium_yearly',
        isTrial: false,
      );

      expect(info.isActive, isTrue);
      expect(info.expirationDate, expDate);
      expect(info.willRenew, isTrue);
      expect(info.productId, 'premium_yearly');
      expect(info.isTrial, isFalse);
    });

    test('trial subscription', () {
      const info = SubscriptionInfo(
        isActive: true,
        isTrial: true,
        productId: 'premium_monthly',
      );
      expect(info.isTrial, isTrue);
      expect(info.isActive, isTrue);
    });

    test('expired subscription', () {
      final info = SubscriptionInfo(
        isActive: false,
        expirationDate: DateTime(2024, 1, 1),
        willRenew: false,
      );
      expect(info.isActive, isFalse);
      expect(info.willRenew, isFalse);
    });
  });
}
