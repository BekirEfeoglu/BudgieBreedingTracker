import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/marketplace_enums.dart';
import 'package:budgie_breeding_tracker/data/models/marketplace_listing_model.dart';

void main() {
  group('MarketplaceListing model', () {
    group('fromJson / toJson', () {
      test('round-trips correctly with all fields', () {
        final listing = MarketplaceListing(
          id: 'listing-123',
          userId: 'user-1',
          username: 'testuser',
          avatarUrl: 'https://example.com/avatar.jpg',
          listingType: MarketplaceListingType.sale,
          title: 'Muhabbet Kuşu Satılık',
          description: 'Sağlıklı muhabbet kuşu',
          price: 1500.0,
          currency: 'TRY',
          birdId: 'bird-42',
          species: 'Muhabbet Kuşu',
          mutation: 'Lutino',
          gender: BirdGender.male,
          age: '6 ay',
          imageUrls: ['https://example.com/img1.jpg', 'https://example.com/img2.jpg'],
          city: 'Istanbul',
          status: MarketplaceListingStatus.active,
          viewCount: 42,
          messageCount: 5,
          isVerifiedBreeder: true,
          isDeleted: false,
          needsReview: false,
          createdAt: DateTime(2024, 3, 1),
          updatedAt: DateTime(2024, 6, 15),
        );

        final json = listing.toJson();
        final restored = MarketplaceListing.fromJson(json);

        expect(restored.id, listing.id);
        expect(restored.userId, listing.userId);
        expect(restored.username, listing.username);
        expect(restored.avatarUrl, listing.avatarUrl);
        expect(restored.listingType, listing.listingType);
        expect(restored.title, listing.title);
        expect(restored.description, listing.description);
        expect(restored.price, listing.price);
        expect(restored.currency, listing.currency);
        expect(restored.birdId, listing.birdId);
        expect(restored.species, listing.species);
        expect(restored.mutation, listing.mutation);
        expect(restored.gender, listing.gender);
        expect(restored.age, listing.age);
        expect(restored.imageUrls, listing.imageUrls);
        expect(restored.city, listing.city);
        expect(restored.status, listing.status);
        expect(restored.viewCount, listing.viewCount);
        expect(restored.messageCount, listing.messageCount);
        expect(restored.isVerifiedBreeder, listing.isVerifiedBreeder);
        expect(restored.isDeleted, listing.isDeleted);
        expect(restored.needsReview, listing.needsReview);
      });

      test('default values are correct', () {
        final listing = MarketplaceListing.fromJson({
          'id': 'listing-1',
          'user_id': 'user-1',
        });

        expect(listing.username, '');
        expect(listing.avatarUrl, isNull);
        expect(listing.listingType, MarketplaceListingType.sale);
        expect(listing.title, '');
        expect(listing.description, '');
        expect(listing.price, isNull);
        expect(listing.currency, 'TRY');
        expect(listing.birdId, isNull);
        expect(listing.species, '');
        expect(listing.mutation, isNull);
        expect(listing.gender, BirdGender.unknown);
        expect(listing.age, isNull);
        expect(listing.imageUrls, isEmpty);
        expect(listing.city, '');
        expect(listing.status, MarketplaceListingStatus.active);
        expect(listing.viewCount, 0);
        expect(listing.messageCount, 0);
        expect(listing.isVerifiedBreeder, false);
        expect(listing.isDeleted, false);
        expect(listing.needsReview, false);
        expect(listing.isFavoritedByMe, false);
      });
    });

    group('unknown enum deserialization', () {
      test('unknown listingType deserializes to MarketplaceListingType.unknown', () {
        final listing = MarketplaceListing.fromJson({
          'id': 'listing-1',
          'user_id': 'user-1',
          'listing_type': 'barter_supreme',
        });

        expect(listing.listingType, MarketplaceListingType.unknown);
      });

      test('unknown status deserializes to MarketplaceListingStatus.unknown', () {
        final listing = MarketplaceListing.fromJson({
          'id': 'listing-1',
          'user_id': 'user-1',
          'status': 'pending_review',
        });

        expect(listing.status, MarketplaceListingStatus.unknown);
      });

      test('unknown gender deserializes to BirdGender.unknown', () {
        final listing = MarketplaceListing.fromJson({
          'id': 'listing-1',
          'user_id': 'user-1',
          'gender': 'alien',
        });

        expect(listing.gender, BirdGender.unknown);
      });
    });

    group('isFavoritedByMe excluded from JSON', () {
      test('isFavoritedByMe is not deserialized from JSON (always false)', () {
        final listing = MarketplaceListing.fromJson({
          'id': 'listing-1',
          'user_id': 'user-1',
          'is_favorited_by_me': true,
        });

        // includeFromJson: false means it always uses @Default(false)
        expect(listing.isFavoritedByMe, false);
      });
    });
  });

  group('MarketplaceListingX extension', () {
    group('priceDisplay', () {
      test('formats correctly with price 1500 and currency TRY', () {
        final listing = MarketplaceListing(
          id: 'l-1',
          userId: 'u-1',
          price: 1500,
          currency: 'TRY',
        );

        expect(listing.priceDisplay, '1500 TRY');
      });

      test('returns empty string when price is null', () {
        final listing = MarketplaceListing(
          id: 'l-1',
          userId: 'u-1',
          price: null,
        );

        expect(listing.priceDisplay, '');
      });

      test('formats with different currency', () {
        final listing = MarketplaceListing(
          id: 'l-1',
          userId: 'u-1',
          price: 250.0,
          currency: 'EUR',
        );

        expect(listing.priceDisplay, '250 EUR');
      });
    });

    group('hasBirdLinked', () {
      test('returns true when birdId is set', () {
        final listing = MarketplaceListing(
          id: 'l-1',
          userId: 'u-1',
          birdId: 'bird-42',
        );

        expect(listing.hasBirdLinked, isTrue);
      });

      test('returns false when birdId is null', () {
        final listing = MarketplaceListing(
          id: 'l-1',
          userId: 'u-1',
          birdId: null,
        );

        expect(listing.hasBirdLinked, isFalse);
      });

      test('returns false when birdId is empty string', () {
        final listing = MarketplaceListing(
          id: 'l-1',
          userId: 'u-1',
          birdId: '',
        );

        expect(listing.hasBirdLinked, isFalse);
      });
    });

    group('primaryImageUrl', () {
      test('returns first image when imageUrls is not empty', () {
        final listing = MarketplaceListing(
          id: 'l-1',
          userId: 'u-1',
          imageUrls: [
            'https://example.com/img1.jpg',
            'https://example.com/img2.jpg',
          ],
        );

        expect(listing.primaryImageUrl, 'https://example.com/img1.jpg');
      });

      test('returns null when imageUrls is empty', () {
        final listing = MarketplaceListing(
          id: 'l-1',
          userId: 'u-1',
          imageUrls: const [],
        );

        expect(listing.primaryImageUrl, isNull);
      });
    });
  });
}
