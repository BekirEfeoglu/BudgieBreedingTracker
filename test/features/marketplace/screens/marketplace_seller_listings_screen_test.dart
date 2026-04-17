@Tags(['community'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart' as app;
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/repositories/marketplace_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/marketplace/providers/marketplace_providers.dart';
import 'package:budgie_breeding_tracker/features/marketplace/screens/marketplace_seller_listings_screen.dart';
import 'package:budgie_breeding_tracker/features/marketplace/widgets/marketplace_listing_card.dart';

import '../../../helpers/test_localization.dart';

class MockMarketplaceRepository extends Mock implements MarketplaceRepository {}

const _testUserId = 'current-user';
const _testSellerId = 'seller-123';

const _sampleListings = [
  MarketplaceListing(
    id: 'sel-1',
    userId: _testSellerId,
    title: 'Seller Budgie 1',
    description: 'From seller',
    species: 'Budgerigar',
    city: 'Istanbul',
  ),
  MarketplaceListing(
    id: 'sel-2',
    userId: _testSellerId,
    title: 'Seller Budgie 2',
    description: 'Another from seller',
    species: 'Budgerigar',
    city: 'Ankara',
  ),
];

void main() {
  late MockMarketplaceRepository mockRepo;

  setUp(() {
    mockRepo = MockMarketplaceRepository();
  });

  Widget buildSubject({
    List<MarketplaceListing> listings = const [],
  }) {
    when(() => mockRepo.getByUser(
          userId: _testSellerId,
          currentUserId: _testUserId,
        )).thenAnswer((_) async => listings);

    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue(_testUserId),
        marketplaceRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: const MaterialApp(
        home: MarketplaceSellerListingsScreen(sellerId: _testSellerId),
      ),
    );
  }

  Widget buildLoadingSubject(Completer<List<MarketplaceListing>> completer) {
    when(() => mockRepo.getByUser(
          userId: _testSellerId,
          currentUserId: _testUserId,
        )).thenAnswer((_) => completer.future);

    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue(_testUserId),
        marketplaceRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: const MaterialApp(
        home: MarketplaceSellerListingsScreen(sellerId: _testSellerId),
      ),
    );
  }

  Widget buildErrorSubject() {
    when(() => mockRepo.getByUser(
          userId: _testSellerId,
          currentUserId: _testUserId,
        )).thenThrow(Exception('Network error'));

    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue(_testUserId),
        marketplaceRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: const MaterialApp(
        home: MarketplaceSellerListingsScreen(sellerId: _testSellerId),
      ),
    );
  }

  group('MarketplaceSellerListingsScreen', () {
    testWidgets('should_show_loading_indicator_when_data_is_loading',
        (tester) async {
      final completer = Completer<List<MarketplaceListing>>();

      await pumpLocalizedApp(
        tester,
        buildLoadingSubject(completer),
        settle: false,
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete([]);
    });

    testWidgets('should_show_error_state_when_fetch_fails', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildErrorSubject(),
      );

      expect(find.byType(app.ErrorState), findsOneWidget);
    });

    testWidgets('should_show_empty_state_when_no_listings', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(listings: []),
      );

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('marketplace.no_listings'), findsOneWidget);
    });

    testWidgets('should_show_listing_cards_when_data_available',
        (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(listings: _sampleListings),
      );

      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(MarketplaceListingCard), findsAtLeastNWidgets(1));
      expect(find.text('Seller Budgie 1'), findsOneWidget);
    });

    testWidgets('should_show_seller_listings_title_in_app_bar',
        (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(listings: []),
      );

      expect(find.text('marketplace.seller_listings'), findsOneWidget);
    });
  });
}
