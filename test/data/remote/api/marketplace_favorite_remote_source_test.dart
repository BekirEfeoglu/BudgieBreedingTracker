import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/remote/api/marketplace_favorite_remote_source.dart';

import '../../../helpers/fake_supabase.dart';

void main() {
  late FakeFilterBuilder<PostgrestList> selectBuilder;
  late FakeQueryBuilder queryBuilder;
  late FakeSupabaseClient client;
  late MarketplaceFavoriteRemoteSource source;

  setUp(() {
    final stack = createFakeSupabaseStack();
    selectBuilder = stack.selectBuilder;
    queryBuilder = stack.queryBuilder;
    client = stack.client;
    source = MarketplaceFavoriteRemoteSource(client);
  });

  group('MarketplaceFavoriteRemoteSource', () {
    test('fetchFavoritedListingIds filters by user_id', () async {
      selectBuilder.result = [
        {'listing_id': 'listing-1'},
        {'listing_id': 'listing-2'},
      ];

      final result = await source.fetchFavoritedListingIds('user-1');

      expect(client.requestedTable, SupabaseConstants.marketplaceFavoritesTable);
      expect(result, ['listing-1', 'listing-2']);
      final eqKeys = selectBuilder.eqCalls
          .map((e) => '${e.key}:${e.value}')
          .toList();
      expect(eqKeys, contains('user_id:user-1'));
    });

    test('fetchFavoritedListingIds returns empty list when none', () async {
      selectBuilder.result = [];

      final result = await source.fetchFavoritedListingIds('user-1');

      expect(result, isEmpty);
    });

    test('addFavorite inserts with user_id and listing_id', () async {
      await source.addFavorite('user-1', 'listing-1');

      expect(client.requestedTable, SupabaseConstants.marketplaceFavoritesTable);
      final payload = queryBuilder.upsertPayload as Map<String, dynamic>;
      expect(payload['user_id'], 'user-1');
      expect(payload['listing_id'], 'listing-1');
    });

    test('removeFavorite deletes matching record', () async {
      await source.removeFavorite('user-1', 'listing-1');

      expect(client.requestedTable, SupabaseConstants.marketplaceFavoritesTable);
      final eqKeys = queryBuilder.deleteBuilder.eqCalls
          .map((e) => '${e.key}:${e.value}')
          .toList();
      expect(eqKeys, containsAll(['user_id:user-1', 'listing_id:listing-1']));
    });

    test('rethrows on fetch error', () {
      selectBuilder.error = Exception('network error');

      expect(
        () => source.fetchFavoritedListingIds('user-1'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
