import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/gamification_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/gamification/xp_constants.dart';

void main() {
  group('XpConstants.getXpAmount', () {
    test('returns the configured XP for each known action', () {
      expect(XpConstants.getXpAmount(XpAction.dailyLogin), 5);
      expect(XpConstants.getXpAmount(XpAction.addBird), 10);
      expect(XpConstants.getXpAmount(XpAction.createBreeding), 15);
      expect(XpConstants.getXpAmount(XpAction.recordChick), 10);
      expect(XpConstants.getXpAmount(XpAction.addHealthRecord), 5);
      expect(XpConstants.getXpAmount(XpAction.completeProfile), 20);
      expect(XpConstants.getXpAmount(XpAction.sharePost), 5);
      expect(XpConstants.getXpAmount(XpAction.addComment), 3);
      expect(XpConstants.getXpAmount(XpAction.receiveLike), 1);
      expect(XpConstants.getXpAmount(XpAction.createListing), 10);
      expect(XpConstants.getXpAmount(XpAction.sendMessage), 2);
    });

    test('returns 0 for actions not in the xpValues map (unknown fallback)', () {
      // unlockBadge is awarded via badge engine, not direct XP table.
      // unknown is the deserialization fallback — must never grant XP.
      expect(XpConstants.getXpAmount(XpAction.unlockBadge), 0);
      expect(XpConstants.getXpAmount(XpAction.unknown), 0);
    });

    test('every gameplay XpAction (excluding unknown/unlockBadge) is mapped', () {
      // Catches regression where a new gameplay action is added to the enum
      // but its XP reward is forgotten in xpConstants.
      const excluded = {XpAction.unlockBadge, XpAction.unknown};
      for (final action in XpAction.values) {
        if (excluded.contains(action)) continue;
        expect(
          XpConstants.xpValues.containsKey(action),
          isTrue,
          reason: 'XpAction.$action is missing from xpValues map',
        );
        expect(
          XpConstants.getXpAmount(action),
          greaterThan(0),
          reason: 'XpAction.$action should award positive XP',
        );
      }
    });

    test('XP values are positive integers (no negative XP regressions)', () {
      for (final entry in XpConstants.xpValues.entries) {
        expect(
          entry.value,
          greaterThan(0),
          reason: '${entry.key} should award positive XP',
        );
      }
    });
  });

  group('XpConstants.getDailyLimit', () {
    test('returns the configured daily limit when defined', () {
      expect(XpConstants.getDailyLimit(XpAction.dailyLogin), 1);
      expect(XpConstants.getDailyLimit(XpAction.completeProfile), 1);
      expect(XpConstants.getDailyLimit(XpAction.sendMessage), 5);
    });

    test('returns null for actions without a daily limit', () {
      expect(XpConstants.getDailyLimit(XpAction.addBird), isNull);
      expect(XpConstants.getDailyLimit(XpAction.recordChick), isNull);
      expect(XpConstants.getDailyLimit(XpAction.addHealthRecord), isNull);
      expect(XpConstants.getDailyLimit(XpAction.sharePost), isNull);
      expect(XpConstants.getDailyLimit(XpAction.addComment), isNull);
      expect(XpConstants.getDailyLimit(XpAction.receiveLike), isNull);
      expect(XpConstants.getDailyLimit(XpAction.createListing), isNull);
      expect(XpConstants.getDailyLimit(XpAction.createBreeding), isNull);
    });

    test('daily limit values are positive when defined', () {
      for (final entry in XpConstants.dailyLimits.entries) {
        expect(
          entry.value,
          greaterThan(0),
          reason: '${entry.key} daily limit should be positive',
        );
      }
    });
  });
}
