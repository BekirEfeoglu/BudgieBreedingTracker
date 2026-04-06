@Tags(['community'])
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/data/repositories/marketplace_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/marketplace/providers/marketplace_providers.dart';

class MockMarketplaceRepository extends Mock implements MarketplaceRepository {}

MarketplaceListing _makeListing({
  required String id,
  String title = 'Test Bird',
  String description = 'A nice budgie',
  String species = 'Budgerigar',
  String city = 'Istanbul',
  String? mutation,
  double? price,
  MarketplaceListingType listingType = MarketplaceListingType.sale,
  DateTime? createdAt,
}) {
  return MarketplaceListing(
    id: id,
    userId: 'seller-1',
    title: title,
    description: description,
    species: species,
    city: city,
    mutation: mutation,
    price: price,
    listingType: listingType,
    createdAt: createdAt ?? DateTime(2024, 6, 1),
  );
}

void main() {
  group('isMarketplaceEnabledProvider', () {
    test('returns true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(isMarketplaceEnabledProvider), isTrue);
    });
  });

  group('MarketplaceFilter', () {
    test('has 5 values', () {
      expect(MarketplaceFilter.values, hasLength(5));
    });

    test('label getter returns localization key strings', () {
      // .tr() returns the raw key in test environment
      for (final filter in MarketplaceFilter.values) {
        expect(filter.label, isA<String>());
        expect(filter.label, isNotEmpty);
      }
    });
  });

  group('MarketplaceSort', () {
    test('has 3 values', () {
      expect(MarketplaceSort.values, hasLength(3));
    });

    test('label getter returns localization key strings', () {
      for (final sort in MarketplaceSort.values) {
        expect(sort.label, isA<String>());
        expect(sort.label, isNotEmpty);
      }
    });
  });

  group('marketplaceFilterProvider', () {
    test('defaults to all', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(marketplaceFilterProvider), MarketplaceFilter.all);
    });

    test('can be updated to sale', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(marketplaceFilterProvider.notifier).state =
          MarketplaceFilter.sale;

      expect(container.read(marketplaceFilterProvider), MarketplaceFilter.sale);
    });

    test('can cycle through all filter values', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      for (final filter in MarketplaceFilter.values) {
        container.read(marketplaceFilterProvider.notifier).state = filter;
        expect(container.read(marketplaceFilterProvider), filter);
      }
    });
  });

  group('marketplaceSortProvider', () {
    test('defaults to newest', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(marketplaceSortProvider), MarketplaceSort.newest);
    });

    test('can be updated to priceAsc', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(marketplaceSortProvider.notifier).state =
          MarketplaceSort.priceAsc;

      expect(
        container.read(marketplaceSortProvider),
        MarketplaceSort.priceAsc,
      );
    });

    test('can be updated to priceDesc', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(marketplaceSortProvider.notifier).state =
          MarketplaceSort.priceDesc;

      expect(
        container.read(marketplaceSortProvider),
        MarketplaceSort.priceDesc,
      );
    });
  });

  group('marketplaceSearchQueryProvider', () {
    test('defaults to empty string', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(marketplaceSearchQueryProvider), isEmpty);
    });

    test('can be updated with a query', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(marketplaceSearchQueryProvider.notifier).state = 'mavi';

      expect(container.read(marketplaceSearchQueryProvider), 'mavi');
    });

    test('can be cleared back to empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(marketplaceSearchQueryProvider.notifier).state = 'query';
      container.read(marketplaceSearchQueryProvider.notifier).state = '';

      expect(container.read(marketplaceSearchQueryProvider), isEmpty);
    });
  });

  group('marketplaceCityFilterProvider', () {
    test('defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(marketplaceCityFilterProvider), isNull);
    });

    test('can be set to a city', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(marketplaceCityFilterProvider.notifier).state = 'Ankara';

      expect(container.read(marketplaceCityFilterProvider), 'Ankara');
    });

    test('can be cleared back to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(marketplaceCityFilterProvider.notifier).state = 'Izmir';
      container.read(marketplaceCityFilterProvider.notifier).state = null;

      expect(container.read(marketplaceCityFilterProvider), isNull);
    });
  });

  group('marketplaceListingsProvider', () {
    late MockMarketplaceRepository mockRepo;

    setUp(() {
      mockRepo = MockMarketplaceRepository();
    });

    test('fetches listings from repository', () async {
      final listings = [
        _makeListing(id: 'l1', title: 'Blue Budgie'),
        _makeListing(id: 'l2', title: 'Green Budgie'),
      ];
      when(
        () => mockRepo.getListings(
          currentUserId: 'user-1',
          city: any(named: 'city'),
          listingType: any(named: 'listingType'),
        ),
      ).thenAnswer((_) async => listings);

      final container = ProviderContainer(
        overrides: [
          marketplaceRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        marketplaceListingsProvider('user-1').future,
      );

      expect(result, hasLength(2));
      expect(result.first.title, 'Blue Budgie');
      verify(
        () => mockRepo.getListings(
          currentUserId: 'user-1',
          city: null,
          listingType: null,
        ),
      ).called(1);
    });

    test('passes listingType when filter is not all', () async {
      when(
        () => mockRepo.getListings(
          currentUserId: 'user-1',
          city: any(named: 'city'),
          listingType: any(named: 'listingType'),
        ),
      ).thenAnswer((_) async => []);

      final container = ProviderContainer(
        overrides: [
          marketplaceRepositoryProvider.overrideWithValue(mockRepo),
          marketplaceFilterProvider.overrideWith(
            () => _FixedFilterNotifier(MarketplaceFilter.trade),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(marketplaceListingsProvider('user-1').future);

      verify(
        () => mockRepo.getListings(
          currentUserId: 'user-1',
          city: null,
          listingType: 'trade',
        ),
      ).called(1);
    });

    test('passes city when city filter is set', () async {
      when(
        () => mockRepo.getListings(
          currentUserId: 'user-1',
          city: any(named: 'city'),
          listingType: any(named: 'listingType'),
        ),
      ).thenAnswer((_) async => []);

      final container = ProviderContainer(
        overrides: [
          marketplaceRepositoryProvider.overrideWithValue(mockRepo),
          marketplaceCityFilterProvider.overrideWith(
            () => _FixedCityNotifier('Ankara'),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(marketplaceListingsProvider('user-1').future);

      verify(
        () => mockRepo.getListings(
          currentUserId: 'user-1',
          city: 'Ankara',
          listingType: null,
        ),
      ).called(1);
    });

    test('propagates error when repository throws', () async {
      when(
        () => mockRepo.getListings(
          currentUserId: 'user-1',
          city: any(named: 'city'),
          listingType: any(named: 'listingType'),
        ),
      ).thenAnswer((_) async => throw Exception('network error'));

      final container = ProviderContainer(
        overrides: [
          marketplaceRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      AsyncValue<List<MarketplaceListing>>? lastValue;
      container.listen(
        marketplaceListingsProvider('user-1'),
        (_, next) => lastValue = next,
        fireImmediately: true,
      );

      // Let the FutureProvider complete
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(lastValue, isNotNull);
      expect(lastValue!.hasError, isTrue);
      expect(lastValue!.error, isA<Exception>());
    });
  });

  group('marketplaceListingByIdProvider', () {
    late MockMarketplaceRepository mockRepo;

    setUp(() {
      mockRepo = MockMarketplaceRepository();
    });

    test('fetches a single listing by id', () async {
      final listing = _makeListing(id: 'l1', title: 'Special Budgie');
      when(
        () => mockRepo.getById(id: 'l1', currentUserId: 'user-1'),
      ).thenAnswer((_) async => listing);

      final container = ProviderContainer(
        overrides: [
          marketplaceRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        marketplaceListingByIdProvider(
          (id: 'l1', userId: 'user-1'),
        ).future,
      );

      expect(result, isNotNull);
      expect(result!.id, 'l1');
      expect(result.title, 'Special Budgie');
    });

    test('returns null when listing not found', () async {
      when(
        () => mockRepo.getById(id: 'missing', currentUserId: 'user-1'),
      ).thenAnswer((_) async => null);

      final container = ProviderContainer(
        overrides: [
          marketplaceRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        marketplaceListingByIdProvider(
          (id: 'missing', userId: 'user-1'),
        ).future,
      );

      expect(result, isNull);
    });
  });

  group('myMarketplaceListingsProvider', () {
    late MockMarketplaceRepository mockRepo;

    setUp(() {
      mockRepo = MockMarketplaceRepository();
    });

    test('fetches user listings', () async {
      final listings = [
        _makeListing(id: 'l1'),
        _makeListing(id: 'l2'),
      ];
      when(
        () => mockRepo.getByUser(userId: 'user-1', currentUserId: 'user-1'),
      ).thenAnswer((_) async => listings);

      final container = ProviderContainer(
        overrides: [
          marketplaceRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        myMarketplaceListingsProvider('user-1').future,
      );

      expect(result, hasLength(2));
      verify(
        () => mockRepo.getByUser(userId: 'user-1', currentUserId: 'user-1'),
      ).called(1);
    });

    test('returns empty list when user has no listings', () async {
      when(
        () => mockRepo.getByUser(userId: 'user-1', currentUserId: 'user-1'),
      ).thenAnswer((_) async => []);

      final container = ProviderContainer(
        overrides: [
          marketplaceRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        myMarketplaceListingsProvider('user-1').future,
      );

      expect(result, isEmpty);
    });
  });

  group('filteredMarketplaceListingsProvider', () {
    final listings = [
      _makeListing(
        id: 'l1',
        title: 'Blue Budgie',
        description: 'Very beautiful',
        species: 'Budgerigar',
        city: 'Istanbul',
        mutation: 'Opaline',
        price: 500,
        createdAt: DateTime(2024, 6, 1),
      ),
      _makeListing(
        id: 'l2',
        title: 'Green Budgie',
        description: 'Healthy bird',
        species: 'Budgerigar',
        city: 'Ankara',
        mutation: 'Normal',
        price: 200,
        createdAt: DateTime(2024, 7, 1),
      ),
      _makeListing(
        id: 'l3',
        title: 'Yellow Canary',
        description: 'Singing bird',
        species: 'Canary',
        city: 'Izmir',
        price: 1000,
        createdAt: DateTime(2024, 5, 1),
      ),
    ];

    test('returns all listings when no search query', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = container.read(
        filteredMarketplaceListingsProvider(listings),
      );

      expect(result, hasLength(3));
    });

    test('sorts by newest by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = container.read(
        filteredMarketplaceListingsProvider(listings),
      );

      expect(result.first.id, 'l2'); // July 2024
      expect(result.last.id, 'l3'); // May 2024
    });

    test('sorts by price ascending', () {
      final container = ProviderContainer(
        overrides: [
          marketplaceSortProvider.overrideWith(
            () => _FixedSortNotifier(MarketplaceSort.priceAsc),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(
        filteredMarketplaceListingsProvider(listings),
      );

      expect(result.first.price, 200);
      expect(result.last.price, 1000);
    });

    test('sorts by price descending', () {
      final container = ProviderContainer(
        overrides: [
          marketplaceSortProvider.overrideWith(
            () => _FixedSortNotifier(MarketplaceSort.priceDesc),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(
        filteredMarketplaceListingsProvider(listings),
      );

      expect(result.first.price, 1000);
      expect(result.last.price, 200);
    });

    test('filters by title search query', () {
      final container = ProviderContainer(
        overrides: [
          marketplaceSearchQueryProvider.overrideWith(
            () => _FixedSearchNotifier('blue'),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(
        filteredMarketplaceListingsProvider(listings),
      );

      expect(result, hasLength(1));
      expect(result.first.id, 'l1');
    });

    test('filters by description search query', () {
      final container = ProviderContainer(
        overrides: [
          marketplaceSearchQueryProvider.overrideWith(
            () => _FixedSearchNotifier('singing'),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(
        filteredMarketplaceListingsProvider(listings),
      );

      expect(result, hasLength(1));
      expect(result.first.id, 'l3');
    });

    test('filters by species search query', () {
      final container = ProviderContainer(
        overrides: [
          marketplaceSearchQueryProvider.overrideWith(
            () => _FixedSearchNotifier('canary'),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(
        filteredMarketplaceListingsProvider(listings),
      );

      expect(result, hasLength(1));
      expect(result.first.id, 'l3');
    });

    test('filters by city search query', () {
      final container = ProviderContainer(
        overrides: [
          marketplaceSearchQueryProvider.overrideWith(
            () => _FixedSearchNotifier('ankara'),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(
        filteredMarketplaceListingsProvider(listings),
      );

      expect(result, hasLength(1));
      expect(result.first.id, 'l2');
    });

    test('filters by mutation search query', () {
      final container = ProviderContainer(
        overrides: [
          marketplaceSearchQueryProvider.overrideWith(
            () => _FixedSearchNotifier('opaline'),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(
        filteredMarketplaceListingsProvider(listings),
      );

      expect(result, hasLength(1));
      expect(result.first.id, 'l1');
    });

    test('search is case-insensitive', () {
      final container = ProviderContainer(
        overrides: [
          marketplaceSearchQueryProvider.overrideWith(
            () => _FixedSearchNotifier('BLUE'),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(
        filteredMarketplaceListingsProvider(listings),
      );

      expect(result, hasLength(1));
      expect(result.first.id, 'l1');
    });

    test('search trims whitespace', () {
      final container = ProviderContainer(
        overrides: [
          marketplaceSearchQueryProvider.overrideWith(
            () => _FixedSearchNotifier('  blue  '),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(
        filteredMarketplaceListingsProvider(listings),
      );

      expect(result, hasLength(1));
      expect(result.first.id, 'l1');
    });

    test('returns empty when search matches nothing', () {
      final container = ProviderContainer(
        overrides: [
          marketplaceSearchQueryProvider.overrideWith(
            () => _FixedSearchNotifier('nonexistent'),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(
        filteredMarketplaceListingsProvider(listings),
      );

      expect(result, isEmpty);
    });

    test('handles listings with null mutation in search', () {
      final listingsWithNullMutation = [
        _makeListing(id: 'l1', mutation: null),
        _makeListing(id: 'l2', mutation: 'Opaline'),
      ];

      final container = ProviderContainer(
        overrides: [
          marketplaceSearchQueryProvider.overrideWith(
            () => _FixedSearchNotifier('opaline'),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(
        filteredMarketplaceListingsProvider(listingsWithNullMutation),
      );

      expect(result, hasLength(1));
      expect(result.first.id, 'l2');
    });

    test('handles listings with null price in sort', () {
      final listingsWithNullPrice = [
        _makeListing(id: 'l1', price: null),
        _makeListing(id: 'l2', price: 300),
        _makeListing(id: 'l3', price: null),
      ];

      final container = ProviderContainer(
        overrides: [
          marketplaceSortProvider.overrideWith(
            () => _FixedSortNotifier(MarketplaceSort.priceAsc),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(
        filteredMarketplaceListingsProvider(listingsWithNullPrice),
      );

      // null prices treated as 0, so they come first in ascending
      expect(result, hasLength(3));
      expect(result.last.price, 300);
    });

    test('handles listings with null createdAt in newest sort', () {
      final listingsWithNullDate = [
        _makeListing(id: 'l1', createdAt: null),
        _makeListing(id: 'l2', createdAt: DateTime(2024, 7, 1)),
      ];

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = container.read(
        filteredMarketplaceListingsProvider(listingsWithNullDate),
      );

      // Non-null date should come first in newest sort
      expect(result.first.id, 'l2');
    });

    test('applies both search and sort together', () {
      final container = ProviderContainer(
        overrides: [
          marketplaceSearchQueryProvider.overrideWith(
            () => _FixedSearchNotifier('budgie'),
          ),
          marketplaceSortProvider.overrideWith(
            () => _FixedSortNotifier(MarketplaceSort.priceAsc),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(
        filteredMarketplaceListingsProvider(listings),
      );

      // Only budgie listings (l1 and l2), sorted by price ascending
      expect(result, hasLength(2));
      expect(result.first.price, 200); // l2 cheaper
      expect(result.last.price, 500); // l1 more expensive
    });

    test('returns empty list when input is empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = container.read(
        filteredMarketplaceListingsProvider(<MarketplaceListing>[]),
      );

      expect(result, isEmpty);
    });
  });
}

// ── Test Notifier Helpers ──

class _FixedFilterNotifier extends MarketplaceFilterNotifier {
  final MarketplaceFilter _initial;
  _FixedFilterNotifier(this._initial);

  @override
  MarketplaceFilter build() => _initial;
}

class _FixedSortNotifier extends MarketplaceSortNotifier {
  final MarketplaceSort _initial;
  _FixedSortNotifier(this._initial);

  @override
  MarketplaceSort build() => _initial;
}

class _FixedSearchNotifier extends MarketplaceSearchQueryNotifier {
  final String _initial;
  _FixedSearchNotifier(this._initial);

  @override
  String build() => _initial;
}

class _FixedCityNotifier extends MarketplaceCityFilterNotifier {
  final String? _initial;
  _FixedCityNotifier(this._initial);

  @override
  String? build() => _initial;
}
