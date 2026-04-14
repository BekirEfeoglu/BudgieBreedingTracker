import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/gamification_enums.dart';
import 'package:budgie_breeding_tracker/data/remote/api/gamification_remote_source.dart';
import 'package:budgie_breeding_tracker/domain/services/gamification/gamification_service.dart';
import 'package:budgie_breeding_tracker/domain/services/gamification/xp_constants.dart';

class MockGamificationRemoteSource extends Mock
    implements GamificationRemoteSource {}

void main() {
  late MockGamificationRemoteSource mockRemote;
  late GamificationService service;

  const userId = 'test-user-123';

  setUp(() {
    mockRemote = MockGamificationRemoteSource();
    service = GamificationService(mockRemote);
  });

  /// Sets up standard mocks for a recordAction call with no existing level.
  void setUpBasicRecordAction({
    int dailyCount = 0,
    Map<String, dynamic>? existingLevel,
    List<Map<String, dynamic>> badges = const [],
    List<Map<String, dynamic>> userBadges = const [],
  }) {
    when(() => mockRemote.fetchDailyActionCount(userId, any()))
        .thenAnswer((_) async => dailyCount);
    when(() => mockRemote.insertXpTransaction(any()))
        .thenAnswer((_) async {});
    when(() => mockRemote.fetchUserLevel(userId))
        .thenAnswer((_) async => existingLevel);
    when(() => mockRemote.upsertUserLevel(any())).thenAnswer((_) async {});
    when(() => mockRemote.updateProfileLevelInfo(
          userId,
          level: any(named: 'level'),
          title: any(named: 'title'),
        )).thenAnswer((_) async {});
    when(() => mockRemote.fetchBadges()).thenAnswer((_) async => badges);
    when(() => mockRemote.fetchUserBadges(userId))
        .thenAnswer((_) async => userBadges);
    when(() => mockRemote.upsertUserBadge(any())).thenAnswer((_) async {});
  }

  group('XpConstants', () {
    test('getXpAmount returns correct values for all defined actions', () {
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

    test('getXpAmount returns 0 for unknown actions', () {
      expect(XpConstants.getXpAmount(XpAction.unlockBadge), 0);
      expect(XpConstants.getXpAmount(XpAction.unknown), 0);
    });

    test('getDailyLimit returns correct limits for limited actions', () {
      expect(XpConstants.getDailyLimit(XpAction.dailyLogin), 1);
      expect(XpConstants.getDailyLimit(XpAction.completeProfile), 1);
      expect(XpConstants.getDailyLimit(XpAction.sendMessage), 5);
    });

    test('getDailyLimit returns null for unlimited actions', () {
      expect(XpConstants.getDailyLimit(XpAction.addBird), isNull);
      expect(XpConstants.getDailyLimit(XpAction.createBreeding), isNull);
      expect(XpConstants.getDailyLimit(XpAction.sharePost), isNull);
    });
  });

  group('GamificationService.recordAction', () {
    test('inserts XP transaction and updates level for addBird', () async {
      setUpBasicRecordAction();

      await service.recordAction(userId, XpAction.addBird);

      verify(() => mockRemote.insertXpTransaction(any(
            that: predicate<Map<String, dynamic>>(
              (m) => m['action'] == 'addBird' && m['amount'] == 10,
            ),
          ))).called(1);
      verify(() => mockRemote.upsertUserLevel(any())).called(1);
      verify(() => mockRemote.updateProfileLevelInfo(
            userId,
            level: any(named: 'level'),
            title: any(named: 'title'),
          )).called(1);
    });

    test('skips when XP amount is 0 (unlockBadge not in xpValues)',
        () async {
      // unlockBadge has no XP value in the map, so getXpAmount returns 0
      await service.recordAction(userId, XpAction.unlockBadge);

      verifyNever(() => mockRemote.insertXpTransaction(any()));
      verifyNever(() => mockRemote.upsertUserLevel(any()));
    });

    test('respects daily limit and skips when exceeded', () async {
      // dailyLogin has limit of 1
      when(() => mockRemote.fetchDailyActionCount(userId, 'dailyLogin'))
          .thenAnswer((_) async => 1);

      await service.recordAction(userId, XpAction.dailyLogin);

      verifyNever(() => mockRemote.insertXpTransaction(any()));
    });

    test('allows action when under daily limit', () async {
      setUpBasicRecordAction(dailyCount: 0);

      await service.recordAction(userId, XpAction.dailyLogin);

      verify(() => mockRemote.insertXpTransaction(any())).called(1);
    });

    test('passes referenceId when provided', () async {
      setUpBasicRecordAction();

      await service.recordAction(
        userId,
        XpAction.addBird,
        referenceId: 'bird-abc-123',
      );

      verify(() => mockRemote.insertXpTransaction(any(
            that: predicate<Map<String, dynamic>>(
              (m) => m['reference_id'] == 'bird-abc-123',
            ),
          ))).called(1);
    });

    test('does not include referenceId when not provided', () async {
      setUpBasicRecordAction();

      await service.recordAction(userId, XpAction.addBird);

      verify(() => mockRemote.insertXpTransaction(any(
            that: predicate<Map<String, dynamic>>(
              (m) => !m.containsKey('reference_id'),
            ),
          ))).called(1);
    });

    test('handles remote source error gracefully (no throw)', () async {
      when(() => mockRemote.fetchDailyActionCount(userId, any()))
          .thenThrow(Exception('network error'));

      // Should not throw — errors are caught and logged
      await service.recordAction(userId, XpAction.addBird);
    });
  });

  group('GamificationService level update', () {
    test('creates new level record when none exists', () async {
      setUpBasicRecordAction(existingLevel: null);

      await service.recordAction(userId, XpAction.addBird);

      verify(() => mockRemote.upsertUserLevel(any(
            that: predicate<Map<String, dynamic>>(
              (m) =>
                  m['user_id'] == userId &&
                  m['total_xp'] == 10 &&
                  m['level'] == 1,
            ),
          ))).called(1);
    });

    test('accumulates XP on existing level record', () async {
      setUpBasicRecordAction(existingLevel: {
        'id': 'level-id-1',
        'user_id': userId,
        'total_xp': 90,
        'level': 1,
      });

      await service.recordAction(userId, XpAction.addBird); // +10 XP

      // 90 + 10 = 100 XP -> level 2
      verify(() => mockRemote.upsertUserLevel(any(
            that: predicate<Map<String, dynamic>>(
              (m) =>
                  m['id'] == 'level-id-1' &&
                  m['total_xp'] == 100 &&
                  m['level'] == 2,
            ),
          ))).called(1);
    });

    test('syncs level and title to profile', () async {
      setUpBasicRecordAction(existingLevel: {
        'id': 'lvl-1',
        'total_xp': 0,
      });

      await service.recordAction(userId, XpAction.addBird);

      verify(() => mockRemote.updateProfileLevelInfo(
            userId,
            level: 1,
            title: 'gamification.title_beginner',
          )).called(1);
    });
  });

  group('GamificationService badge progress', () {
    test('increments progress for related badges on addBird', () async {
      setUpBasicRecordAction(
        badges: [
          {
            'id': 'badge-first-bird',
            'key': 'first_bird',
            'requirement': 1,
            'xp_reward': 0,
          },
          {
            'id': 'badge-bird-lover',
            'key': 'bird_lover_10',
            'requirement': 10,
            'xp_reward': 0,
          },
          {
            'id': 'badge-unrelated',
            'key': 'first_breeding',
            'requirement': 1,
            'xp_reward': 0,
          },
        ],
      );

      await service.recordAction(userId, XpAction.addBird);

      // Should update first_bird and bird_lover_10, NOT first_breeding
      verify(() => mockRemote.upsertUserBadge(any(
            that: predicate<Map<String, dynamic>>(
              (m) => m['badge_key'] == 'first_bird',
            ),
          ))).called(1);
      verify(() => mockRemote.upsertUserBadge(any(
            that: predicate<Map<String, dynamic>>(
              (m) => m['badge_key'] == 'bird_lover_10',
            ),
          ))).called(1);
      verifyNever(() => mockRemote.upsertUserBadge(any(
            that: predicate<Map<String, dynamic>>(
              (m) => m['badge_key'] == 'first_breeding',
            ),
          )));
    });

    test('unlocks badge when progress meets requirement', () async {
      setUpBasicRecordAction(
        badges: [
          {
            'id': 'badge-first-bird',
            'key': 'first_bird',
            'requirement': 1,
            'xp_reward': 50,
          },
        ],
      );

      await service.recordAction(userId, XpAction.addBird);

      // Badge should be unlocked (progress 1 >= requirement 1)
      verify(() => mockRemote.upsertUserBadge(any(
            that: predicate<Map<String, dynamic>>(
              (m) =>
                  m['badge_key'] == 'first_bird' &&
                  m['is_unlocked'] == true &&
                  m['unlocked_at'] != null,
            ),
          ))).called(1);

      // Bonus XP transaction for badge unlock
      verify(() => mockRemote.insertXpTransaction(any(
            that: predicate<Map<String, dynamic>>(
              (m) =>
                  m['action'] == 'unlockBadge' &&
                  m['amount'] == 50,
            ),
          ))).called(1);
    });

    test('does not award bonus XP if badge was already unlocked', () async {
      setUpBasicRecordAction(
        badges: [
          {
            'id': 'badge-first-bird',
            'key': 'first_bird',
            'requirement': 1,
            'xp_reward': 50,
          },
        ],
        userBadges: [
          {
            'id': 'ub-1',
            'badge_id': 'badge-first-bird',
            'badge_key': 'first_bird',
            'progress': 5,
            'is_unlocked': true,
          },
        ],
      );

      await service.recordAction(userId, XpAction.addBird);

      // Badge already unlocked — no bonus XP
      verifyNever(() => mockRemote.insertXpTransaction(any(
            that: predicate<Map<String, dynamic>>(
              (m) => m['action'] == 'unlockBadge',
            ),
          )));
    });

    test('does not process badges for actions with no related keys',
        () async {
      setUpBasicRecordAction(
        badges: [
          {'id': 'b-1', 'key': 'first_bird', 'requirement': 1, 'xp_reward': 0},
        ],
      );

      await service.recordAction(userId, XpAction.receiveLike);

      // receiveLike has no related badge keys
      verifyNever(() => mockRemote.upsertUserBadge(any()));
    });

    test('preserves existing badge ID on progress update', () async {
      setUpBasicRecordAction(
        badges: [
          {
            'id': 'badge-bird-lover',
            'key': 'bird_lover_10',
            'requirement': 10,
            'xp_reward': 0,
          },
        ],
        userBadges: [
          {
            'id': 'existing-ub-id',
            'badge_id': 'badge-bird-lover',
            'badge_key': 'bird_lover_10',
            'progress': 3,
            'is_unlocked': false,
          },
        ],
      );

      await service.recordAction(userId, XpAction.addBird);

      verify(() => mockRemote.upsertUserBadge(any(
            that: predicate<Map<String, dynamic>>(
              (m) =>
                  m['id'] == 'existing-ub-id' &&
                  m['progress'] == 4 &&
                  m['is_unlocked'] == false,
            ),
          ))).called(1);
    });
  });

  group('GamificationService.checkVerifiedBreeder', () {
    test('returns early when user level is below 5', () async {
      when(() => mockRemote.fetchUserLevel(userId))
          .thenAnswer((_) async => {'level': 3});

      await service.checkVerifiedBreeder(userId);

      // Should not check badges at all
      verifyNever(() => mockRemote.fetchUserBadges(userId));
    });

    test('checks entity counts and badges when level is 5 or above', () async {
      when(() => mockRemote.fetchUserLevel(userId))
          .thenAnswer((_) async => {'level': 5});
      when(() => mockRemote.fetchEntityCounts(userId)).thenAnswer(
        (_) async => {
          'birds': 5,
          'breeding_pairs': 2,
          'chicks': 3,
          'posts': 1,
        },
      );
      when(() => mockRemote.fetchUserBadges(userId))
          .thenAnswer((_) async => []);
      when(() => mockRemote.fetchBadges()).thenAnswer(
        (_) async => [
          {'id': 'badge-1', 'key': 'verified_breeder', 'xp_reward': 0},
        ],
      );
      when(() => mockRemote.upsertUserBadge(any())).thenAnswer((_) async {});
      when(() => mockRemote.updateProfileVerification(
            userId,
            isVerified: true,
            level: any(named: 'level'),
            title: any(named: 'title'),
          )).thenAnswer((_) async {});

      await service.checkVerifiedBreeder(userId);

      verify(() => mockRemote.fetchEntityCounts(userId)).called(1);
      verify(() => mockRemote.fetchUserBadges(userId)).called(1);
      verify(() => mockRemote.upsertUserBadge(any())).called(1);
    });

    test('skips verification when entity criteria not met', () async {
      when(() => mockRemote.fetchUserLevel(userId))
          .thenAnswer((_) async => {'level': 5});
      when(() => mockRemote.fetchEntityCounts(userId)).thenAnswer(
        (_) async => {
          'birds': 1, // Below minimum of 3
          'breeding_pairs': 0,
          'chicks': 0,
          'posts': 0,
        },
      );

      await service.checkVerifiedBreeder(userId);

      verify(() => mockRemote.fetchEntityCounts(userId)).called(1);
      verifyNever(() => mockRemote.fetchUserBadges(userId));
    });

    test('handles null user level gracefully', () async {
      when(() => mockRemote.fetchUserLevel(userId))
          .thenAnswer((_) async => null);

      // level defaults to 0, which is < 5, so early return
      await service.checkVerifiedBreeder(userId);

      verifyNever(() => mockRemote.fetchUserBadges(userId));
    });

    test('handles remote error gracefully (no throw)', () async {
      when(() => mockRemote.fetchUserLevel(userId))
          .thenThrow(Exception('network error'));

      await service.checkVerifiedBreeder(userId);
      // Should not throw
    });
  });

  group('GamificationService badge-action mapping', () {
    test('addBird maps to bird badges', () async {
      setUpBasicRecordAction(
        badges: [
          {'id': 'b1', 'key': 'first_bird', 'requirement': 100, 'xp_reward': 0},
          {'id': 'b2', 'key': 'bird_lover_10', 'requirement': 100, 'xp_reward': 0},
          {'id': 'b3', 'key': 'bird_paradise_50', 'requirement': 100, 'xp_reward': 0},
        ],
      );
      await service.recordAction(userId, XpAction.addBird);
      verify(() => mockRemote.upsertUserBadge(any())).called(3);
    });

    test('createBreeding maps to breeding badges', () async {
      setUpBasicRecordAction(
        badges: [
          {'id': 'b1', 'key': 'first_breeding', 'requirement': 100, 'xp_reward': 0},
          {'id': 'b2', 'key': 'breeder_10', 'requirement': 100, 'xp_reward': 0},
          {'id': 'b3', 'key': 'breeder_50', 'requirement': 100, 'xp_reward': 0},
        ],
      );
      await service.recordAction(userId, XpAction.createBreeding);
      verify(() => mockRemote.upsertUserBadge(any())).called(3);
    });

    test('recordChick maps to chick badges', () async {
      setUpBasicRecordAction(
        badges: [
          {'id': 'b1', 'key': 'first_chick', 'requirement': 100, 'xp_reward': 0},
          {'id': 'b2', 'key': 'chick_100', 'requirement': 100, 'xp_reward': 0},
        ],
      );
      await service.recordAction(userId, XpAction.recordChick);
      verify(() => mockRemote.upsertUserBadge(any())).called(2);
    });

    test('sharePost maps to social_butterfly_50', () async {
      setUpBasicRecordAction(
        badges: [
          {'id': 'b1', 'key': 'social_butterfly_50', 'requirement': 100, 'xp_reward': 0},
        ],
      );
      await service.recordAction(userId, XpAction.sharePost);
      verify(() => mockRemote.upsertUserBadge(any())).called(1);
    });

    test('addComment maps to commenter_100', () async {
      setUpBasicRecordAction(
        badges: [
          {'id': 'b1', 'key': 'commenter_100', 'requirement': 100, 'xp_reward': 0},
        ],
      );
      await service.recordAction(userId, XpAction.addComment);
      verify(() => mockRemote.upsertUserBadge(any())).called(1);
    });

    test('addHealthRecord maps to health_tracker_50', () async {
      setUpBasicRecordAction(
        badges: [
          {'id': 'b1', 'key': 'health_tracker_50', 'requirement': 100, 'xp_reward': 0},
        ],
      );
      await service.recordAction(userId, XpAction.addHealthRecord);
      verify(() => mockRemote.upsertUserBadge(any())).called(1);
    });
  });
}
