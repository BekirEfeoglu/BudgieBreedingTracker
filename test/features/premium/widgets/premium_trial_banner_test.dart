import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart';
import 'package:budgie_breeding_tracker/features/premium/widgets/premium_paywall_sections.dart';

Widget _wrap(Widget child, {List<Package> offerings = const []}) {
  return ProviderScope(
    overrides: [
      premiumOfferingsProvider.overrideWith((_) async => offerings),
    ],
    child: MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  group('PremiumTrialBannerSection', () {
    testWidgets('hides when no packages available', (tester) async {
      await tester.pumpWidget(_wrap(const PremiumTrialBannerSection()));
      await tester.pumpAndSettle();

      // Should render SizedBox.shrink (no visible content)
      expect(find.byType(Container), findsNothing);
      expect(find.text(l10n('premium.trial_badge')), findsNothing);
    });

    testWidgets('hides when package has no introductory offer', (tester) async {
      // Package without intro offer
      final pkg = Package.fromJson({
        'identifier': r'$rc_six_month',
        'packageType': 'SIX_MONTH',
        'product': {
          'identifier': 'budgie_premium_semi_annual',
          'description': 'Semi-annual plan',
          'title': '6 Month Premium',
          'price': 15.0,
          'priceString': '\$15.00',
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
      });

      await tester.pumpWidget(
        _wrap(const PremiumTrialBannerSection(), offerings: [pkg]),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('premium.trial_badge')), findsNothing);
    });

    testWidgets('shows trial banner when package has introductory offer', (
      tester,
    ) async {
      // Package WITH introductory offer (7-day free trial)
      final pkg = Package.fromJson({
        'identifier': r'$rc_six_month',
        'packageType': 'SIX_MONTH',
        'product': {
          'identifier': 'budgie_premium_semi_annual',
          'description': 'Semi-annual plan',
          'title': '6 Month Premium',
          'price': 15.0,
          'priceString': '\$15.00',
          'currencyCode': 'USD',
          'productCategory': 'SUBSCRIPTION',
          'introPrice': {
            'price': 0,
            'priceString': 'Free',
            'period': 'P1W',
            'cycles': 1,
            'periodUnit': 'WEEK',
            'periodNumberOfUnits': 1,
          },
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
      });

      await tester.pumpWidget(
        _wrap(const PremiumTrialBannerSection(), offerings: [pkg]),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('premium.trial_badge')), findsOneWidget);
    });
  });
}
