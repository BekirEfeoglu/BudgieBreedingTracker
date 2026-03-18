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
      await tester.pumpWidget(
        _wrapWithProviders(const PremiumTrialBannerSection()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PremiumTrialBannerSection), findsOneWidget);
    });

    testWidgets('shows trial badge text', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(const PremiumTrialBannerSection()),
      );
      await tester.pumpAndSettle();

      expect(find.text('premium.trial_badge'), findsOneWidget);
    });

    testWidgets('shows trial subtitle fallback when no offerings',
        (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(const PremiumTrialBannerSection()),
      );
      await tester.pumpAndSettle();

      expect(find.text('premium.trial_subtitle_fallback'), findsOneWidget);
    });

    testWidgets('shows value proposition text', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(const PremiumTrialBannerSection()),
      );
      await tester.pumpAndSettle();

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

        expect(
          find.text('premium.offerings_unavailable_title'),
          findsOneWidget,
        );
        expect(find.text('premium.price_unavailable'), findsNWidgets(3));
        expect(find.text('common.retry'), findsOneWidget);
      },
    );
  });

  group('PremiumPricingSection responsive layout', () {
    testWidgets(
      'shows Column layout on narrow screens (phone)',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _wrapWithProviders(const PremiumPricingSection()),
        );
        await tester.pumpAndSettle();

        // On narrow screens, pricing cards should be in a Column (no Row)
        // Find the LayoutBuilder's output — should NOT have Row with 3 Expanded
        final rows = tester.widgetList<Row>(find.byType(Row));
        final hasThreeExpandedRow = rows.any((row) {
          final expandedCount =
              row.children.whereType<Expanded>().length;
          return expandedCount == 3;
        });
        expect(hasThreeExpandedRow, isFalse);
      },
    );

    testWidgets(
      'shows Row layout on wide screens (tablet)',
      (tester) async {
        tester.view.physicalSize = const Size(768, 1024);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _wrapWithProviders(const PremiumPricingSection()),
        );
        await tester.pumpAndSettle();

        // On wide screens, pricing cards should be in a Row with 3 Expanded
        final rows = tester.widgetList<Row>(find.byType(Row));
        final hasThreeExpandedRow = rows.any((row) {
          final expandedCount =
              row.children.whereType<Expanded>().length;
          return expandedCount == 3;
        });
        expect(hasThreeExpandedRow, isTrue);
      },
    );

    testWidgets(
      'guest user sees info card instead of purchase issue card',
      (tester) async {
        await tester.pumpWidget(
          _wrapWithProviders(
            const PremiumPricingSection(),
            userId: 'anonymous',
          ),
        );
        await tester.pumpAndSettle();

        // Guest info card should be visible
        expect(
          find.text('premium.sign_in_for_multi_device'),
          findsOneWidget,
        );
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
