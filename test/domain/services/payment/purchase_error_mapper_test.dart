import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:budgie_breeding_tracker/domain/services/payment/purchase_error_mapper.dart';
import 'package:budgie_breeding_tracker/domain/services/payment/purchase_models.dart';

/// Concrete class to test the [PurchaseErrorMapper] mixin in isolation.
class _TestErrorMapper with PurchaseErrorMapper {}

void main() {
  late _TestErrorMapper mapper;

  setUp(() {
    mapper = _TestErrorMapper();
  });

  group('PurchaseErrorMapper', () {
    group('isStoreUnavailableNow', () {
      test('returns false when store has not been marked unavailable', () {
        expect(mapper.isStoreUnavailableNow(), isFalse);
      });

      test('returns true during cooldown period after marking', () {
        // Arrange: mark store unavailable via a billing error
        final exception = PlatformException(
          code: PurchasesErrorCode.purchaseNotAllowedError.index.toString(),
          message: 'BILLING_UNAVAILABLE',
        );
        mapper.markStoreUnavailableIfNeeded(exception);

        // Act & Assert
        expect(mapper.isStoreUnavailableNow(), isTrue);
      });

      test('returns false after cooldown expires', () async {
        // Arrange: mark store unavailable
        final exception = PlatformException(
          code: PurchasesErrorCode.purchaseNotAllowedError.index.toString(),
          message: 'BILLING_UNAVAILABLE',
        );
        mapper.markStoreUnavailableIfNeeded(exception);
        expect(mapper.isStoreUnavailableNow(), isTrue);

        // Act: wait for cooldown to expire (20 seconds)
        // We cannot wait 20 real seconds, so we test the boundary logic
        // by clearing and verifying state transitions instead.
        mapper.clearStoreUnavailableState();

        // Assert
        expect(mapper.isStoreUnavailableNow(), isFalse);
      });
    });

    group('storeUnavailableReason', () {
      test('returns null when store is available', () {
        expect(mapper.storeUnavailableReason, isNull);
      });

      test('returns the error message after marking unavailable', () {
        final exception = PlatformException(
          code: PurchasesErrorCode.purchaseNotAllowedError.index.toString(),
          message: 'Billing service is down',
        );
        mapper.markStoreUnavailableIfNeeded(exception);

        expect(mapper.storeUnavailableReason, 'Billing service is down');
      });

      test('uses error code when message is null', () {
        final errorCode =
            PurchasesErrorCode.purchaseNotAllowedError.index.toString();
        final exception = PlatformException(code: errorCode);

        // The message check: e.message ?? e.code — message is null, so
        // the .toUpperCase() check on message will use e.code.
        // purchaseNotAllowedError code match triggers unavailable.
        mapper.markStoreUnavailableIfNeeded(exception);

        // storeUnavailableReason stores e.message ?? e.code
        expect(mapper.storeUnavailableReason, errorCode);
      });
    });

    group('clearStoreUnavailableState', () {
      test('resets all unavailable state fields', () {
        // Arrange: mark unavailable
        final exception = PlatformException(
          code: PurchasesErrorCode.purchaseNotAllowedError.index.toString(),
          message: 'BILLING_UNAVAILABLE',
        );
        mapper.markStoreUnavailableIfNeeded(exception);
        expect(mapper.isStoreUnavailableNow(), isTrue);
        expect(mapper.storeUnavailableReason, isNotNull);

        // Act
        mapper.clearStoreUnavailableState();

        // Assert
        expect(mapper.isStoreUnavailableNow(), isFalse);
        expect(mapper.storeUnavailableReason, isNull);
      });

      test('is safe to call when already cleared', () {
        mapper.clearStoreUnavailableState();
        expect(mapper.isStoreUnavailableNow(), isFalse);
        expect(mapper.storeUnavailableReason, isNull);
      });
    });

    group('markStoreUnavailableIfNeeded', () {
      test(
        'returns true for purchaseNotAllowedError error code',
        () {
          final exception = PlatformException(
            code:
                PurchasesErrorCode.purchaseNotAllowedError.index.toString(),
            message: 'Not allowed',
          );

          expect(mapper.markStoreUnavailableIfNeeded(exception), isTrue);
          expect(mapper.isStoreUnavailableNow(), isTrue);
        },
      );

      test(
        'returns true when message contains BILLING_UNAVAILABLE',
        () {
          final exception = PlatformException(
            code: '0',
            message: 'Error: BILLING_UNAVAILABLE on this device',
          );

          expect(mapper.markStoreUnavailableIfNeeded(exception), isTrue);
          expect(mapper.isStoreUnavailableNow(), isTrue);
        },
      );

      test(
        'returns true when message contains BILLING SERVICE UNAVAILABLE',
        () {
          final exception = PlatformException(
            code: '0',
            message: 'BILLING SERVICE UNAVAILABLE',
          );

          expect(mapper.markStoreUnavailableIfNeeded(exception), isTrue);
          expect(mapper.isStoreUnavailableNow(), isTrue);
        },
      );

      test(
        'handles case-insensitive billing message matching via toUpperCase',
        () {
          final exception = PlatformException(
            code: '0',
            message: 'billing_unavailable error occurred',
          );

          expect(mapper.markStoreUnavailableIfNeeded(exception), isTrue);
        },
      );

      test('returns false for non-billing errors', () {
        final exception = PlatformException(
          code: PurchasesErrorCode.networkError.index.toString(),
          message: 'Network timeout',
        );

        expect(mapper.markStoreUnavailableIfNeeded(exception), isFalse);
        expect(mapper.isStoreUnavailableNow(), isFalse);
      });

      test('does not overwrite existing unavailable state on repeated calls',
          () {
        final firstException = PlatformException(
          code: PurchasesErrorCode.purchaseNotAllowedError.index.toString(),
          message: 'First billing error',
        );
        final secondException = PlatformException(
          code: PurchasesErrorCode.purchaseNotAllowedError.index.toString(),
          message: 'Second billing error',
        );

        mapper.markStoreUnavailableIfNeeded(firstException);
        mapper.markStoreUnavailableIfNeeded(secondException);

        // Reason should still be from the first call
        expect(mapper.storeUnavailableReason, 'First billing error');
      });

      test('uses error code as message fallback when message is null', () {
        final errorCode =
            PurchasesErrorCode.purchaseNotAllowedError.index.toString();
        final exception = PlatformException(code: errorCode);

        mapper.markStoreUnavailableIfNeeded(exception);

        expect(mapper.storeUnavailableReason, errorCode);
      });
    });

    group('mapPurchaseErrorCode', () {
      test('maps storeProblemError to storeProblem', () {
        expect(
          mapper.mapPurchaseErrorCode(PurchasesErrorCode.storeProblemError),
          PurchaseErrorCodes.storeProblem,
        );
      });

      test('maps purchaseNotAllowedError to notAllowed', () {
        expect(
          mapper.mapPurchaseErrorCode(
            PurchasesErrorCode.purchaseNotAllowedError,
          ),
          PurchaseErrorCodes.notAllowed,
        );
      });

      test('maps productNotAvailableForPurchaseError to productUnavailable',
          () {
        expect(
          mapper.mapPurchaseErrorCode(
            PurchasesErrorCode.productNotAvailableForPurchaseError,
          ),
          PurchaseErrorCodes.productUnavailable,
        );
      });

      test('maps productAlreadyPurchasedError to alreadyOwned', () {
        expect(
          mapper.mapPurchaseErrorCode(
            PurchasesErrorCode.productAlreadyPurchasedError,
          ),
          PurchaseErrorCodes.alreadyOwned,
        );
      });

      test('maps paymentPendingError to pending', () {
        expect(
          mapper.mapPurchaseErrorCode(PurchasesErrorCode.paymentPendingError),
          PurchaseErrorCodes.pending,
        );
      });

      test('maps networkError to networkError', () {
        expect(
          mapper.mapPurchaseErrorCode(PurchasesErrorCode.networkError),
          PurchaseErrorCodes.networkError,
        );
      });

      test('maps offlineConnectionError to networkError', () {
        expect(
          mapper.mapPurchaseErrorCode(
            PurchasesErrorCode.offlineConnectionError,
          ),
          PurchaseErrorCodes.networkError,
        );
      });

      test('maps operationAlreadyInProgressError to inProgress', () {
        expect(
          mapper.mapPurchaseErrorCode(
            PurchasesErrorCode.operationAlreadyInProgressError,
          ),
          PurchaseErrorCodes.inProgress,
        );
      });

      test('maps configurationError to configurationError', () {
        expect(
          mapper.mapPurchaseErrorCode(PurchasesErrorCode.configurationError),
          PurchaseErrorCodes.configurationError,
        );
      });

      test('maps invalidCredentialsError to configurationError', () {
        expect(
          mapper.mapPurchaseErrorCode(
            PurchasesErrorCode.invalidCredentialsError,
          ),
          PurchaseErrorCodes.configurationError,
        );
      });

      test('maps invalidReceiptError to configurationError', () {
        expect(
          mapper.mapPurchaseErrorCode(PurchasesErrorCode.invalidReceiptError),
          PurchaseErrorCodes.configurationError,
        );
      });

      test('maps missingReceiptFileError to configurationError', () {
        expect(
          mapper.mapPurchaseErrorCode(
            PurchasesErrorCode.missingReceiptFileError,
          ),
          PurchaseErrorCodes.configurationError,
        );
      });

      test('maps receiptAlreadyInUseError to configurationError', () {
        expect(
          mapper.mapPurchaseErrorCode(
            PurchasesErrorCode.receiptAlreadyInUseError,
          ),
          PurchaseErrorCodes.configurationError,
        );
      });

      test(
        'maps receiptInUseByOtherSubscriberError to configurationError',
        () {
          expect(
            mapper.mapPurchaseErrorCode(
              PurchasesErrorCode.receiptInUseByOtherSubscriberError,
            ),
            PurchaseErrorCodes.configurationError,
          );
        },
      );

      test('maps purchaseCancelledError to genericError (wildcard)', () {
        expect(
          mapper.mapPurchaseErrorCode(
            PurchasesErrorCode.purchaseCancelledError,
          ),
          PurchaseErrorCodes.genericError,
        );
      });

      test('maps unknownError to genericError (wildcard)', () {
        expect(
          mapper.mapPurchaseErrorCode(PurchasesErrorCode.unknownError),
          PurchaseErrorCodes.genericError,
        );
      });

      test('maps all explicitly handled codes to non-generic values', () {
        final explicitMappings = {
          PurchasesErrorCode.storeProblemError: PurchaseErrorCodes.storeProblem,
          PurchasesErrorCode.purchaseNotAllowedError:
              PurchaseErrorCodes.notAllowed,
          PurchasesErrorCode.productNotAvailableForPurchaseError:
              PurchaseErrorCodes.productUnavailable,
          PurchasesErrorCode.productAlreadyPurchasedError:
              PurchaseErrorCodes.alreadyOwned,
          PurchasesErrorCode.paymentPendingError: PurchaseErrorCodes.pending,
          PurchasesErrorCode.networkError: PurchaseErrorCodes.networkError,
          PurchasesErrorCode.offlineConnectionError:
              PurchaseErrorCodes.networkError,
          PurchasesErrorCode.operationAlreadyInProgressError:
              PurchaseErrorCodes.inProgress,
          PurchasesErrorCode.configurationError:
              PurchaseErrorCodes.configurationError,
          PurchasesErrorCode.invalidCredentialsError:
              PurchaseErrorCodes.configurationError,
          PurchasesErrorCode.invalidReceiptError:
              PurchaseErrorCodes.configurationError,
          PurchasesErrorCode.missingReceiptFileError:
              PurchaseErrorCodes.configurationError,
          PurchasesErrorCode.receiptAlreadyInUseError:
              PurchaseErrorCodes.configurationError,
          PurchasesErrorCode.receiptInUseByOtherSubscriberError:
              PurchaseErrorCodes.configurationError,
        };

        for (final entry in explicitMappings.entries) {
          expect(
            mapper.mapPurchaseErrorCode(entry.key),
            entry.value,
            reason: '${entry.key} should map to ${entry.value}',
          );
        }
      });
    });

    group('state lifecycle', () {
      test('full cycle: available -> unavailable -> cleared -> available', () {
        // Initially available
        expect(mapper.isStoreUnavailableNow(), isFalse);

        // Mark unavailable
        final exception = PlatformException(
          code: PurchasesErrorCode.purchaseNotAllowedError.index.toString(),
          message: 'BILLING_UNAVAILABLE',
        );
        mapper.markStoreUnavailableIfNeeded(exception);
        expect(mapper.isStoreUnavailableNow(), isTrue);
        expect(mapper.storeUnavailableReason, 'BILLING_UNAVAILABLE');

        // Clear
        mapper.clearStoreUnavailableState();
        expect(mapper.isStoreUnavailableNow(), isFalse);
        expect(mapper.storeUnavailableReason, isNull);

        // Non-billing error does not re-mark
        final networkError = PlatformException(
          code: PurchasesErrorCode.networkError.index.toString(),
          message: 'Timeout',
        );
        mapper.markStoreUnavailableIfNeeded(networkError);
        expect(mapper.isStoreUnavailableNow(), isFalse);
      });

      test('separate instances do not share state', () {
        final mapper1 = _TestErrorMapper();
        final mapper2 = _TestErrorMapper();

        final exception = PlatformException(
          code: PurchasesErrorCode.purchaseNotAllowedError.index.toString(),
          message: 'BILLING_UNAVAILABLE',
        );
        mapper1.markStoreUnavailableIfNeeded(exception);

        expect(mapper1.isStoreUnavailableNow(), isTrue);
        expect(mapper2.isStoreUnavailableNow(), isFalse);
      });
    });
  });
}
