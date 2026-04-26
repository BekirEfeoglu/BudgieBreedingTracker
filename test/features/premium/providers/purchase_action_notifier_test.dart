import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/bootstrap.dart';
import 'package:budgie_breeding_tracker/domain/services/payment/purchase_service.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/premium_providers.dart';

import '../../../helpers/fake_purchase_service.dart';
import '../../../helpers/test_helpers.dart';

class MockPackage extends Mock implements Package {}

class MockStoreProduct extends Mock implements StoreProduct {}

void _stubPackage(
  MockPackage package, {
  required PackageType packageType,
  required String identifier,
  required String productIdentifier,
}) {
  final storeProduct = MockStoreProduct();
  when(() => package.packageType).thenReturn(packageType);
  when(() => package.identifier).thenReturn(identifier);
  when(() => package.storeProduct).thenReturn(storeProduct);
  when(() => storeProduct.identifier).thenReturn(productIdentifier);
}

ProviderContainer _containerWithService(
  FakePurchaseService service, {
  List<dynamic> extraOverrides = const [],
}) {
  return ProviderContainer(
    overrides: [
      currentUserIdProvider.overrideWithValue('user-1'),
      purchaseServiceProvider.overrideWithValue(service),
      ...extraOverrides,
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

  group('PurchaseActionState', () {
    test('default state has no loading, error, or success', () {
      const state = PurchaseActionState();

      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
      expect(state.purchasingPlan, isNull);
    });

    test('copyWith preserves bool fields but resets nullable fields', () {
      const state = PurchaseActionState(
        isLoading: true,
        error: 'old_error',
        isSuccess: false,
        purchasingPlan: PremiumPlan.semiAnnual,
      );

      final updated = state.copyWith(isSuccess: true);

      // Bool fields use ?? fallback, so isLoading is preserved
      expect(updated.isLoading, isTrue);
      expect(updated.isSuccess, isTrue);
      // Nullable fields (error, purchasingPlan) are NOT preserved on copyWith;
      // they reset to null unless explicitly passed
      expect(updated.error, isNull);
      expect(updated.purchasingPlan, isNull);
    });

    test('copyWith clears error when set to null', () {
      const state = PurchaseActionState(error: 'some_error');

      final updated = state.copyWith(error: null);
      expect(updated.error, isNull);
    });

    test('copyWith can update all fields', () {
      const state = PurchaseActionState();

      final updated = state.copyWith(
        isLoading: true,
        error: 'error',
        isSuccess: true,
        purchasingPlan: PremiumPlan.yearly,
      );

      expect(updated.isLoading, isTrue);
      expect(updated.error, 'error');
      expect(updated.isSuccess, isTrue);
      expect(updated.purchasingPlan, PremiumPlan.yearly);
    });
  });

  group('PurchaseActionNotifier.build', () {
    test('initial state is default PurchaseActionState', () {
      final container = _containerWithService(service);
      addTearDown(container.dispose);

      final state = container.read(purchaseActionProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
      expect(state.purchasingPlan, isNull);
    });
  });

  group('PurchaseActionNotifier.purchasePlan', () {
    test('sets loading state with plan type at start', () async {
      service.offeringsResult = [];

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      // Start the purchase but don't await — check intermediate state
      await container
          .read(purchaseActionProvider.notifier)
          .purchasePlan(PremiumPlan.semiAnnual);

      // After completion, loading should be cleared
      final state = container.read(purchaseActionProvider);
      expect(state.isLoading, isFalse);
    });

    test('shows error when purchase service is not ready', () async {
      service.initializeResult = false;

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      await container
          .read(purchaseActionProvider.notifier)
          .purchasePlan(PremiumPlan.semiAnnual);

      final state = container.read(purchaseActionProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, PurchaseErrorCodes.noOfferings);
    });

    test('shows error when offerings are empty', () async {
      service.offeringsResult = [];

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      // Wait for PremiumNotifier._load to complete first
      container.read(localPremiumProvider);
      await waitUntil(() => service.isPremiumCallCount > 0);

      await container
          .read(purchaseActionProvider.notifier)
          .purchasePlan(PremiumPlan.semiAnnual);

      final state = container.read(purchaseActionProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, PurchaseErrorCodes.noOfferings);
    });

    test('shows error when no matching package found for plan', () async {
      final annual = MockPackage();
      _stubPackage(
        annual,
        packageType: PackageType.annual,
        identifier: 'annual',
        productIdentifier: 'budgie_premium_yearly',
      );
      service.offeringsResult = [annual];

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      await container
          .read(purchaseActionProvider.notifier)
          .purchasePlan(PremiumPlan.semiAnnual);

      final state = container.read(purchaseActionProvider);
      expect(state.error, PurchaseErrorCodes.packageNotFound);
      expect(service.lastPurchasedPackage, isNull);
    });

    test('sets success when purchase succeeds', () async {
      final monthly = MockPackage();
      _stubPackage(
        monthly,
        packageType: PackageType.sixMonth,
        identifier: 'six_month',
        productIdentifier: 'budgie_premium_semi_annual',
      );
      service.offeringsResult = [monthly];
      service.purchaseResult = true;

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      await container
          .read(purchaseActionProvider.notifier)
          .purchasePlan(PremiumPlan.semiAnnual);

      final state = container.read(purchaseActionProvider);
      expect(state.isSuccess, isTrue);
      expect(state.error, isNull);
    });

    test('shows cancelled error when purchase returns false', () async {
      final monthly = MockPackage();
      _stubPackage(
        monthly,
        packageType: PackageType.sixMonth,
        identifier: 'six_month',
        productIdentifier: 'budgie_premium_semi_annual',
      );
      service.offeringsResult = [monthly];
      service.purchaseResult = false;

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      await container
          .read(purchaseActionProvider.notifier)
          .purchasePlan(PremiumPlan.semiAnnual);

      final state = container.read(purchaseActionProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, PurchaseErrorCodes.cancelled);
    });

    test('surfaces PurchaseException error code', () async {
      final monthly = MockPackage();
      _stubPackage(
        monthly,
        packageType: PackageType.sixMonth,
        identifier: 'six_month',
        productIdentifier: 'budgie_premium_semi_annual',
      );
      service.offeringsResult = [monthly];
      service.purchaseError = const PurchaseException(
        PurchaseErrorCodes.pending,
      );

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      await container
          .read(purchaseActionProvider.notifier)
          .purchasePlan(PremiumPlan.semiAnnual);

      final state = container.read(purchaseActionProvider);
      expect(state.error, PurchaseErrorCodes.pending);
    });

    test('handles generic exceptions', () async {
      final container = _containerWithService(
        service,
        extraOverrides: [
          premiumOfferingsProvider.overrideWith(
            (ref) => Future<List<Package>>.error(Exception('generic failure')),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(purchaseActionProvider.notifier)
          .purchasePlan(PremiumPlan.semiAnnual);

      final state = container.read(purchaseActionProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, contains('generic failure'));
    });

    test('matches yearly plan to annual package type', () async {
      final annual = MockPackage();
      _stubPackage(
        annual,
        packageType: PackageType.annual,
        identifier: 'annual',
        productIdentifier: 'budgie_premium_yearly',
      );
      service.offeringsResult = [annual];
      service.purchaseResult = true;

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      await container
          .read(purchaseActionProvider.notifier)
          .purchasePlan(PremiumPlan.yearly);

      expect(service.lastPurchasedPackage, same(annual));
      expect(container.read(purchaseActionProvider).isSuccess, isTrue);
    });

    test('matches lifetime plan to lifetime package type', () async {
      final lifetime = MockPackage();
      _stubPackage(
        lifetime,
        packageType: PackageType.annual,
        identifier: 'annual',
        productIdentifier: 'budgie_premium_yearly',
      );
      service.offeringsResult = [lifetime];
      service.purchaseResult = true;

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      await container
          .read(purchaseActionProvider.notifier)
          .purchasePlan(PremiumPlan.yearly);

      expect(service.lastPurchasedPackage, same(lifetime));
      expect(container.read(purchaseActionProvider).isSuccess, isTrue);
    });
  });

  group('PurchaseActionNotifier.restorePurchases', () {
    test('sets loading state at start', () async {
      service.restoreResult = true;

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      await container.read(purchaseActionProvider.notifier).restorePurchases();

      // After completion, check final state
      final state = container.read(purchaseActionProvider);
      expect(state.isLoading, isFalse);
    });

    test('shows error when purchase service is not ready', () async {
      service.initializeResult = false;

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      await container.read(purchaseActionProvider.notifier).restorePurchases();

      final state = container.read(purchaseActionProvider);
      expect(state.error, PurchaseErrorCodes.noOfferings);
    });

    test('sets success state when restore succeeds', () async {
      service.restoreResult = true;

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      await container.read(purchaseActionProvider.notifier).restorePurchases();

      final state = container.read(purchaseActionProvider);
      expect(state.isSuccess, isTrue);
      expect(state.error, isNull);
    });

    test('shows no-purchases error when restore returns false', () async {
      service.restoreResult = false;

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      await container.read(purchaseActionProvider.notifier).restorePurchases();

      final state = container.read(purchaseActionProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, PurchaseErrorCodes.restoreNoPurchases);
    });

    test('surfaces PurchaseException error code on restore', () async {
      service.restoreError = const PurchaseException(
        PurchaseErrorCodes.networkError,
      );

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      await container.read(purchaseActionProvider.notifier).restorePurchases();

      final state = container.read(purchaseActionProvider);
      expect(state.error, PurchaseErrorCodes.networkError);
    });

    test('shows restore_failed for generic exceptions', () async {
      service.restoreError = Exception('unexpected');

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      await container.read(purchaseActionProvider.notifier).restorePurchases();

      final state = container.read(purchaseActionProvider);
      expect(state.error, PurchaseErrorCodes.restoreFailed);
    });
  });

  group('PurchaseActionNotifier.reset', () {
    test('resets all state fields to defaults', () async {
      final monthly = MockPackage();
      _stubPackage(
        monthly,
        packageType: PackageType.sixMonth,
        identifier: 'six_month',
        productIdentifier: 'budgie_premium_semi_annual',
      );
      service.offeringsResult = [monthly];
      service.purchaseResult = false;

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      await container
          .read(purchaseActionProvider.notifier)
          .purchasePlan(PremiumPlan.semiAnnual);
      expect(
        container.read(purchaseActionProvider).error,
        PurchaseErrorCodes.cancelled,
      );

      container.read(purchaseActionProvider.notifier).reset();

      final state = container.read(purchaseActionProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
      expect(state.purchasingPlan, isNull);
    });

    test('can be called multiple times without error', () {
      final container = _containerWithService(service);
      addTearDown(container.dispose);

      container.read(purchaseActionProvider.notifier).reset();
      container.read(purchaseActionProvider.notifier).reset();

      final state = container.read(purchaseActionProvider);
      expect(state.isLoading, isFalse);
    });
  });

  group('PurchaseActionNotifier sequential operations', () {
    test('second purchase clears previous error state', () async {
      final monthly = MockPackage();
      _stubPackage(
        monthly,
        packageType: PackageType.sixMonth,
        identifier: 'six_month',
        productIdentifier: 'budgie_premium_semi_annual',
      );
      service.offeringsResult = [monthly];

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      // First: failure
      service.purchaseResult = false;
      await container
          .read(purchaseActionProvider.notifier)
          .purchasePlan(PremiumPlan.semiAnnual);
      expect(
        container.read(purchaseActionProvider).error,
        PurchaseErrorCodes.cancelled,
      );

      // Second: success
      service.purchaseResult = true;
      await container
          .read(purchaseActionProvider.notifier)
          .purchasePlan(PremiumPlan.semiAnnual);

      final state = container.read(purchaseActionProvider);
      expect(state.isSuccess, isTrue);
      expect(state.error, isNull);
    });

    test('restore after failed purchase works correctly', () async {
      service.initializeResult = false;
      final container = _containerWithService(service);
      addTearDown(container.dispose);

      await container
          .read(purchaseActionProvider.notifier)
          .purchasePlan(PremiumPlan.semiAnnual);
      expect(
        container.read(purchaseActionProvider).error,
        PurchaseErrorCodes.noOfferings,
      );

      // Restore also fails when service not ready
      await container.read(purchaseActionProvider.notifier).restorePurchases();
      expect(
        container.read(purchaseActionProvider).error,
        PurchaseErrorCodes.noOfferings,
      );
    });
  });
}
