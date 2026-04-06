import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/remote/api/gamification_remote_source.dart';

import '../../../helpers/fake_supabase.dart';

void main() {
  late RoutingFakeClient client;
  late GamificationRemoteSource source;

  late FakeFilterBuilder<PostgrestList> badgesSelect;
  late FakeFilterBuilder<PostgrestList> userBadgesSelect;
  late FakeFilterBuilder<PostgrestList> userLevelsSelect;
  late FakeFilterBuilder<PostgrestList> xpSelect;
  late FakeFilterBuilder<PostgrestList> profilesSelect;

  late FakeQueryBuilder badgesQuery;
  late FakeQueryBuilder userBadgesQuery;
  late FakeQueryBuilder userLevelsQuery;
  late FakeQueryBuilder xpQuery;
  late FakeQueryBuilder profilesQuery;

  setUp(() {
    client = RoutingFakeClient();

    final badges = client.addTable(SupabaseConstants.badgesTable);
    badgesSelect = badges.selectBuilder;
    badgesQuery = badges.queryBuilder;

    final userBadges = client.addTable(SupabaseConstants.userBadgesTable);
    userBadgesSelect = userBadges.selectBuilder;
    userBadgesQuery = userBadges.queryBuilder;

    final userLevels = client.addTable(SupabaseConstants.userLevelsTable);
    userLevelsSelect = userLevels.selectBuilder;
    userLevelsQuery = userLevels.queryBuilder;

    final xp = client.addTable(SupabaseConstants.xpTransactionsTable);
    xpSelect = xp.selectBuilder;
    xpQuery = xp.queryBuilder;

    final profiles = client.addTable(SupabaseConstants.profilesTable);
    profilesSelect = profiles.selectBuilder;
    profilesQuery = profiles.queryBuilder;

    source = GamificationRemoteSource(client);
  });

  group('GamificationRemoteSource', () {
    test('fetchBadges queries badges table with order', () async {
      badgesSelect.result = [
        {'id': 'b1', 'name': 'First Egg', 'sort_order': 1},
      ];

      final result = await source.fetchBadges();

      expect(result, hasLength(1));
      expect(result.first['id'], 'b1');
      expect(badgesSelect.orderCalls, contains('sort_order'));
    });

    test('fetchUserBadges filters by user_id', () async {
      userBadgesSelect.result = [
        {'id': 'ub1', 'user_id': 'user-1', 'badge_id': 'b1'},
      ];

      final result = await source.fetchUserBadges('user-1');

      expect(result, hasLength(1));
      final eqKeys = userBadgesSelect.eqCalls
          .map((e) => '${e.key}:${e.value}')
          .toList();
      expect(eqKeys, contains('user_id:user-1'));
    });

    test('upsertUserBadge sends payload', () async {
      final data = {'user_id': 'user-1', 'badge_id': 'b1'};
      await source.upsertUserBadge(data);

      expect(userBadgesQuery.upsertPayload, data);
    });

    test('fetchUserLevel applies user_id filter and maybeSingle', () async {
      userLevelsSelect.singleResult = {
        'user_id': 'user-1',
        'level': 5,
        'total_xp': 500,
      };

      final result = await source.fetchUserLevel('user-1');

      expect(result, isNotNull);
      expect(result!['level'], 5);
      final eqKeys = userLevelsSelect.eqCalls
          .map((e) => '${e.key}:${e.value}')
          .toList();
      expect(eqKeys, contains('user_id:user-1'));
    });

    test('upsertUserLevel sends payload', () async {
      final data = {'user_id': 'user-1', 'level': 5};
      await source.upsertUserLevel(data);

      expect(userLevelsQuery.upsertPayload, data);
    });

    test('insertXpTransaction inserts data', () async {
      final data = {'user_id': 'user-1', 'action': 'addBird', 'amount': 10};
      await source.insertXpTransaction(data);

      expect(xpQuery.insertPayload, data);
    });

    test('fetchXpTransactions applies user filter, order and limit', () async {
      xpSelect.result = [
        {'id': 'xp1', 'user_id': 'user-1', 'amount': 10},
      ];

      final result = await source.fetchXpTransactions('user-1', limit: 25);

      expect(result, hasLength(1));
      final eqKeys = xpSelect.eqCalls.map((e) => '${e.key}:${e.value}').toList();
      expect(eqKeys, contains('user_id:user-1'));
      expect(xpSelect.orderCalls, contains('created_at'));
      expect(xpSelect.limitValue, 25);
    });

    test('fetchLeaderboard orders by total_xp desc with limit', () async {
      userLevelsSelect.result = [
        {'user_id': 'user-1', 'total_xp': 1000},
        {'user_id': 'user-2', 'total_xp': 800},
      ];

      final result = await source.fetchLeaderboard(limit: 50);

      expect(result, hasLength(2));
      expect(userLevelsSelect.orderCalls, contains('total_xp'));
      expect(userLevelsSelect.limitValue, 50);
    });

    test('fetchDailyActionCount filters by user, action and date', () async {
      xpSelect.result = [
        {'id': 'xp1'},
        {'id': 'xp2'},
      ];

      final count = await source.fetchDailyActionCount('user-1', 'addBird');

      expect(count, 2);
      final eqKeys = xpSelect.eqCalls.map((e) => '${e.key}:${e.value}').toList();
      expect(eqKeys, contains('user_id:user-1'));
      expect(eqKeys, contains('action:addBird'));
    });

    test('fetchDailyActionCount returns 0 on error', () async {
      xpSelect.error = Exception('failed');

      final count = await source.fetchDailyActionCount('user-1', 'addBird');

      expect(count, 0);
    });

    test('updateProfileVerification updates profile fields', () async {
      await source.updateProfileVerification(
        'user-1',
        isVerified: true,
        level: 10,
        title: 'Expert',
      );

      expect(profilesQuery.updatePayload, {
        'is_verified_breeder': true,
        'level': 10,
        'xp_title': 'Expert',
      });
    });

    test('updateProfileLevelInfo updates only level and title', () async {
      await source.updateProfileLevelInfo(
        'user-1',
        level: 5,
        title: 'Breeder',
      );

      expect(profilesQuery.updatePayload, {
        'level': 5,
        'xp_title': 'Breeder',
      });
    });
  });
}
