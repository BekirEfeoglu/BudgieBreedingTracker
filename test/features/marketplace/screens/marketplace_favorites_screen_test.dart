@Tags(['community'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart' as app;
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/features/marketplace/providers/marketplace_providers.dart';
import 'package:budgie_breeding_tracker/features/marketplace/screens/marketplace_favorites_screen.dart';
import 'package:budgie_breeding_tracker/features/marketplace/widgets/marketplace_listing_card.dart';

import '../../../helpers/test_localization.dart';

const _testUserId = 'test-user-fav';

const _sampleListings = [
  MarketplaceListing(
    id: 'fav-1',
    userId: 'user-1',
    title: 'Favorite Budgie 1',
    description: 'A favorite budgie',
    species: 'Budgerigar',
    city: 'Istanbul',
    isFavoritedByMe: true,
  ),
  MarketplaceListing(
    id: 'fav-2',
    userId: 'user-2',
    title: 'Favorite Budgie 2',
    description: 'Another favorite',
    species: 'Budgerigar',
    city: 'Ankara',
    isFavoritedByMe: true,
  ),
];

Widget _buildSubject({
  required AsyncValue<List<MarketplaceListing>> listingsAsync,
}) {
  return ProviderScope(
    overrides: [
      currentUserIdProvider.overrideWithValue(_testUserId),
      marketplaceFavoritesProvider(_testUserId).overrideWith(
        (_) => switch (listingsAsync) {
          AsyncData(:final value) => Future.value(value),
          AsyncError(:final error) => Future.error(error),
          _ => Completer<List<MarketplaceListing>>().future,
        },
      ),
    ],
    child: const MaterialApp(
      home: MarketplaceFavoritesScreen(),
    ),
  );
}

void main() {
  group('MarketplaceFavoritesScreen', () {
    testWidgets('should_show_loading_indicator_when_data_is_loading',
        (tester) async {
      final completer = Completer<List<MarketplaceListing>>();

      await pumpLocalizedApp(
        tester,
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue(_testUserId),
            marketplaceFavoritesProvider(_testUserId).overrideWith(
              (_) => completer.future,
            ),
          ],
          child: const MaterialApp(
            home: MarketplaceFavoritesScreen(),
          ),
        ),
        settle: false,
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete([]);
    });

    testWidgets('should_show_error_state_when_fetch_fails', (tester) async {
      await pumpLocalizedApp(
        tester,
        _buildSubject(
          listingsAsync:
              AsyncError(Exception('Network error'), StackTrace.empty),
        ),
      );

      expect(find.byType(app.ErrorState), findsOneWidget);
    });

    testWidgets('should_show_empty_state_when_no_favorites', (tester) async {
      await pumpLocalizedApp(
        tester,
        _buildSubject(listingsAsync: const AsyncData([])),
      );

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('marketplace.no_favorites'), findsOneWidget);
    });

    testWidgets('should_show_listing_cards_when_favorites_exist',
        (tester) async {
      await pumpLocalizedApp(
        tester,
        _buildSubject(listingsAsync: const AsyncData(_sampleListings)),
      );

      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(MarketplaceListingCard), findsAtLeastNWidgets(1));
      expect(find.text('Favorite Budgie 1'), findsOneWidget);
    });

    testWidgets('should_show_favorites_title_in_app_bar', (tester) async {
      await pumpLocalizedApp(
        tester,
        _buildSubject(listingsAsync: const AsyncData([])),
      );

      expect(find.text('marketplace.favorites'), findsOneWidget);
    });
  });
}
