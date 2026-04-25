import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/bootstrap.dart';
import 'package:budgie_breeding_tracker/data/models/profile_model.dart';
import 'package:budgie_breeding_tracker/domain/services/payment/purchase_service.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/premium_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';

import '../../../helpers/fake_purchase_service.dart';
import '../../../helpers/test_helpers.dart';

class MockPackage extends Mock implements Package {}

class MockStoreProduct extends Mock implements StoreProduct {}

Map<String, dynamic> _packageJson({
  required String identifier,
  required String packageType,
  required String productIdentifier,
  String priceString = '\$9.99',
}) {
  return {
    'identifier': identifier,
    'packageType': packageType,
    'product': {
      'identifier': productIdentifier,
      'description': 'Premium plan',
      'title': 'Premium',
      'price': 9.99,
      'priceString': priceString,
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

Future<void> _flushAsync() async {
  await Future<void>.delayed(const Duration(milliseconds: 1));
  await Future<void>.delayed(const Duration(milliseconds: 1));
}

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
    // Riverpod 3 retries FutureProviders on error by default.
    // Disable retries so Future.error overrides propagate immediately.
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

  group('localPremiumProvider', () {
    test('loads cached value and syncs it with service result', () async {
      SharedPreferences.setMockInitialValues({'is_premium_user-1': false});
      service.isPremiumResult = true;

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      expect(container.read(localPremiumProvider), isFalse);
      await _flushAsync();

      expect(container.read(localPremiumProvider), isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('is_premium_user-1'), isTrue);
      expect(service.isPremiumCallCount, 1);
    });

    test('purchase sets premium true only when purchase succeeds', () async {
      final package = MockPackage();
      service.isPremiumError = Exception('not initialized');
      service.purchaseResult = true;

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      final success = await container
          .read(localPremiumProvider.notifier)
          .purchase(package);

      expect(service.lastPurchasedPackage, same(package));
      expect(success, isTrue);
    });

    test(
      'restore persists false when no active subscription is restored',
      () async {
        service.restoreResult = false;

        final container = _containerWithService(service);
        addTearDown(container.dispose);

        await container.read(localPremiumProvider.notifier).setPremium(true);
        final restored = await container
            .read(localPremiumProvider.notifier)
            .restore();

        expect(restored, isFalse);
        expect(container.read(localPremiumProvider), isFalse);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('is_premium_user-1'), isFalse);
      },
    );

    test('uses per-user cache and ignores another user premium flag', () async {
      SharedPreferences.setMockInitialValues({
        'is_premium_user-2': true,
        'is_premium_user-1': false,
      });
      service.isPremiumError = Exception('not initialized');

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      expect(container.read(localPremiumProvider), isFalse);
      await _flushAsync();
      expect(container.read(localPremiumProvider), isFalse);
    });

    test(
      'anonymous user clears premium state and logs out RevenueCat',
      () async {
        SharedPreferences.setMockInitialValues({'is_premium': true});

        final container = ProviderContainer(
          overrides: [
            currentUserIdProvider.overrideWithValue('anonymous'),
            purchaseServiceProvider.overrideWithValue(service),
          ],
        );
        addTearDown(container.dispose);

        expect(container.read(localPremiumProvider), isFalse);
        await _flushAsync();

        final prefs = await SharedPreferences.getInstance();
        expect(container.read(localPremiumProvider), isFalse);
        expect(service.logoutCallCount, 1);
        expect(prefs.getBool('is_premium'), isNull);
      },
    );
  });

  group('purchaseActionProvider', () {
    test('copyWith updates provided fields and preserves others', () {
      const state = PurchaseActionState(
        isLoading: true,
        error: 'old',
        isSuccess: false,
        purchasingPlan: PremiumPlan.semiAnnual,
      );

      final next = state.copyWith(
        error: 'new',
        isSuccess: true,
        purchasingPlan: PremiumPlan.yearly,
      );

      expect(next.isLoading, isTrue);
      expect(next.error, 'new');
      expect(next.isSuccess, isTrue);
      expect(next.purchasingPlan, PremiumPlan.yearly);
    });

    test('shows error when offerings are empty', () async {
      service.offeringsResult = [];

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      // Trigger PremiumNotifier._load() early and wait for it to complete
      container.read(localPremiumProvider);
      await waitUntil(() => service.isPremiumCallCount > 0);

      await container
          .read(purchaseActionProvider.notifier)
          .purchasePlan(PremiumPlan.semiAnnual);

      final state = container.read(purchaseActionProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, 'no_offerings');
      expect(container.read(localPremiumProvider), isFalse);
    });

    test(
      'returns purchase_cancelled when purchase service returns false',
      () async {
        final semiAnnual = MockPackage();
        _stubPackage(
          semiAnnual,
          packageType: PackageType.sixMonth,
          identifier: 'six_month',
          productIdentifier: 'budgie_premium_semi_annual',
        );
        service.offeringsResult = [semiAnnual];
        service.purchaseResult = false;

        final container = _containerWithService(service);
        addTearDown(container.dispose);

        await container
            .read(purchaseActionProvider.notifier)
            .purchasePlan(PremiumPlan.semiAnnual);

        final state = container.read(purchaseActionProvider);
        expect(state.isSuccess, isFalse);
        expect(state.error, 'purchase_cancelled');
        expect(container.read(localPremiumProvider), isFalse);
      },
    );

    test(
      'does not fall back to the wrong package when plan is missing',
      () async {
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
            .purchasePlan(PremiumPlan.semiAnnual);

        final state = container.read(purchaseActionProvider);
        expect(state.isSuccess, isFalse);
        expect(state.error, 'package_not_found');
        expect(service.lastPurchasedPackage, isNull);
      },
    );

    test('matches custom semi-annual RevenueCat package by plan', () async {
      final semiAnnual = Package.fromJson(
        _packageJson(
          identifier: r'$rc_six_month',
          packageType: 'CUSTOM',
          productIdentifier: 'budgie_premium_semi_annual',
          priceString: '\$15.00',
        ),
      );
      service.offeringsResult = [semiAnnual];
      service.purchaseResult = true;

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      await container
          .read(purchaseActionProvider.notifier)
          .purchasePlan(PremiumPlan.semiAnnual);
      expect(service.lastPurchasedPackage?.identifier, r'$rc_six_month');
    });

    test('matches custom yearly RevenueCat package by plan', () async {
      final annual = Package.fromJson(
        _packageJson(
          identifier: r'$rc_annual',
          packageType: 'CUSTOM',
          productIdentifier: 'budgie_premium_yearly',
          priceString: '\$25.00',
        ),
      );
      service.offeringsResult = [annual];
      service.purchaseResult = true;

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      await container
          .read(purchaseActionProvider.notifier)
          .purchasePlan(PremiumPlan.yearly);
      expect(service.lastPurchasedPackage?.identifier, r'$rc_annual');
    });

    test('matches semi-annual and yearly plans by package type', () async {
      final semiAnnual = MockPackage();
      final annual = MockPackage();
      _stubPackage(
        semiAnnual,
        packageType: PackageType.sixMonth,
        identifier: 'six_month',
        productIdentifier: 'budgie_premium_semi_annual',
      );
      _stubPackage(
        annual,
        packageType: PackageType.annual,
        identifier: 'annual',
        productIdentifier: 'budgie_premium_yearly',
      );
      service.offeringsResult = [semiAnnual, annual];
      service.purchaseResult = true;

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      await container
          .read(purchaseActionProvider.notifier)
          .purchasePlan(PremiumPlan.semiAnnual);
      expect(service.lastPurchasedPackage, same(semiAnnual));

      await container
          .read(purchaseActionProvider.notifier)
          .purchasePlan(PremiumPlan.yearly);
      expect(service.lastPurchasedPackage, same(annual));
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
      expect(state.error, 'no_offerings');
      expect(service.initializeCallCount, 1);
    });

    test('restorePurchases handles both false and thrown responses', () async {
      final container = _containerWithService(service);
      addTearDown(container.dispose);

      service.restoreResult = false;
      await container.read(purchaseActionProvider.notifier).restorePurchases();
      expect(
        container.read(purchaseActionProvider).error,
        'restore_no_purchases',
      );

      service.restoreError = Exception('restore failed');
      await container.read(purchaseActionProvider.notifier).restorePurchases();
      expect(container.read(purchaseActionProvider).error, 'restore_failed');
    });

    test('restorePurchases sets success state on successful restore', () async {
      service.restoreResult = true;
      final container = _containerWithService(service);
      addTearDown(container.dispose);

      await container.read(purchaseActionProvider.notifier).restorePurchases();

      final state = container.read(purchaseActionProvider);
      expect(state.isSuccess, isTrue);
      expect(state.error, isNull);
    });

    test(
      'restorePurchases shows error when purchase service is not ready',
      () async {
        service.initializeResult = false;

        final container = _containerWithService(service);
        addTearDown(container.dispose);

        await container
            .read(purchaseActionProvider.notifier)
            .restorePurchases();

        final state = container.read(purchaseActionProvider);
        expect(state.isSuccess, isFalse);
        expect(state.error, 'no_offerings');
        expect(service.initializeCallCount, 1);
      },
    );

    test('purchasePlan sets error state when offerings fetch throws', () async {
      // Override premiumOfferingsProvider directly so the FutureProvider.future
      // resolves immediately with an error (avoids Riverpod 3 FutureProvider
      // retry hang when the underlying service throws).
      final container = _containerWithService(
        service,
        extraOverrides: [
          premiumOfferingsProvider.overrideWith(
            (ref) => Future<List<Package>>.error(Exception('offerings failed')),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(purchaseActionProvider.notifier)
          .purchasePlan(PremiumPlan.semiAnnual);

      final state = container.read(purchaseActionProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, contains('offerings failed'));
    });

    test('purchasePlan surfaces mapped purchase exception codes', () async {
      final semiAnnual = MockPackage();
      _stubPackage(
        semiAnnual,
        packageType: PackageType.sixMonth,
        identifier: 'six_month',
        productIdentifier: 'budgie_premium_semi_annual',
      );
      service.offeringsResult = [semiAnnual];
      service.purchaseError = const PurchaseException('purchase_pending');

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      await container
          .read(purchaseActionProvider.notifier)
          .purchasePlan(PremiumPlan.semiAnnual);

      expect(container.read(purchaseActionProvider).error, 'purchase_pending');
    });

    test('reset clears loading/error/success flags', () async {
      final semiAnnual = MockPackage();
      _stubPackage(
        semiAnnual,
        packageType: PackageType.sixMonth,
        identifier: 'six_month',
        productIdentifier: 'budgie_premium_semi_annual',
      );
      service.offeringsResult = [semiAnnual];
      service.purchaseResult = false;

      final container = _containerWithService(service);
      addTearDown(container.dispose);

      await container
          .read(purchaseActionProvider.notifier)
          .purchasePlan(PremiumPlan.semiAnnual);
      expect(
        container.read(purchaseActionProvider).error,
        'purchase_cancelled',
      );

      container.read(purchaseActionProvider.notifier).reset();

      final reset = container.read(purchaseActionProvider);
      expect(reset.isLoading, isFalse);
      expect(reset.isSuccess, isFalse);
      expect(reset.error, isNull);
      expect(reset.purchasingPlan, isNull);
    });
  });

  group('helper providers', () {
    test(
      'purchaseServiceReadyProvider initializes RevenueCat for current user',
      () async {
        final container = _containerWithService(service);
        addTearDown(container.dispose);

        final isReady = await container.read(
          purchaseServiceReadyProvider.future,
        );
        expect(isReady, isTrue);
        expect(service.initializeCallCount, 1);
        expect(service.lastInitializedApiKey, 'android_test_key');
        expect(service.lastInitializedUserId, 'user-1');
      },
    );

    test(
      'premiumOfferingsProvider proxies PurchaseService.getOfferings',
      () async {
        final semiAnnual = MockPackage();
        _stubPackage(
          semiAnnual,
          packageType: PackageType.sixMonth,
          identifier: 'six_month',
          productIdentifier: 'budgie_premium_semi_annual',
        );
        service.offeringsResult = [semiAnnual];

        final container = _containerWithService(service);
        addTearDown(container.dispose);

        final offerings = await container.read(premiumOfferingsProvider.future);
        expect(offerings, hasLength(1));
        expect(offerings.first, same(semiAnnual));
        expect(service.initializeCallCount, 1);
      },
    );

    test(
      'subscriptionInfoProvider proxies PurchaseService.getSubscriptionInfo',
      () async {
        service.subscriptionInfoResult = const SubscriptionInfo(
          isActive: true,
          productId: 'premium_yearly',
          willRenew: true,
        );

        final container = _containerWithService(service);
        addTearDown(container.dispose);

        final info = await container.read(subscriptionInfoProvider.future);
        expect(info.isActive, isTrue);
        expect(info.productId, 'premium_yearly');
        expect(info.willRenew, isTrue);
      },
    );

    test('isPremiumProvider prefers profile value', () async {
      const profile = Profile(
        id: 'user-1',
        email: 'user@test.com',
        isPremium: true,
      );
      service.isPremiumError = Exception('not initialized');

      final container = _containerWithService(
        service,
        extraOverrides: [
          userProfileProvider.overrideWith((_) => Stream.value(profile)),
        ],
      );
      addTearDown(container.dispose);

      container.listen(userProfileProvider, (_, __) {});
      await container.read(userProfileProvider.future);
      expect(container.read(isPremiumProvider), isTrue);
      await waitUntil(() => service.isPremiumCallCount > 0);
      await _flushAsync();
    });

    test(
      'isPremiumProvider listener syncs local cache on profile updates',
      () async {
        final controller = StreamController<Profile?>();
        service.isPremiumError = Exception('not initialized');

        final container = _containerWithService(
          service,
          extraOverrides: [
            userProfileProvider.overrideWith((_) => controller.stream),
          ],
        );
        // Teardown runs LIFO: subs → container.dispose → controller.close.
        // container.dispose() MUST precede controller.close() so that Riverpod
        // cancels its internal stream subscription before the close() Future
        // waits for all listeners to finish.
        addTearDown(controller.close); // runs last
        addTearDown(container.dispose); // runs third

        // Keep userProfileProvider and isPremiumProvider both active.
        // premiumSyncProvider contains the ref.listen that syncs profile
        // premium status to localPremiumProvider (moved from isPremiumProvider).
        final profileSub = container.listen(userProfileProvider, (_, __) {});
        addTearDown(profileSub.close); // runs second
        final premiumSub = container.listen<bool>(
          isPremiumProvider,
          (_, __) {},
        );
        addTearDown(premiumSub.close); // runs first
        // Activate the sync listener provider
        container.read(premiumSyncProvider);

        // Emit isPremium: false and verify isPremiumProvider reflects profile.
        controller.add(
          const Profile(id: 'u1', email: 'u1@test.com', isPremium: false),
        );
        await _flushAsync();
        expect(container.read(isPremiumProvider), isFalse);

        // Emit isPremium: true – isPremiumProvider should eagerly re-evaluate
        // via ref.watch(userProfileProvider) and return profileHasPremium = true.
        controller.add(
          const Profile(id: 'u1', email: 'u1@test.com', isPremium: true),
        );
        await _flushAsync();
        expect(container.read(isPremiumProvider), isTrue);
      },
    );
  });
}
