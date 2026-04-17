@Tags(['community'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/features/marketplace/widgets/marketplace_seller_card.dart';

import '../../../helpers/test_localization.dart';

void main() {
  group('MarketplaceSellerCard', () {
    testWidgets('should_render_username', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const MarketplaceSellerCard(
          sellerId: 'seller-1',
          username: 'TestBreeder',
          activeListingCount: 5,
        ),
      );

      expect(find.text('TestBreeder'), findsOneWidget);
    });

    testWidgets('should_show_verified_badge_when_verified', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const MarketplaceSellerCard(
          sellerId: 'seller-1',
          username: 'VerifiedUser',
          isVerifiedBreeder: true,
          activeListingCount: 3,
        ),
      );

      expect(find.byIcon(LucideIcons.badgeCheck), findsOneWidget);
    });

    testWidgets('should_not_show_verified_badge_when_not_verified',
        (tester) async {
      await pumpLocalizedWidget(
        tester,
        const MarketplaceSellerCard(
          sellerId: 'seller-1',
          username: 'RegularUser',
          isVerifiedBreeder: false,
          activeListingCount: 2,
        ),
      );

      expect(find.byIcon(LucideIcons.badgeCheck), findsNothing);
    });

    testWidgets('should_show_member_since_when_provided', (tester) async {
      await pumpLocalizedWidget(
        tester,
        MarketplaceSellerCard(
          sellerId: 'seller-1',
          username: 'OldTimer',
          memberSince: DateTime(2024, 1, 1),
          activeListingCount: 1,
        ),
      );

      // The member since text uses l10n key with months arg
      expect(find.text('marketplace.seller_member_since'), findsOneWidget);
    });

    testWidgets('should_render_card_with_inkwell', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const MarketplaceSellerCard(
          sellerId: 'seller-1',
          username: 'TapTest',
          activeListingCount: 0,
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(InkWell), findsOneWidget);
    });
  });
}
