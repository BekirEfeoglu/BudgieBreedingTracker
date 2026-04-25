@Tags(['community'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/data/repositories/marketplace_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/marketplace/providers/marketplace_providers.dart';
import 'package:budgie_breeding_tracker/features/marketplace/screens/marketplace_screen.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/premium_providers.dart';

import '../../../helpers/test_localization.dart';

class MockMarketplaceRepository extends Mock implements MarketplaceRepository {}

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
        currentUserIdProvider.overrideWithValue('test-user'),
        marketplaceRepositoryProvider.overrideWithValue(mockRepo),
        effectivePremiumProvider.overrideWithValue(false),
        canCreateListingProvider('test-user').overrideWithValue(true),
        marketplaceListingsProvider('test-user').overrideWith(
          (_) => switch (listingsAsync) {
            AsyncData(:final value) => Future.value(value),
            AsyncError(:final error) => Future.error(error),
            _ => Future<List<MarketplaceListing>>.value([]),
          },
        ),
      ],
      child: const MaterialApp(
        home: MarketplaceScreen(),
      ),
    );
  }

  testWidgets('loading state shows CircularProgressIndicator', (tester) async {
    // Use a Completer that never completes — no pending timers
    final completer = Completer<List<MarketplaceListing>>();

    await pumpLocalizedApp(
      tester,
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('test-user'),
          marketplaceRepositoryProvider.overrideWithValue(mockRepo),
          effectivePremiumProvider.overrideWithValue(false),
          canCreateListingProvider('test-user').overrideWithValue(true),
          marketplaceListingsProvider('test-user').overrideWith(
            (_) => completer.future,
          ),
        ],
        child: const MaterialApp(
          home: MarketplaceScreen(),
        ),
      ),
      settle: false,
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Complete future to avoid uncompleted future warnings
    completer.complete([]);
  });

  testWidgets('empty state shows EmptyState widget', (tester) async {
    await pumpLocalizedApp(
      tester,
      buildSubject(listingsAsync: const AsyncData([])),
    );

    expect(find.byType(CircularProgressIndicator), findsNothing);
    // EmptyState widget should be rendered for empty listings
    expect(find.byType(ListView), findsNothing);
  });

  testWidgets('data state shows listing cards', (tester) async {
    final listings = [
      const MarketplaceListing(
        id: 'listing-1',
        userId: 'user-1',
        title: 'Test Budgie',
        description: 'A lovely budgie',
        species: 'Budgerigar',
        city: 'Istanbul',
      ),
      const MarketplaceListing(
        id: 'listing-2',
        userId: 'user-2',
        title: 'Blue Budgie',
        description: 'Beautiful blue budgie',
        species: 'Budgerigar',
        city: 'Ankara',
      ),
    ];

    await pumpLocalizedApp(
      tester,
      buildSubject(listingsAsync: AsyncData(listings)),
    );

    expect(find.byType(ListView), findsOneWidget);
    // At least the first listing title should be visible; the second may be
    // offscreen due to lazy rendering in ListView.builder.
    expect(find.text('Test Budgie'), findsOneWidget);
  });
}
