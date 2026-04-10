@Tags(['marketplace'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/data/remote/api/marketplace_listing_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/api/marketplace_favorite_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/marketplace_repository.dart';

class MockMarketplaceListingRemoteSource extends Mock
    implements MarketplaceListingRemoteSource {}

class MockMarketplaceFavoriteRemoteSource extends Mock
    implements MarketplaceFavoriteRemoteSource {}

Map<String, dynamic> _makeListingRow({
  required String id,
  String userId = 'u1',
  String title = 'Test Listing',
  String description = 'A beautiful budgie',
  double? price = 250.0,
  String currency = 'TRY',
  String listingType = 'sale',
  String gender = 'male',
  String species = 'Muhabbet Kusu',
  String city = 'Istanbul',
  String status = 'active',
  int viewCount = 0,
  int messageCount = 0,
  bool isVerifiedBreeder = false,
  bool isDeleted = false,
  bool needsReview = false,
  List<String> imageUrls = const [],
}) =>
    {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'listing_type': listingType,
      'gender': gender,
      'species': species,
      'mutation': null,
      'bird_id': null,
      'age': null,
      'image_urls': imageUrls,
      'city': city,
      'status': status,
      'view_count': viewCount,
      'message_count': messageCount,
      'is_verified_breeder': isVerifiedBreeder,
      'is_deleted': isDeleted,
      'needs_review': needsReview,
      'created_at': '2026-04-01T10:00:00Z',
      'updated_at': '2026-04-01T10:00:00Z',
    };

void main() {
  late MockMarketplaceListingRemoteSource listingSource;
  late MockMarketplaceFavoriteRemoteSource favoriteSource;
  late MarketplaceRepository repository;

  setUp(() {
    listingSource = MockMarketplaceListingRemoteSource();
    favoriteSource = MockMarketplaceFavoriteRemoteSource();

    repository = MarketplaceRepository(
      listingSource: listingSource,
      favoriteSource: favoriteSource,
    );
  });

  void stubFavoritesEmpty() {
    when(
      () => favoriteSource.fetchFavoritedListingIds(any()),
    ).thenAnswer((_) async => []);
  }

  group('getListings', () {
    test('returns enriched listings with favorite state', () async {
      when(
        () => listingSource.fetchListings(
          limit: 20,
          before: null,
          city: null,
          listingType: null,
          gender: null,
          minPrice: null,
          maxPrice: null,
        ),
      ).thenAnswer(
        (_) async => [
          _makeListingRow(id: 'l1', title: 'Blue Budgie'),
          _makeListingRow(id: 'l2', title: 'Green Budgie'),
        ],
      );

      when(
        () => favoriteSource.fetchFavoritedListingIds('u1'),
      ).thenAnswer((_) async => ['l1']);

      final listings = await repository.getListings(currentUserId: 'u1');

      expect(listings, hasLength(2));
      expect(listings[0].id, 'l1');
      expect(listings[0].title, 'Blue Budgie');
      expect(listings[0].isFavoritedByMe, isTrue);
      expect(listings[1].id, 'l2');
      expect(listings[1].isFavoritedByMe, isFalse);
    });

    test('passes filter parameters to remote source', () async {
      final before = DateTime(2026, 4, 1);
      when(
        () => listingSource.fetchListings(
          limit: 10,
          before: before,
          city: 'Ankara',
          listingType: 'sale',
          gender: 'female',
          minPrice: 100.0,
          maxPrice: 500.0,
        ),
      ).thenAnswer((_) async => []);
      stubFavoritesEmpty();

      final listings = await repository.getListings(
        currentUserId: 'u1',
        limit: 10,
        before: before,
        city: 'Ankara',
        listingType: 'sale',
        gender: 'female',
        minPrice: 100.0,
        maxPrice: 500.0,
      );

      expect(listings, isEmpty);
      verify(
        () => listingSource.fetchListings(
          limit: 10,
          before: before,
          city: 'Ankara',
          listingType: 'sale',
          gender: 'female',
          minPrice: 100.0,
          maxPrice: 500.0,
        ),
      ).called(1);
    });

    test('returns empty list when no listings', () async {
      when(
        () => listingSource.fetchListings(
          limit: 20,
          before: null,
          city: null,
          listingType: null,
          gender: null,
          minPrice: null,
          maxPrice: null,
        ),
      ).thenAnswer((_) async => []);

      final listings = await repository.getListings(currentUserId: 'u1');

      expect(listings, isEmpty);
      verifyNever(() => favoriteSource.fetchFavoritedListingIds(any()));
    });

    test('handles favorites fetch failure gracefully', () async {
      when(
        () => listingSource.fetchListings(
          limit: 20,
          before: null,
          city: null,
          listingType: null,
          gender: null,
          minPrice: null,
          maxPrice: null,
        ),
      ).thenAnswer(
        (_) async => [_makeListingRow(id: 'l1')],
      );

      when(
        () => favoriteSource.fetchFavoritedListingIds(any()),
      ).thenThrow(Exception('Network error'));

      final listings = await repository.getListings(currentUserId: 'u1');

      expect(listings, hasLength(1));
      expect(listings[0].isFavoritedByMe, isFalse);
    });
  });

  group('getById', () {
    test('returns enriched listing when found', () async {
      when(
        () => listingSource.fetchById('l1'),
      ).thenAnswer(
        (_) async => _makeListingRow(id: 'l1', title: 'Rare Budgie'),
      );

      when(
        () => favoriteSource.fetchFavoritedListingIds('u1'),
      ).thenAnswer((_) async => ['l1']);

      final listing = await repository.getById(
        id: 'l1',
        currentUserId: 'u1',
      );

      expect(listing, isNotNull);
      expect(listing!.id, 'l1');
      expect(listing.title, 'Rare Budgie');
      expect(listing.isFavoritedByMe, isTrue);
    });

    test('returns null when not found', () async {
      when(
        () => listingSource.fetchById('missing'),
      ).thenAnswer((_) async => null);

      final listing = await repository.getById(
        id: 'missing',
        currentUserId: 'u1',
      );

      expect(listing, isNull);
    });

    test('returns listing with isFavoritedByMe false when not favorited',
        () async {
      when(
        () => listingSource.fetchById('l1'),
      ).thenAnswer((_) async => _makeListingRow(id: 'l1'));
      stubFavoritesEmpty();

      final listing = await repository.getById(
        id: 'l1',
        currentUserId: 'u1',
      );

      expect(listing, isNotNull);
      expect(listing!.isFavoritedByMe, isFalse);
    });
  });

  group('getByUser', () {
    test('fetches listings by target user and enriches', () async {
      when(() => listingSource.fetchByUser('u2')).thenAnswer(
        (_) async => [
          _makeListingRow(id: 'l1', userId: 'u2'),
          _makeListingRow(id: 'l2', userId: 'u2'),
        ],
      );
      stubFavoritesEmpty();

      final listings = await repository.getByUser(
        userId: 'u2',
        currentUserId: 'u1',
      );

      expect(listings, hasLength(2));
      verify(() => listingSource.fetchByUser('u2')).called(1);
    });

    test('returns empty list when user has no listings', () async {
      when(
        () => listingSource.fetchByUser('u2'),
      ).thenAnswer((_) async => []);

      final listings = await repository.getByUser(
        userId: 'u2',
        currentUserId: 'u1',
      );

      expect(listings, isEmpty);
    });
  });

  group('create', () {
    test('delegates to listingSource.insert and returns model', () async {
      final data = {
        'user_id': 'u1',
        'title': 'New Budgie',
        'listing_type': 'sale',
      };

      when(() => listingSource.insert(data)).thenAnswer(
        (_) async => _makeListingRow(id: 'l-new', title: 'New Budgie'),
      );

      final listing = await repository.create(data);

      expect(listing.id, 'l-new');
      expect(listing.title, 'New Budgie');
      verify(() => listingSource.insert(data)).called(1);
    });

    test('rethrows on insert failure', () async {
      when(() => listingSource.insert(any())).thenThrow(
        Exception('Insert failed'),
      );

      expect(
        () => repository.create({'title': 'Fail'}),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('updateListing', () {
    test('delegates to listingSource.update and returns updated model',
        () async {
      final data = {'title': 'Updated Title'};

      when(() => listingSource.update('l1', data, userId: 'u1')).thenAnswer(
        (_) async => _makeListingRow(id: 'l1', title: 'Updated Title'),
      );

      final listing = await repository.updateListing('l1', data, userId: 'u1');

      expect(listing.id, 'l1');
      expect(listing.title, 'Updated Title');
      verify(() => listingSource.update('l1', data, userId: 'u1')).called(1);
    });

    test('rethrows on update failure', () async {
      when(() => listingSource.update(any(), any(), userId: any(named: 'userId'))).thenThrow(
        Exception('Update failed'),
      );

      expect(
        () => repository.updateListing('l1', {'title': 'Fail'}, userId: 'u1'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('delete', () {
    test('delegates to listingSource.softDelete', () async {
      when(() => listingSource.softDelete('l1', userId: 'u1')).thenAnswer((_) async {});

      await repository.delete('l1', userId: 'u1');

      verify(() => listingSource.softDelete('l1', userId: 'u1')).called(1);
    });

    test('rethrows on delete failure', () async {
      when(() => listingSource.softDelete(any(), userId: any(named: 'userId'))).thenThrow(
        Exception('Delete failed'),
      );

      expect(
        () => repository.delete('l1', userId: 'u1'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('updateStatus', () {
    test('delegates to listingSource.updateStatus', () async {
      when(
        () => listingSource.updateStatus('l1', 'sold', userId: 'u1'),
      ).thenAnswer((_) async {});

      await repository.updateStatus('l1', 'sold', userId: 'u1');

      verify(() => listingSource.updateStatus('l1', 'sold', userId: 'u1')).called(1);
    });
  });

  group('incrementViewCount', () {
    test('delegates to listingSource.incrementViewCount', () async {
      when(
        () => listingSource.incrementViewCount('l1'),
      ).thenAnswer((_) async {});

      await repository.incrementViewCount('l1');

      verify(() => listingSource.incrementViewCount('l1')).called(1);
    });
  });

  group('toggleFavorite', () {
    test('removes favorite when already favorited', () async {
      when(
        () => favoriteSource.removeFavorite('u1', 'l1'),
      ).thenAnswer((_) async {});

      await repository.toggleFavorite(
        userId: 'u1',
        listingId: 'l1',
        isFavorited: true,
      );

      verify(() => favoriteSource.removeFavorite('u1', 'l1')).called(1);
      verifyNever(() => favoriteSource.addFavorite(any(), any()));
    });

    test('adds favorite when not favorited', () async {
      when(
        () => favoriteSource.addFavorite('u1', 'l1'),
      ).thenAnswer((_) async {});

      await repository.toggleFavorite(
        userId: 'u1',
        listingId: 'l1',
        isFavorited: false,
      );

      verify(() => favoriteSource.addFavorite('u1', 'l1')).called(1);
      verifyNever(() => favoriteSource.removeFavorite(any(), any()));
    });

    test('rethrows on favorite toggle failure', () async {
      when(
        () => favoriteSource.addFavorite(any(), any()),
      ).thenThrow(Exception('Favorite failed'));

      expect(
        () => repository.toggleFavorite(
          userId: 'u1',
          listingId: 'l1',
          isFavorited: false,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('search', () {
    test('returns matching enriched listings', () async {
      when(() => listingSource.search('mavi', limit: 20)).thenAnswer(
        (_) async => [
          _makeListingRow(id: 'l1', title: 'Mavi Muhabbet Kusu'),
        ],
      );

      when(
        () => favoriteSource.fetchFavoritedListingIds('u1'),
      ).thenAnswer((_) async => ['l1']);

      final listings = await repository.search(
        query: 'mavi',
        currentUserId: 'u1',
      );

      expect(listings, hasLength(1));
      expect(listings[0].title, 'Mavi Muhabbet Kusu');
      expect(listings[0].isFavoritedByMe, isTrue);
    });

    test('returns empty for no matches', () async {
      when(
        () => listingSource.search('nonexistent', limit: 20),
      ).thenAnswer((_) async => []);

      final listings = await repository.search(
        query: 'nonexistent',
        currentUserId: 'u1',
      );

      expect(listings, isEmpty);
    });

    test('passes custom limit to remote source', () async {
      when(
        () => listingSource.search('budgie', limit: 10),
      ).thenAnswer((_) async => []);
      stubFavoritesEmpty();

      await repository.search(
        query: 'budgie',
        currentUserId: 'u1',
        limit: 10,
      );

      verify(() => listingSource.search('budgie', limit: 10)).called(1);
    });
  });

  group('_enrichListings', () {
    test('skips favorites fetch for empty rows', () async {
      when(
        () => listingSource.fetchListings(
          limit: 20,
          before: null,
          city: null,
          listingType: null,
          gender: null,
          minPrice: null,
          maxPrice: null,
        ),
      ).thenAnswer((_) async => []);

      await repository.getListings(currentUserId: 'u1');

      verifyNever(() => favoriteSource.fetchFavoritedListingIds(any()));
    });

    test('parses listing type correctly including unknown', () async {
      when(
        () => listingSource.fetchListings(
          limit: 20,
          before: null,
          city: null,
          listingType: null,
          gender: null,
          minPrice: null,
          maxPrice: null,
        ),
      ).thenAnswer(
        (_) async => [
          _makeListingRow(id: 'l1', listingType: 'adoption'),
          _makeListingRow(id: 'l2', listingType: 'invalid_type'),
        ],
      );
      stubFavoritesEmpty();

      final listings = await repository.getListings(currentUserId: 'u1');

      expect(listings, hasLength(2));
      expect(listings[0].listingType.name, 'adoption');
      expect(listings[1].listingType.name, 'unknown');
    });

    test('parses listing fields correctly', () async {
      when(() => listingSource.fetchById('l1')).thenAnswer(
        (_) async => _makeListingRow(
          id: 'l1',
          title: 'Beautiful Budgie',
          price: 350.0,
          currency: 'TRY',
          city: 'Ankara',
          viewCount: 42,
          species: 'Muhabbet',
        ),
      );
      stubFavoritesEmpty();

      final listing = await repository.getById(
        id: 'l1',
        currentUserId: 'u1',
      );

      expect(listing, isNotNull);
      expect(listing!.price, 350.0);
      expect(listing.currency, 'TRY');
      expect(listing.city, 'Ankara');
      expect(listing.viewCount, 42);
      expect(listing.species, 'Muhabbet');
    });
  });
}
