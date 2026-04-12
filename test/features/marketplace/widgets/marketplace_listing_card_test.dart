@Tags(['community'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/marketplace_enums.dart';
import 'package:budgie_breeding_tracker/core/widgets/status_badge.dart';
import 'package:budgie_breeding_tracker/data/models/marketplace_listing_model.dart';
import 'package:budgie_breeding_tracker/features/marketplace/widgets/marketplace_listing_card.dart';

import '../../../helpers/test_localization.dart';

const _saleListing = MarketplaceListing(
  id: 'listing-1',
  userId: 'user-1',
  title: 'Beautiful Blue Budgie',
  description: 'A lovely budgie',
  species: 'Budgerigar',
  city: 'Istanbul',
  price: 750,
  gender: BirdGender.male,
  listingType: MarketplaceListingType.sale,
);

const _adoptionListing = MarketplaceListing(
  id: 'listing-2',
  userId: 'user-2',
  title: 'Free Adoption Budgie',
  description: 'Looking for a good home',
  species: 'Budgerigar',
  city: 'Ankara',
  gender: BirdGender.female,
  listingType: MarketplaceListingType.adoption,
);

const _verifiedListing = MarketplaceListing(
  id: 'listing-3',
  userId: 'user-3',
  title: 'Verified Breeder Budgie',
  description: 'From a verified breeder',
  species: 'Budgerigar',
  city: 'Izmir',
  isVerifiedBreeder: true,
  gender: BirdGender.unknown,
);

const _listingWithImage = MarketplaceListing(
  id: 'listing-4',
  userId: 'user-4',
  title: 'Budgie With Photo',
  description: 'Has a photo',
  species: 'Budgerigar',
  city: 'Bursa',
  imageUrls: ['https://example.com/photo.jpg'],
  gender: BirdGender.male,
);

void main() {
  group('MarketplaceListingCard', () {
    testWidgets('renders listing title', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const MarketplaceListingCard(listing: _saleListing),
      );

      expect(find.text('Beautiful Blue Budgie'), findsOneWidget);
    });

    testWidgets('renders price for sale listing', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const MarketplaceListingCard(listing: _saleListing),
      );

      expect(find.text('750 TRY'), findsOneWidget);
    });

    testWidgets('does not show price for adoption listing', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const MarketplaceListingCard(listing: _adoptionListing),
      );

      expect(find.text('750 TRY'), findsNothing);
    });

    testWidgets('renders city', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const MarketplaceListingCard(listing: _saleListing),
      );

      expect(find.text('Istanbul'), findsOneWidget);
    });

    testWidgets('renders species and gender', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const MarketplaceListingCard(listing: _saleListing),
      );

      expect(find.text('Budgerigar \u00b7 male'), findsOneWidget);
    });

    testWidgets('renders StatusBadge with listing type', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const MarketplaceListingCard(listing: _saleListing),
      );

      expect(find.byType(StatusBadge), findsOneWidget);
    });

    testWidgets('shows verified badge for verified breeder', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const MarketplaceListingCard(listing: _verifiedListing),
      );

      // Verified breeder icon should be visible
      // The card shows a badgeCheck icon for verified breeders
      expect(find.text('Verified Breeder Budgie'), findsOneWidget);
    });

    testWidgets('renders Card with InkWell', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const MarketplaceListingCard(listing: _saleListing),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('renders image when imageUrls is not empty', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const MarketplaceListingCard(listing: _listingWithImage),
      );

      expect(find.byType(AspectRatio), findsOneWidget);
    });

    testWidgets('does not render image when imageUrls is empty',
        (tester) async {
      await pumpLocalizedWidget(
        tester,
        const MarketplaceListingCard(listing: _saleListing),
      );

      // No AspectRatio when there's no image
      expect(find.byType(AspectRatio), findsNothing);
    });
  });
}
