@Tags(['community'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart' as app;
import 'package:budgie_breeding_tracker/data/repositories/marketplace_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/marketplace/providers/marketplace_providers.dart';
import 'package:budgie_breeding_tracker/features/marketplace/screens/marketplace_my_listings_screen.dart';
import 'package:budgie_breeding_tracker/features/marketplace/widgets/marketplace_listing_card.dart';

import '../../../helpers/test_localization.dart';

class MockMarketplaceRepository extends Mock implements MarketplaceRepository {}

const _testUserId = 'test-user';

const _sampleListings = [
  MarketplaceListing(
    id: 'listing-1',
    userId: _testUserId,
    title: 'My Budgie Sale',
    description: 'A nice budgie',
    species: 'Budgerigar',
    city: 'Istanbul',
  ),
  MarketplaceListing(
    id: 'listing-2',
    userId: _testUserId,
    title: 'Another Budgie',
    description: 'Another nice budgie',
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
    required AsyncValue<List<MarketplaceListing>> listingsAsync,
  }) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue(_testUserId),
        marketplaceRepositoryProvider.overrideWithValue(mockRepo),
        myMarketplaceListingsProvider(_testUserId).overrideWith(
          (_) => switch (listingsAsync) {
            AsyncData(:final value) => Future.value(value),
            AsyncError(:final error) => Future.error(error),
            _ => Completer<List<MarketplaceListing>>().future,
          },
        ),
      ],
      child: const MaterialApp(
        home: MarketplaceMyListingsScreen(),
      ),
    );
  }

  group('MarketplaceMyListingsScreen', () {
    testWidgets('loading state shows CircularProgressIndicator',
        (tester) async {
      final completer = Completer<List<MarketplaceListing>>();

      await pumpLocalizedApp(
        tester,
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue(_testUserId),
            marketplaceRepositoryProvider.overrideWithValue(mockRepo),
            myMarketplaceListingsProvider(_testUserId).overrideWith(
              (_) => completer.future,
            ),
          ],
          child: const MaterialApp(
            home: MarketplaceMyListingsScreen(),
          ),
        ),
        settle: false,
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete([]);
    });

    testWidgets('error state shows ErrorState widget', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(
          listingsAsync:
              AsyncError(Exception('Network error'), StackTrace.empty),
        ),
      );

      expect(find.byType(app.ErrorState), findsOneWidget);
    });

    testWidgets('empty state shows EmptyState widget', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(listingsAsync: const AsyncData([])),
      );

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('marketplace.no_listings'), findsOneWidget);
    });

    testWidgets('data state shows listing cards', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(listingsAsync: const AsyncData(_sampleListings)),
      );

      expect(find.byType(ListView), findsOneWidget);
      // At least the first card must be visible; the second may be offscreen
      // due to lazy rendering in ListView.builder within the test viewport.
      expect(find.byType(MarketplaceListingCard), findsAtLeastNWidgets(1));
      expect(find.text('My Budgie Sale'), findsOneWidget);
    });

    testWidgets('app bar shows my listings title', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(listingsAsync: const AsyncData([])),
      );

      expect(find.text('marketplace.my_listings'), findsOneWidget);
    });
  });
}
