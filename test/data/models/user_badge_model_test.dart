import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/data/models/user_badge_model.dart';

void main() {
  group('UserBadge', () {
    test('progressPercent returns correct ratio', () {
      final badge = UserBadge(id: 'ub1', userId: 'u1', badgeId: 'b1', progress: 5);
      expect(badge.progressPercent(10), 0.5);
    });

    test('progressPercent clamps to 1.0', () {
      final badge = UserBadge(id: 'ub1', userId: 'u1', badgeId: 'b1', progress: 15);
      expect(badge.progressPercent(10), 1.0);
    });

    test('progressPercent returns 0 for zero requirement', () {
      final badge = UserBadge(id: 'ub1', userId: 'u1', badgeId: 'b1', progress: 5);
      expect(badge.progressPercent(0), 0);
    });

    test('default values are correct', () {
      final badge = UserBadge(id: 'ub1', userId: 'u1', badgeId: 'b1');
      expect(badge.progress, 0);
      expect(badge.isUnlocked, false);
      expect(badge.unlockedAt, isNull);
      expect(badge.badgeKey, '');
    });
  });
}
