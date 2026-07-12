import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/remote/api/gamification_remote_source.dart';

import '../../../helpers/fake_supabase.dart';

void main() {
  late RoutingFakeClient client;
  late GamificationRemoteSource source;

  late FakeFilterBuilder<PostgrestList> userStreaksSelect;

  setUp(() {
    client = RoutingFakeClient();

    final userStreaks = client.addTable(SupabaseConstants.userStreaksTable);
    userStreaksSelect = userStreaks.selectBuilder;

    source = GamificationRemoteSource(client);
  });

  group('GamificationRemoteSource streak', () {
    test(
      'recordDailyCheckin calls record_daily_checkin RPC and maps result',
      () async {
        client.addRpc(SupabaseConstants.recordDailyCheckinRpc, {
          'current_streak': 3,
          'longest_streak': 3,
          'grace_consumed': false,
          'awarded_xp': 7,
          'milestone_unlocked': null,
        });

        final result = await source.recordDailyCheckin('Europe/Istanbul');

        expect(result.currentStreak, 3);
        expect(result.longestStreak, 3);
        expect(result.graceConsumed, isFalse);
        expect(result.awardedXp, 7);
        expect(result.milestoneUnlocked, isNull);
        expect(client.rpcCalls, hasLength(1));
        expect(
          client.rpcCalls.first.fn,
          SupabaseConstants.recordDailyCheckinRpc,
        );
        expect(client.rpcCalls.first.params, {
          'p_time_zone': 'Europe/Istanbul',
        });
      },
    );

    test('fetchStreak filters by user_id and maps to UserStreak', () async {
      userStreaksSelect.singleResult = {
        'user_id': 'user-1',
        'current_streak': 5,
        'longest_streak': 9,
        'last_check_in_date': '2026-07-12',
        'grace_used_this_month': 1,
        'grace_month': '2026-07-01',
      };

      final result = await source.fetchStreak('user-1');

      expect(result, isNotNull);
      expect(result!.currentStreak, 5);
      expect(result.longestStreak, 9);
      final eqKeys = userStreaksSelect.eqCalls
          .map((e) => '${e.key}:${e.value}')
          .toList();
      expect(eqKeys, contains('user_id:user-1'));
    });

    test('fetchStreak returns null when no row exists', () async {
      userStreaksSelect.singleResult = null;

      final result = await source.fetchStreak('user-1');

      expect(result, isNull);
    });
  });
}
