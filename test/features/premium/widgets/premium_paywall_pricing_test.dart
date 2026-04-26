import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/premium_providers.dart';
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
  double price = 9.99,
}) {
  return {
    'identifier': identifier,
    'packageType': packageType,
    'product': {
      'identifier': productIdentifier,
      'description': 'Premium plan',
      'title': 'Premium',
      'price': price,
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

      expect(find.text(l10n('premium.plan_semi_annual')), findsOneWidget);
      expect(find.text(l10n('premium.plan_yearly')), findsOneWidget);
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

      expect(find.text(l10n('premium.best_value')), findsOneWidget);
    });

    testWidgets('shows savings text on yearly plan', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(const PremiumPricingSection()),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('premium.save_percent')), findsOneWidget);
    });

    testWidgets('does not show trial text on pricing cards', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(const PremiumPricingSection()),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('premium.trial_after_price')), findsNothing);
    });

    testWidgets('shows terms note disclosure', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(const PremiumPricingSection()),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('premium.terms_note')), findsOneWidget);
    });

    testWidgets('shows guest access card for anonymous user', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(
          const PremiumPricingSection(),
          userId: 'anonymous',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('premium.account_required_title')), findsOneWidget);
      expect(
        find.text(l10n('premium.sign_in_to_purchase')),
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

      expect(find.text(l10n('premium.account_required_title')), findsNothing);
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
        find.text(l10n('premium.purchase_setup_missing_title')),
        findsOneWidget,
      );
      expect(
        find.text(l10n('premium.purchase_setup_missing_body')),
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

      expect(find.text(l10n('common.retry')), findsOneWidget);
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
    });

    testWidgets('shows legal links section', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(const PremiumPricingSection()),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('settings.privacy_policy')), findsOneWidget);
    });

    testWidgets('renders savings text with store packages available', (
      tester,
    ) async {
      // Regional prices: €10/6mo, €16/yr → 20% savings computed dynamically
      final offerings = [
        Package.fromJson(
          _packageJson(
            identifier: r'$rc_six_month',
            packageType: 'SIX_MONTH',
            productIdentifier: 'budgie_premium_semi_annual',
            priceString: '€10,00',
            price: 10.0,
          ),
        ),
        Package.fromJson(
          _packageJson(
            identifier: r'$rc_annual',
            packageType: 'ANNUAL',
            productIdentifier: 'budgie_premium_yearly',
            priceString: '€16,00',
            price: 16.0,
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

      // Savings text should still render (via l10n key) regardless of value
      expect(find.text(l10n('premium.save_percent')), findsOneWidget);
    });

    testWidgets('renders savings text with fallback when no packages', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithProviders(const PremiumPricingSection()),
      );
      await tester.pumpAndSettle();

      // No packages → falls back to 17%
      expect(find.text(l10n('premium.save_percent')), findsOneWidget);
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

  group('calculateSavingsPercent', () {
    test('computes 20% for €10/6mo and €16/yr', () {
      // 10*2=20, (20-16)/20*100 = 20%
      expect(
        calculateSavingsPercent(semiAnnualPrice: 10.0, yearlyPrice: 16.0),
        '20',
      );
    });

    test('computes 17% for \$15/6mo and \$25/yr', () {
      // 15*2=30, (30-25)/30*100 = 16.67 → rounds to 17%
      expect(
        calculateSavingsPercent(semiAnnualPrice: 15.0, yearlyPrice: 25.0),
        '17',
      );
    });

    test('returns fallback when semi-annual price is null', () {
      expect(
        calculateSavingsPercent(semiAnnualPrice: null, yearlyPrice: 25.0),
        '17',
      );
    });

    test('returns fallback when yearly price is null', () {
      expect(
        calculateSavingsPercent(semiAnnualPrice: 15.0, yearlyPrice: null),
        '17',
      );
    });

    test('returns fallback when prices are zero', () {
      expect(
        calculateSavingsPercent(semiAnnualPrice: 0, yearlyPrice: 0),
        '17',
      );
    });

    test('returns fallback when yearly >= annualized semi-annual', () {
      // No savings: yearly costs more than 2× semi-annual
      expect(
        calculateSavingsPercent(semiAnnualPrice: 10.0, yearlyPrice: 20.0),
        '17',
      );
    });

    test('computes large savings correctly', () {
      // 10*2=20, (20-5)/20*100 = 75%
      expect(
        calculateSavingsPercent(semiAnnualPrice: 10.0, yearlyPrice: 5.0),
        '75',
      );
    });
  });
}
