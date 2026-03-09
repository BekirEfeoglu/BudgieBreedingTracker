import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart';
import 'package:budgie_breeding_tracker/features/premium/widgets/premium_paywall_sections.dart';

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
  group('PremiumHeaderSection', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_wrap(const PremiumHeaderSection()));
      await tester.pump();

      expect(find.byType(PremiumHeaderSection), findsOneWidget);
    });

    testWidgets('shows headline text', (tester) async {
      await tester.pumpWidget(_wrap(const PremiumHeaderSection()));
      await tester.pump();

      expect(find.text('premium.headline'), findsOneWidget);
    });

    testWidgets('shows subtitle text', (tester) async {
      await tester.pumpWidget(_wrap(const PremiumHeaderSection()));
      await tester.pump();

      expect(find.text('premium.subtitle'), findsOneWidget);
    });

    testWidgets('renders gradient Container', (tester) async {
      await tester.pumpWidget(_wrap(const PremiumHeaderSection()));
      await tester.pump();

      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });
  });

  group('PremiumTrialBannerSection', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_wrap(const PremiumTrialBannerSection()));
      await tester.pump();

      expect(find.byType(PremiumTrialBannerSection), findsOneWidget);
    });

    testWidgets('shows trial badge text', (tester) async {
      await tester.pumpWidget(_wrap(const PremiumTrialBannerSection()));
      await tester.pump();

      expect(find.text('premium.trial_badge'), findsOneWidget);
    });

    testWidgets('shows trial subtitle text', (tester) async {
      await tester.pumpWidget(_wrap(const PremiumTrialBannerSection()));
      await tester.pump();

      expect(find.text('premium.trial_subtitle'), findsOneWidget);
    });

    testWidgets('shows value proposition text', (tester) async {
      await tester.pumpWidget(_wrap(const PremiumTrialBannerSection()));
      await tester.pump();

      expect(find.text('premium.value_proposition'), findsOneWidget);
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

      expect(find.text('premium.features_title'), findsOneWidget);
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
              identifier: r'$rc_monthly',
              packageType: 'CUSTOM',
              productIdentifier: 'budgie_premium_monthly',
              priceString: '\$4.99',
            ),
          ),
          Package.fromJson(
            _packageJson(
              identifier: r'$rc_annual',
              packageType: 'CUSTOM',
              productIdentifier: 'budgie_premium_yearly',
              priceString: '\$34.99',
            ),
          ),
          Package.fromJson(
            _packageJson(
              identifier: r'$rc_lifetime',
              packageType: 'CUSTOM',
              productIdentifier: 'budgie_premium_lifetime',
              priceString: '\$89.99',
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

        expect(find.text('\$4.99'), findsOneWidget);
        expect(find.text('\$34.99'), findsOneWidget);
        expect(find.text('\$89.99'), findsOneWidget);
        expect(find.text('premium.price_yearly'), findsNothing);
        expect(find.text('premium.price_lifetime'), findsNothing);
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

        expect(find.text('Plans are temporarily unavailable'), findsOneWidget);
        expect(find.text('Store price unavailable'), findsNWidgets(3));
      },
    );
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

      expect(find.text('premium.feature_genetics'), findsOneWidget);
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
}
