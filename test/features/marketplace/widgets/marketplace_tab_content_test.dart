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
import 'package:budgie_breeding_tracker/features/marketplace/widgets/marketplace_filter_bar.dart';
import 'package:budgie_breeding_tracker/features/marketplace/widgets/marketplace_listing_card.dart';
import 'package:budgie_breeding_tracker/features/marketplace/widgets/marketplace_tab_content.dart';

import '../../../helpers/test_localization.dart';

class MockMarketplaceRepository extends Mock implements MarketplaceRepository {}

const _testUserId = 'test-user';

const _sampleListings = [
  MarketplaceListing(
    id: 'listing-1',
    userId: 'user-1',
    title: 'Test Budgie',
    description: 'A lovely budgie',
    species: 'Budgerigar',
    city: 'Istanbul',
  ),
  MarketplaceListing(
    id: 'listing-2',
    userId: 'user-2',
    title: 'Blue Budgie',
    description: 'Beautiful blue budgie',
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
    List<MarketplaceListing>? filteredListings,
  }) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue(_testUserId),
        marketplaceRepositoryProvider.overrideWithValue(mockRepo),
        marketplaceListingsProvider(_testUserId).overrideWith(
          (_) => switch (listingsAsync) {
            AsyncData(:final value) => Future.value(value),
            AsyncError(:final error) => Future.error(error),
            _ => Completer<List<MarketplaceListing>>().future,
          },
        ),
        if (filteredListings != null)
          filteredMarketplaceListingsProvider(
            (listingsAsync as AsyncData<List<MarketplaceListing>>).value,
          ).overrideWithValue(filteredListings),
      ],
      child: const MaterialApp(
        home: Scaffold(body: MarketplaceTabContent()),
      ),
    );
  }

  group('MarketplaceTabContent', () {
    testWidgets('loading state shows CircularProgressIndicator',
        (tester) async {
      final completer = Completer<List<MarketplaceListing>>();

      await pumpLocalizedApp(
        tester,
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue(_testUserId),
            marketplaceRepositoryProvider.overrideWithValue(mockRepo),
            marketplaceListingsProvider(_testUserId).overrideWith(
              (_) => completer.future,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: MarketplaceTabContent()),
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

    testWidgets('empty data shows EmptyState with action button',
        (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(listingsAsync: const AsyncData([])),
      );

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('marketplace.no_listings'), findsOneWidget);
      expect(find.text('marketplace.add_listing'), findsOneWidget);
    });

    testWidgets('no search results shows EmptyState without action',
        (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(
          listingsAsync: const AsyncData(_sampleListings),
          filteredListings: const [],
        ),
      );

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('common.no_results'), findsOneWidget);
      // Should not have action button for "no results" state
      expect(find.text('marketplace.add_listing'), findsNothing);
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
      expect(find.text('Test Budgie'), findsOneWidget);
    });

    testWidgets('renders filter bar', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(listingsAsync: const AsyncData(_sampleListings)),
      );

      expect(find.byType(MarketplaceFilterBar), findsOneWidget);
    });

    testWidgets('renders my listings button', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(listingsAsync: const AsyncData(_sampleListings)),
      );

      expect(find.byTooltip('marketplace.my_listings'), findsOneWidget);
    });
  });
}
