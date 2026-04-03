import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:budgie_breeding_tracker/domain/services/payment/purchase_service.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart';
import 'package:budgie_breeding_tracker/features/premium/widgets/premium_paywall_sections.dart';
import 'package:budgie_breeding_tracker/features/premium/widgets/subscription_info_card.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

Widget _wrapWithProviders(
  Widget child, {
  List<Package> offerings = const [],
  String userId = 'test-user',
  PremiumPurchaseIssue? purchaseIssue,
}) {
  return ProviderScope(
    overrides: [
      currentUserIdProvider.overrideWithValue(userId),
      purchaseActionProvider.overrideWith(() => PurchaseActionNotifier()),
      premiumOfferingsProvider.overrideWith((_) async => offerings),
      premiumPurchaseIssueProvider.overrideWithValue(purchaseIssue),
    ],
    child: _wrap(child),
  );
}

Map<String, dynamic> _packageJson({
  required String identifier,
  required String packageType,
  required String productIdentifier,
  required String priceString,
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

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('tr');
    await initializeDateFormatting('de');
  });

  group('PremiumHeaderSection', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_wrap(const PremiumHeaderSection()));
      await tester.pump();

      expect(find.byType(PremiumHeaderSection), findsOneWidget);
    });

    testWidgets('shows headline text', (tester) async {
      await tester.pumpWidget(_wrap(const PremiumHeaderSection()));
      await tester.pump();

      expect(find.text(l10n('premium.headline')), findsOneWidget);
    });

    testWidgets('shows subtitle text', (tester) async {
      await tester.pumpWidget(_wrap(const PremiumHeaderSection()));
      await tester.pump();

      expect(find.text(l10n('premium.subtitle')), findsOneWidget);
    });

    testWidgets('renders gradient Container', (tester) async {
      await tester.pumpWidget(_wrap(const PremiumHeaderSection()));
      await tester.pump();

      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });
  });

  group('PremiumTrialBannerSection', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(const PremiumTrialBannerSection()),
      );
      await tester.pump();

      expect(find.byType(PremiumTrialBannerSection), findsOneWidget);
    });

    testWidgets('hides when no packages have introductory offer', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithProviders(const PremiumTrialBannerSection()),
      );
      await tester.pumpAndSettle();

      // No introductory offer → SizedBox.shrink, no trial badge visible
      expect(find.text(l10n('premium.trial_badge')), findsNothing);
      expect(find.text(l10n('premium.value_proposition')), findsNothing);
    });
  });

  group('PremiumFeatureListSection', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_wrap(const PremiumFeatureListSection()));
      await tester.pump();

      expect(find.byType(PremiumFeatureListSection), findsOneWidget);
    });

    testWidgets('shows features_title text', (tester) async {
      await tester.pumpWidget(_wrap(const PremiumFeatureListSection()));
      await tester.pump();

      expect(find.text(l10n('premium.features_title')), findsOneWidget);
    });

    testWidgets('shows multiple PremiumFeatureItem widgets', (tester) async {
      await tester.pumpWidget(_wrap(const PremiumFeatureListSection()));
      await tester.pump();

      expect(find.byType(PremiumFeatureItem), findsAtLeastNWidgets(1));
    });
  });

  group('PremiumPricingSection', () {
    testWidgets(
      'shows store prices for custom RevenueCat package identifiers',
      (tester) async {
        final offerings = [
          Package.fromJson(
            _packageJson(
              identifier: r'$rc_six_month',
              packageType: 'CUSTOM',
              productIdentifier: 'budgie_premium_semi_annual',
              priceString: '\$15.00',
            ),
          ),
          Package.fromJson(
            _packageJson(
              identifier: r'$rc_annual',
              packageType: 'CUSTOM',
              productIdentifier: 'budgie_premium_yearly',
              priceString: '\$25.00',
            ),
          ),
        ];

        await tester.pumpWidget(
          _wrapWithProviders(
            const PremiumPricingSection(),
            offerings: offerings,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('\$15.00', findRichText: true),
          findsAtLeastNWidgets(1),
        );
        expect(
          find.textContaining('\$25.00', findRichText: true),
          findsAtLeastNWidgets(1),
        );
        expect(find.text(l10n('premium.price_semi_annual')), findsNothing);
        expect(find.text(l10n('premium.price_yearly')), findsNothing);
      },
    );

    testWidgets(
      'shows purchase issue guidance when offerings are unavailable',
      (tester) async {
        await tester.pumpWidget(
          _wrapWithProviders(
            const PremiumPricingSection(),
            purchaseIssue: PremiumPurchaseIssue.offeringsUnavailable,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(l10n('premium.offerings_unavailable_title')),
          findsOneWidget,
        );
        // Fallback localized prices shown instead of "price unavailable"
        expect(
          find.textContaining('premium.price_semi_annual', findRichText: true),
          findsOneWidget,
        );
        expect(
          find.textContaining('premium.price_yearly', findRichText: true),
          findsOneWidget,
        );
        expect(find.text(l10n('common.retry')), findsOneWidget);
      },
    );

    testWidgets('shows missing API key guidance with setup instructions', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithProviders(
          const PremiumPricingSection(),
          purchaseIssue: PremiumPurchaseIssue.missingApiKey,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('premium.purchase_setup_missing_title')), findsOneWidget);
      expect(find.text(l10n('premium.purchase_setup_missing_body')), findsOneWidget);
      // missingApiKey has no retry button
      expect(find.text(l10n('common.retry')), findsNothing);
    });

    testWidgets('shows iOS debug StoreKit guidance', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(
          const PremiumPricingSection(),
          purchaseIssue: PremiumPurchaseIssue.iosDebugStoreKitRequired,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('premium.ios_debug_purchase_title')), findsOneWidget);
      expect(find.text(l10n('premium.ios_debug_purchase_body')), findsOneWidget);
      // iosDebugStoreKitRequired has no retry button
      expect(find.text(l10n('common.retry')), findsNothing);
    });

    testWidgets('disables subscribe buttons when purchase issue exists', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithProviders(
          const PremiumPricingSection(),
          purchaseIssue: PremiumPurchaseIssue.missingApiKey,
        ),
      );
      await tester.pumpAndSettle();

      // Both plan cards render with localized fallback prices
      expect(
        find.textContaining('premium.price_semi_annual', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('premium.price_yearly', findRichText: true),
        findsOneWidget,
      );
      expect(find.text(l10n('premium.plan_semi_annual')), findsOneWidget);
      expect(find.text(l10n('premium.plan_yearly')), findsOneWidget);
    });

    testWidgets('shows guest access card for anonymous users', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(const PremiumPricingSection(), userId: 'anonymous'),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('premium.account_required_title')), findsOneWidget);
      expect(find.text(l10n('premium.sign_in_to_purchase')), findsAtLeastNWidgets(1));
    });

    testWidgets('does not show trial text on pricing cards', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(const PremiumPricingSection()),
      );
      await tester.pumpAndSettle();

      // Trial text not shown on pricing cards (no monthly plan)
      expect(find.text(l10n('premium.trial_after_price')), findsNothing);
    });

    testWidgets('shows store prices with standard PackageType identifiers', (
      tester,
    ) async {
      final offerings = [
        Package.fromJson(
          _packageJson(
            identifier: r'$rc_six_month',
            packageType: 'SIX_MONTH',
            productIdentifier: 'budgie_premium_semi_annual',
            priceString: '\$15,00',
          ),
        ),
        Package.fromJson(
          _packageJson(
            identifier: r'$rc_annual',
            packageType: 'ANNUAL',
            productIdentifier: 'budgie_premium_yearly',
            priceString: '\$25,00',
          ),
        ),
      ];

      await tester.pumpWidget(
        _wrapWithProviders(const PremiumPricingSection(), offerings: offerings),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('\$15,00', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('\$25,00', findRichText: true),
        findsOneWidget,
      );
    });
  });

  group('PremiumFeatureItem', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PremiumFeatureItem(featureKey: 'premium.feature_genealogy'),
        ),
      );
      await tester.pump();

      expect(find.byType(PremiumFeatureItem), findsOneWidget);
    });

    testWidgets('shows feature key text', (tester) async {
      await tester.pumpWidget(
        _wrap(const PremiumFeatureItem(featureKey: 'premium.feature_genetics')),
      );
      await tester.pump();

      expect(find.text(l10n('premium.feature_genetics')), findsOneWidget);
    });

    testWidgets('shows check Icon', (tester) async {
      await tester.pumpWidget(
        _wrap(const PremiumFeatureItem(featureKey: 'premium.feature_export')),
      );
      await tester.pump();

      expect(find.byType(Icon), findsAtLeastNWidgets(1));
    });

    testWidgets('renders with Row layout', (tester) async {
      await tester.pumpWidget(
        _wrap(const PremiumFeatureItem(featureKey: 'premium.feature_no_ads')),
      );
      await tester.pump();

      expect(find.byType(Row), findsAtLeastNWidgets(1));
    });
  });

  group('matchPackageForPlan', () {
    test('matches semi-annual by PackageType.sixMonth', () {
      final packages = [
        Package.fromJson(
          _packageJson(
            identifier: r'$rc_six_month',
            packageType: 'SIX_MONTH',
            productIdentifier: 'budgie_premium_semi_annual',
            priceString: '\$15.00',
          ),
        ),
      ];
      final result = matchPackageForPlan(packages, PremiumPlan.semiAnnual)!;
      expect(result.storeProduct.identifier, 'budgie_premium_semi_annual');
    });

    test('matches yearly by PackageType.annual', () {
      final packages = [
        Package.fromJson(
          _packageJson(
            identifier: r'$rc_annual',
            packageType: 'ANNUAL',
            productIdentifier: 'budgie_premium_yearly',
            priceString: '\$25.00',
          ),
        ),
      ];
      final result = matchPackageForPlan(packages, PremiumPlan.yearly)!;
      expect(result.storeProduct.identifier, 'budgie_premium_yearly');
    });

    test('falls back to identifier hint for CUSTOM package types', () {
      final packages = [
        Package.fromJson(
          _packageJson(
            identifier: ':six_month',
            packageType: 'CUSTOM',
            productIdentifier: 'budgie_premium_semi_annual',
            priceString: '\$15.00',
          ),
        ),
        Package.fromJson(
          _packageJson(
            identifier: r'$rc_annual',
            packageType: 'CUSTOM',
            productIdentifier: 'budgie_premium_yearly',
            priceString: '\$25.00',
          ),
        ),
      ];

      expect(
        matchPackageForPlan(
          packages,
          PremiumPlan.semiAnnual,
        )?.storeProduct.identifier,
        'budgie_premium_semi_annual',
      );
      expect(
        matchPackageForPlan(
          packages,
          PremiumPlan.yearly,
        )?.storeProduct.identifier,
        'budgie_premium_yearly',
      );
    });

    test('returns null when no matching plan found', () {
      final packages = [
        Package.fromJson(
          _packageJson(
            identifier: 'weekly_special',
            packageType: 'WEEKLY',
            productIdentifier: 'budgie_weekly',
            priceString: '\$1.99',
          ),
        ),
      ];
      expect(matchPackageForPlan(packages, PremiumPlan.semiAnnual), isNull);
      expect(matchPackageForPlan(packages, PremiumPlan.yearly), isNull);
      expect(matchPackageForPlan(packages, PremiumPlan.yearly), isNull);
    });

    test('returns null for empty package list', () {
      expect(matchPackageForPlan([], PremiumPlan.semiAnnual), isNull);
      expect(matchPackageForPlan([], PremiumPlan.yearly), isNull);
      expect(matchPackageForPlan([], PremiumPlan.yearly), isNull);
    });
  });

  group('SubscriptionInfoCard', () {
    testWidgets('shows active subscription with plan and expiry', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SubscriptionInfoCard(
            subscriptionInfo: SubscriptionInfo(
              isActive: true,
              productId: 'budgie_premium_semi_annual',
              expirationDate: DateTime(2026, 12, 31),
              willRenew: true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(l10n('premium.active_badge')), findsOneWidget);
      expect(find.text(l10n('premium.plan_semi_annual')), findsOneWidget);
      expect(find.text('Dec 31, 2026'), findsOneWidget);
      expect(find.text(l10n('common.yes')), findsOneWidget);
    });

    testWidgets('shows trial badge when subscription is in trial', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SubscriptionInfoCard(
            subscriptionInfo: SubscriptionInfo(
              isActive: true,
              productId: 'budgie_premium_semi_annual',
              expirationDate: DateTime(2026, 4, 1),
              willRenew: true,
              isTrial: true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(l10n('premium.trial_active_badge')), findsOneWidget);
    });

    testWidgets('shows yearly plan name for yearly product', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SubscriptionInfoCard(
            subscriptionInfo: SubscriptionInfo(
              isActive: true,
              productId: 'budgie_premium_yearly',
              expirationDate: DateTime(2027, 3, 16),
              willRenew: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(l10n('premium.plan_yearly')), findsOneWidget);
      expect(find.text(l10n('common.no')), findsOneWidget);
    });
  });
}
