@Tags(['community'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/features/marketplace/providers/marketplace_providers.dart';
import 'package:budgie_breeding_tracker/features/marketplace/widgets/marketplace_filter_sheet.dart';

import '../../../helpers/test_localization.dart';

Widget _buildSubject() {
  return ProviderScope(
    overrides: [
      marketplacePriceRangeProvider.overrideWith(
        () => MarketplacePriceRangeNotifier(),
      ),
      marketplaceCityFilterProvider.overrideWith(
        () => MarketplaceCityFilterNotifier(),
      ),
      marketplaceGenderFilterProvider.overrideWith(
        () => MarketplaceGenderFilterNotifier(),
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: MarketplaceFilterSheet(),
      ),
    ),
  );
}

void main() {
  group('MarketplaceFilterSheet', () {
    testWidgets('should_render_filter_header_and_sections', (tester) async {
      await pumpLocalizedApp(tester, _buildSubject());

      expect(find.text('marketplace.filter_results'), findsOneWidget);
      expect(find.text('marketplace.price_range'), findsOneWidget);
      expect(find.text('marketplace.city_label'), findsOneWidget);
      expect(find.text('marketplace.gender_filter'), findsOneWidget);
    });

    testWidgets('should_render_gender_filter_chips', (tester) async {
      await pumpLocalizedApp(tester, _buildSubject());

      expect(find.byType(FilterChip), findsNWidgets(3));
      expect(find.text('birds.male'), findsOneWidget);
      expect(find.text('birds.female'), findsOneWidget);
      expect(find.text('marketplace.gender_unknown'), findsOneWidget);
    });

    testWidgets('should_render_action_buttons', (tester) async {
      await pumpLocalizedApp(tester, _buildSubject());

      expect(find.text('marketplace.clear_filters'), findsOneWidget);
      expect(find.text('marketplace.apply_filters'), findsOneWidget);
    });

    testWidgets('should_toggle_gender_chip_when_tapped', (tester) async {
      await pumpLocalizedApp(tester, _buildSubject());

      // Tap male chip
      await tester.tap(find.text('birds.male'));
      await tester.pump();

      // Verify chip is selected (FilterChip with selected=true)
      final maleChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'birds.male'),
      );
      expect(maleChip.selected, isTrue);
    });

    testWidgets('should_render_price_range_text_fields', (tester) async {
      await pumpLocalizedApp(tester, _buildSubject());

      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(find.text('marketplace.min_price'), findsOneWidget);
      expect(find.text('marketplace.max_price'), findsOneWidget);
      expect(find.text('marketplace.city_filter'), findsOneWidget);
    });
  });
}
