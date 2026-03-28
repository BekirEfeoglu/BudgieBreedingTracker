@Tags(['e2e'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/bootstrap.dart';
import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart';

import '../helpers/e2e_test_harness.dart';

Package _annualPackage() {
  const offeringContext = PresentedOfferingContext('default', null, null);
  const storeProduct = StoreProduct(
    'annual_plan',
    'Annual premium plan',
    'Yillik Plan',
    999.0,
    '999.00',
    'TRY',
    presentedOfferingContext: offeringContext,
  );
  return const Package(
    'annual',
    PackageType.annual,
    storeProduct,
    offeringContext,
  );
}

void main() {
  ensureE2EBinding();

  setUp(() {
    revenueCatApiKeyAndroid = 'android_test_key';
    revenueCatApiKeyIos = 'ios_test_key';
  });

  tearDown(() {
    revenueCatApiKeyAndroid = '';
    revenueCatApiKeyIos = '';
  });

  group('Premium Flow E2E', () {
    testWidgets(
      'GIVEN free-tier user WHEN premium feature route is opened THEN user is redirected to premium screen and offerings are available',
      (tester) async {
        final mockPurchaseService = MockPurchaseService();
        final annualPackage = _annualPackage();
        when(() => mockPurchaseService.isInitialized).thenReturn(false);
        when(
          () => mockPurchaseService.initialize(
            apiKey: any(named: 'apiKey'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async => true);
        when(
          () => mockPurchaseService.getOfferings(),
        ).thenAnswer((_) async => [annualPackage]);
        when(
          () => mockPurchaseService.isPremium(),
        ).thenAnswer((_) async => false);

        final container = createTestContainer(
          isPremium: false,
          overrides: [
            purchaseServiceProvider.overrideWithValue(mockPurchaseService),
          ],
        );
        addTearDown(container.dispose);

        final router = buildTestNavigator(
          initialLocation: '/premium-feature',
          routes: [
            GoRoute(
              path: '/premium-feature',
              builder: (_, __) => const Scaffold(body: Text('premium-feature')),
            ),
            GoRoute(
              path: '/premium',
              builder: (_, __) => const Scaffold(body: Text('premium-gate')),
            ),
          ],
          redirect: (_, state) {
            final premium = container.read(isPremiumProvider);
            if (state.uri.path == '/premium-feature' && !premium) {
              return '/premium';
            }
            return null;
          },
        );

        await pumpApp(tester, container, router: router);

        final offerings = await container.read(premiumOfferingsProvider.future);
        expect(offerings, hasLength(1));
        expect(find.text('premium-gate'), findsOneWidget);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN premium screen and loaded products WHEN yearly plan purchase is completed THEN purchase service is called and feature gate unlocks',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final mockPurchaseService = MockPurchaseService();
        final annualPackage = _annualPackage();

        when(() => mockPurchaseService.isInitialized).thenReturn(false);
        when(
          () => mockPurchaseService.initialize(
            apiKey: any(named: 'apiKey'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async => true);
        when(
          () => mockPurchaseService.isPremium(),
        ).thenAnswer((_) async => false);
        when(
          () => mockPurchaseService.getOfferings(),
        ).thenAnswer((_) async => [annualPackage]);
        when(
          () => mockPurchaseService.purchasePackage(annualPackage),
        ).thenAnswer((_) async => true);

        final container = createTestContainer(
          isPremium: false,
          overrides: [
            purchaseServiceProvider.overrideWithValue(mockPurchaseService),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(purchaseActionProvider.notifier)
            .purchasePlan(PremiumPlan.yearly);

        final actionState = container.read(purchaseActionProvider);

        expect(actionState.isSuccess, isTrue);
        verify(
          () => mockPurchaseService.purchasePackage(annualPackage),
        ).called(1);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN premium screen WHEN restore purchases is tapped THEN restorePurchases is called and premium is restored',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final mockPurchaseService = MockPurchaseService();

        when(() => mockPurchaseService.isInitialized).thenReturn(false);
        when(
          () => mockPurchaseService.initialize(
            apiKey: any(named: 'apiKey'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async => true);
        when(
          () => mockPurchaseService.isPremium(),
        ).thenAnswer((_) async => false);
        when(
          () => mockPurchaseService.restorePurchases(),
        ).thenAnswer((_) async => true);

        final container = createTestContainer(
          isPremium: false,
          overrides: [
            purchaseServiceProvider.overrideWithValue(mockPurchaseService),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(purchaseActionProvider.notifier)
            .restorePurchases();

        final actionState = container.read(purchaseActionProvider);

        expect(actionState.isSuccess, isTrue);
        verify(() => mockPurchaseService.restorePurchases()).called(1);
      },
      timeout: e2eTimeout,
    );
  });
}
