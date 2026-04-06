@Tags(['community'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/features/marketplace/providers/marketplace_providers.dart';
import 'package:budgie_breeding_tracker/features/marketplace/widgets/marketplace_filter_bar.dart';

import '../../../helpers/test_localization.dart';

void main() {
  Widget buildSubject({
    MarketplaceFilter initialFilter = MarketplaceFilter.all,
  }) {
    return ProviderScope(
      overrides: [
        marketplaceFilterProvider.overrideWith(() {
          final notifier = MarketplaceFilterNotifier();
          return notifier;
        }),
      ],
      child: const MaterialApp(
        home: Scaffold(body: MarketplaceFilterBar()),
      ),
    );
  }

  group('MarketplaceFilterBar', () {
    testWidgets('renders all filter chips', (tester) async {
      await pumpLocalizedApp(tester, buildSubject());

      // Should render a FilterChip for each MarketplaceFilter value
      expect(
        find.byType(FilterChip),
        findsNWidgets(MarketplaceFilter.values.length),
      );
    });

    testWidgets('renders filter labels', (tester) async {
      await pumpLocalizedApp(tester, buildSubject());

      // All filter labels should be rendered (as raw keys)
      expect(find.text('common.all'), findsOneWidget);
      expect(find.text('marketplace.type_sale'), findsOneWidget);
      expect(find.text('marketplace.type_adoption'), findsOneWidget);
      expect(find.text('marketplace.type_trade'), findsOneWidget);
      expect(find.text('marketplace.type_wanted'), findsOneWidget);
    });

    testWidgets('first chip (all) is selected by default', (tester) async {
      await pumpLocalizedApp(tester, buildSubject());

      final allChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'common.all'),
      );
      expect(allChip.selected, isTrue);
    });

    testWidgets('tapping a chip updates selection', (tester) async {
      await pumpLocalizedApp(tester, buildSubject());

      // Tap the "sale" filter chip
      await tester.tap(find.widgetWithText(FilterChip, 'marketplace.type_sale'));
      await tester.pumpAndSettle();

      final saleChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'marketplace.type_sale'),
      );
      expect(saleChip.selected, isTrue);

      final allChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'common.all'),
      );
      expect(allChip.selected, isFalse);
    });

    testWidgets('uses horizontal scroll', (tester) async {
      await pumpLocalizedApp(tester, buildSubject());

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
