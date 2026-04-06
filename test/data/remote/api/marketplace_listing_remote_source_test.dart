import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/remote/api/marketplace_listing_remote_source.dart';

import '../../../helpers/fake_supabase.dart';

void main() {
  late FakeFilterBuilder<PostgrestList> selectBuilder;
  late FakeQueryBuilder queryBuilder;
  late FakeSupabaseClient client;
  late MarketplaceListingRemoteSource source;

  setUp(() {
    final stack = createFakeSupabaseStack();
    selectBuilder = stack.selectBuilder;
    queryBuilder = stack.queryBuilder;
    client = stack.client;
    source = MarketplaceListingRemoteSource(client);
  });

  group('MarketplaceListingRemoteSource', () {
    test('fetchListings applies default filters and order', () async {
      selectBuilder.result = [
        {'id': 'l1', 'title': 'Blue Budgie', 'status': 'active'},
      ];

      final result = await source.fetchListings();

      expect(client.requestedTable, SupabaseConstants.marketplaceListingsTable);
      expect(result, hasLength(1));
      final eqKeys = selectBuilder.eqCalls
          .map((e) => '${e.key}:${e.value}')
          .toList();
      expect(eqKeys, containsAll(['is_deleted:false', 'status:active']));
      expect(selectBuilder.orderCalls, contains('created_at'));
      expect(selectBuilder.limitValue, 20);
    });

    test('fetchListings applies optional filters', () async {
      selectBuilder.result = [];

      await source.fetchListings(
        city: 'Istanbul',
        listingType: 'sale',
        gender: 'male',
        minPrice: 100,
        maxPrice: 500,
        limit: 10,
      );

      final eqKeys = selectBuilder.eqCalls
          .map((e) => '${e.key}:${e.value}')
          .toList();
      expect(eqKeys, containsAll([
        'city:Istanbul',
        'listing_type:sale',
        'gender:male',
      ]));
      final gteKeys = selectBuilder.gteCalls
          .map((e) => '${e.key}:${e.value}')
          .toList();
      expect(gteKeys, contains('price:100.0'));
      final lteKeys = selectBuilder.lteCalls
          .map((e) => '${e.key}:${e.value}')
          .toList();
      expect(lteKeys, contains('price:500.0'));
      expect(selectBuilder.limitValue, 10);
    });

    test('fetchById applies id filter with maybeSingle', () async {
      selectBuilder.singleResult = {'id': 'l1', 'title': 'Blue Budgie'};

      final result = await source.fetchById('l1');

      expect(result, isNotNull);
      expect(result!['id'], 'l1');
      final eqKeys = selectBuilder.eqCalls
          .map((e) => '${e.key}:${e.value}')
          .toList();
      expect(eqKeys, contains('id:l1'));
    });

    test('fetchByUser filters by user_id and is_deleted', () async {
      selectBuilder.result = [
        {'id': 'l1', 'user_id': 'user-1'},
      ];

      final result = await source.fetchByUser('user-1');

      expect(result, hasLength(1));
      final eqKeys = selectBuilder.eqCalls
          .map((e) => '${e.key}:${e.value}')
          .toList();
      expect(eqKeys, containsAll(['user_id:user-1', 'is_deleted:false']));
    });

    test('softDelete sets is_deleted to true', () async {
      await source.softDelete('l1');

      expect(queryBuilder.updatePayload, {'is_deleted': true});
      final eqKeys = queryBuilder.updateBuilder.eqCalls
          .map((e) => '${e.key}:${e.value}')
          .toList();
      expect(eqKeys, contains('id:l1'));
    });

    test('updateStatus sends correct payload', () async {
      await source.updateStatus('l1', 'sold');

      expect(queryBuilder.updatePayload, {'status': 'sold'});
    });

    test('search sanitizes input and applies or filter', () async {
      selectBuilder.result = [];

      await source.search('blue budgie', limit: 10);

      final eqKeys = selectBuilder.eqCalls
          .map((e) => '${e.key}:${e.value}')
          .toList();
      expect(eqKeys, containsAll(['is_deleted:false', 'status:active']));
      expect(selectBuilder.orCalls, isNotEmpty);
      expect(selectBuilder.limitValue, 10);
    });

    test('search returns empty list for empty sanitized query', () async {
      final result = await source.search('!!!');

      expect(result, isEmpty);
    });

    test('rethrows on fetch error', () {
      selectBuilder.error = Exception('network error');

      expect(
        () => source.fetchListings(),
        throwsA(isA<Exception>()),
      );
    });
  });
}
