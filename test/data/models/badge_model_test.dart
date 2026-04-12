@Tags(['community'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/data/models/badge_model.dart';
import 'package:budgie_breeding_tracker/core/enums/gamification_enums.dart';

void main() {
  group('Badge', () {
    test('toJson/fromJson round-trip', () {
      const badge = Badge(
        id: 'b1',
        key: 'first_bird',
        category: BadgeCategory.milestone,
        tier: BadgeTier.bronze,
        nameKey: 'badges.first_bird',
        descriptionKey: 'badges.first_bird_desc',
        iconPath: 'assets/icons/badges/first_bird.svg',
        xpReward: 20,
        requirement: 1,
        sortOrder: 1,
      );

      final json = badge.toJson();
      final restored = Badge.fromJson(json);

      expect(restored.id, badge.id);
      expect(restored.key, badge.key);
      expect(restored.category, badge.category);
      expect(restored.tier, badge.tier);
      expect(restored.nameKey, badge.nameKey);
      expect(restored.xpReward, badge.xpReward);
      expect(restored.requirement, badge.requirement);
    });

    test('deserializes unknown category to unknown', () {
      final json = {
        'id': 'b1',
        'key': 'test',
        'category': 'alien_category',
        'tier': 'bronze',
      };
      final badge = Badge.fromJson(json);
      expect(badge.category, BadgeCategory.unknown);
    });

    test('deserializes unknown tier to unknown', () {
      final json = {
        'id': 'b1',
        'key': 'test',
        'category': 'milestone',
        'tier': 'diamond',
      };
      final badge = Badge.fromJson(json);
      expect(badge.tier, BadgeTier.unknown);
    });

    test('default values are correct', () {
      const badge = Badge(id: 'b1', key: 'test');
      expect(badge.category, BadgeCategory.milestone);
      expect(badge.tier, BadgeTier.bronze);
      expect(badge.nameKey, '');
      expect(badge.xpReward, 0);
      expect(badge.requirement, 0);
      expect(badge.sortOrder, 0);
    });
  });
}
