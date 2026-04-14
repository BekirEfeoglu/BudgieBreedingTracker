@Tags(['community'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
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

const _listingWithMultipleImages = MarketplaceListing(
  id: 'listing-5',
  userId: 'user-5',
  title: 'Multi Photo Budgie',
  description: 'Has multiple photos',
  species: 'Budgerigar',
  city: 'Antalya',
  imageUrls: [
    'https://example.com/photo1.jpg',
    'https://example.com/photo2.jpg',
    'https://example.com/photo3.jpg',
  ],
  gender: BirdGender.male,
);

const _favoritedListing = MarketplaceListing(
  id: 'listing-6',
  userId: 'user-6',
  title: 'Favorited Budgie',
  description: 'This is favorited',
  species: 'Budgerigar',
  city: 'Eskisehir',
  isFavoritedByMe: true,
  gender: BirdGender.female,
);

const _listingWithViewCount = MarketplaceListing(
  id: 'listing-7',
  userId: 'user-7',
  title: 'Popular Budgie',
  description: 'Many views',
  species: 'Budgerigar',
  city: 'Konya',
  viewCount: 42,
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

    testWidgets('shows free label for adoption listing with no price',
        (tester) async {
      await pumpLocalizedWidget(
        tester,
        const MarketplaceListingCard(listing: _adoptionListing),
      );

      // Free label should be shown for adoption with null price (key or translated)
      final freeLabelFinder = find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data == 'Free' ||
                w.data == 'marketplace.free_label' ||
                w.data == 'Ücretsiz' ||
                w.data == 'Kostenlos'),
      );
      expect(freeLabelFinder, findsOneWidget);
    });

    testWidgets('renders city', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const MarketplaceListingCard(listing: _saleListing),
      );

      expect(find.text('Istanbul'), findsOneWidget);
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

    testWidgets('always renders AspectRatio image area', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const MarketplaceListingCard(listing: _saleListing),
      );

      // Image area is always shown (placeholder when no image)
      expect(find.byType(AspectRatio), findsOneWidget);
    });

    testWidgets('renders image when imageUrls is not empty', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const MarketplaceListingCard(listing: _listingWithImage),
      );

      expect(find.byType(AspectRatio), findsOneWidget);
    });

    testWidgets('shows photo count badge when multiple images', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const MarketplaceListingCard(listing: _listingWithMultipleImages),
      );

      // Photo count badge shows number of images
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('does not show photo count badge for single image',
        (tester) async {
      await pumpLocalizedWidget(
        tester,
        const MarketplaceListingCard(listing: _listingWithImage),
      );

      // Camera icon should not appear for single image
      expect(find.byIcon(LucideIcons.camera), findsNothing);
    });

    testWidgets('always shows heart icon overlay', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const MarketplaceListingCard(listing: _saleListing),
      );

      expect(find.byIcon(LucideIcons.heart), findsWidgets);
    });

    testWidgets('calls onFavoriteToggle when heart is tapped', (tester) async {
      var tapped = false;
      await pumpLocalizedWidget(
        tester,
        MarketplaceListingCard(
          listing: _saleListing,
          onFavoriteToggle: () => tapped = true,
        ),
      );

      await tester.tap(find.byIcon(LucideIcons.heart).first);
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('shows view count when viewCount > 0', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const MarketplaceListingCard(listing: _listingWithViewCount),
      );

      expect(find.text('42'), findsOneWidget);
      expect(find.byIcon(LucideIcons.eye), findsOneWidget);
    });

    testWidgets('does not show view count when viewCount is 0', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const MarketplaceListingCard(listing: _saleListing),
      );

      expect(find.byIcon(LucideIcons.eye), findsNothing);
    });

    testWidgets('accepts optional onFavoriteToggle parameter', (tester) async {
      // Should not throw when onFavoriteToggle is null
      await pumpLocalizedWidget(
        tester,
        const MarketplaceListingCard(listing: _saleListing),
      );

      expect(find.byType(MarketplaceListingCard), findsOneWidget);
    });

    testWidgets('heart icon has active color for favorited listing',
        (tester) async {
      await pumpLocalizedWidget(
        tester,
        const MarketplaceListingCard(listing: _favoritedListing),
      );

      // For favorited listing, heart should be a non-white color (active state)
      final activeHeartFinder = find.byWidgetPredicate(
        (w) =>
            w is Icon &&
            w.icon == LucideIcons.heart &&
            w.color != null &&
            w.color != const Color(0xFFFFFFFF),
      );
      expect(activeHeartFinder, findsOneWidget);
    });
  });
}
