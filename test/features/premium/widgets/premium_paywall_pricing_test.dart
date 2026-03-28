import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart';
import 'package:budgie_breeding_tracker/features/premium/widgets/premium_paywall_sections.dart';
import 'package:budgie_breeding_tracker/features/premium/widgets/pricing_card.dart';

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
  group('PremiumPricingSection', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(const PremiumPricingSection()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PremiumPricingSection), findsOneWidget);
    });

    testWidgets('shows two pricing cards', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(const PremiumPricingSection()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PricingCard), findsNWidgets(2));
    });

    testWidgets('shows plan names for both plans', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(const PremiumPricingSection()),
      );
      await tester.pumpAndSettle();

      expect(find.text('premium.plan_semi_annual'), findsOneWidget);
      expect(find.text('premium.plan_yearly'), findsOneWidget);
    });

    testWidgets('shows fallback prices when no packages available', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithProviders(const PremiumPricingSection()),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('premium.price_semi_annual', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('premium.price_yearly', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('shows store prices when packages are available', (
      tester,
    ) async {
      final offerings = [
        Package.fromJson(
          _packageJson(
            identifier: r'$rc_six_month',
            packageType: 'SIX_MONTH',
            productIdentifier: 'budgie_premium_semi_annual',
            priceString: '\$15.00',
          ),
        ),
        Package.fromJson(
          _packageJson(
            identifier: r'$rc_annual',
            packageType: 'ANNUAL',
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
        findsOneWidget,
      );
      expect(
        find.textContaining('\$25.00', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('shows best value badge on yearly plan', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(const PremiumPricingSection()),
      );
      await tester.pumpAndSettle();

      expect(find.text('premium.best_value'), findsOneWidget);
    });

    testWidgets('shows savings text on yearly plan', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(const PremiumPricingSection()),
      );
      await tester.pumpAndSettle();

      expect(find.text('premium.save_percent'), findsOneWidget);
    });

    testWidgets('does not show trial text on pricing cards', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(const PremiumPricingSection()),
      );
      await tester.pumpAndSettle();

      expect(find.text('premium.trial_after_price'), findsNothing);
    });

    testWidgets('shows terms note disclosure', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(const PremiumPricingSection()),
      );
      await tester.pumpAndSettle();

      expect(find.text('premium.terms_note'), findsOneWidget);
    });

    testWidgets('shows guest access card for anonymous user', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(
          const PremiumPricingSection(),
          userId: 'anonymous',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('premium.account_required_title'), findsOneWidget);
      expect(
        find.text('premium.sign_in_to_purchase'),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('does not show guest card for logged-in user', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithProviders(const PremiumPricingSection()),
      );
      await tester.pumpAndSettle();

      expect(find.text('premium.account_required_title'), findsNothing);
    });

    testWidgets('shows purchase issue card when issue exists', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithProviders(
          const PremiumPricingSection(),
          purchaseIssue: PremiumPurchaseIssue.missingApiKey,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('premium.purchase_setup_missing_title'),
        findsOneWidget,
      );
      expect(
        find.text('premium.purchase_setup_missing_body'),
        findsOneWidget,
      );
    });

    testWidgets('shows retry button for offerings unavailable issue', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithProviders(
          const PremiumPricingSection(),
          purchaseIssue: PremiumPurchaseIssue.offeringsUnavailable,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('common.retry'), findsOneWidget);
    });

    testWidgets('does not show retry button for missing API key issue', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithProviders(
          const PremiumPricingSection(),
          purchaseIssue: PremiumPurchaseIssue.missingApiKey,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('common.retry'), findsNothing);
    });

    testWidgets('shows iOS debug StoreKit guidance', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(
          const PremiumPricingSection(),
          purchaseIssue: PremiumPurchaseIssue.iosDebugStoreKitRequired,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('premium.ios_debug_purchase_title'), findsOneWidget);
      expect(find.text('premium.ios_debug_purchase_body'), findsOneWidget);
    });

    testWidgets('shows legal links section', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(const PremiumPricingSection()),
      );
      await tester.pumpAndSettle();

      expect(find.text('settings.privacy_policy'), findsOneWidget);
    });

    testWidgets('shows period labels in RichText for all plans', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithProviders(const PremiumPricingSection()),
      );
      await tester.pumpAndSettle();

      // Period labels are rendered inside RichText (TextSpan), not standalone Text
      expect(
        find.textContaining('premium.period_semi_annual', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('premium.period_yearly', findRichText: true),
        findsOneWidget,
      );
    });
  });
}
