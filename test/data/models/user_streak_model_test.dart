import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/data/models/user_streak_model.dart';

void main() {
  test('UserStreak parses snake_case json', () {
    final s = UserStreak.fromJson({
      'user_id': 'u1',
      'current_streak': 5,
      'longest_streak': 9,
      'last_check_in_date': '2026-07-12',
      'grace_used_this_month': 1,
      'grace_month': '2026-07-01',
    });
    expect(s.currentStreak, 5);
    expect(s.longestStreak, 9);
    expect(s.graceUsedThisMonth, 1);
  });

  test('StreakCheckinResult parses RPC jsonb', () {
    final r = StreakCheckinResult.fromJson({
      'current_streak': 8,
      'longest_streak': 8,
      'grace_consumed': true,
      'awarded_xp': 10,
      'milestone_unlocked': null,
    });
    expect(r.currentStreak, 8);
    expect(r.graceConsumed, true);
    expect(r.awardedXp, 10);
    expect(r.milestoneUnlocked, isNull);
  });
}
