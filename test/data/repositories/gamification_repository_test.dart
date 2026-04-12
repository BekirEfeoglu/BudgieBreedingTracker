import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/gamification_enums.dart';
import 'package:budgie_breeding_tracker/data/models/badge_model.dart';
import 'package:budgie_breeding_tracker/data/models/user_badge_model.dart';
import 'package:budgie_breeding_tracker/data/models/user_level_model.dart';
import 'package:budgie_breeding_tracker/data/models/xp_transaction_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/gamification_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/gamification_repository.dart';
import 'package:budgie_breeding_tracker/domain/services/gamification/gamification_service.dart';

class MockGamificationRemoteSource extends Mock
    implements GamificationRemoteSource {}

class MockGamificationService extends Mock implements GamificationService {}

Map<String, dynamic> _makeBadgeRow({
  required String id,
  String key = 'first_bird',
  String category = 'milestone',
  String tier = 'bronze',
  String nameKey = 'badges.first_bird',
  String descriptionKey = 'badges.first_bird_desc',
  String iconPath = 'assets/icons/badges/first_bird.svg',
  int xpReward = 50,
  int requirement = 1,
  int sortOrder = 0,
}) =>
    {
      'id': id,
      'key': key,
      'category': category,
      'tier': tier,
      'name_key': nameKey,
      'description_key': descriptionKey,
      'icon_path': iconPath,
      'xp_reward': xpReward,
      'requirement': requirement,
      'sort_order': sortOrder,
    };

Map<String, dynamic> _makeUserBadgeRow({
  required String id,
  String userId = 'u1',
  String badgeId = 'badge-1',
  String badgeKey = 'first_bird',
  int progress = 1,
  bool isUnlocked = false,
  String? unlockedAt,
}) =>
    {
      'id': id,
      'user_id': userId,
      'badge_id': badgeId,
      'badge_key': badgeKey,
      'progress': progress,
      'is_unlocked': isUnlocked,
      if (unlockedAt != null) 'unlocked_at': unlockedAt,
      'created_at': '2026-04-01T10:00:00Z',
    };

Map<String, dynamic> _makeUserLevelRow({
  String id = 'level-1',
  String userId = 'u1',
  int totalXp = 250,
  int level = 3,
  int currentLevelXp = 50,
  int nextLevelXp = 200,
  String title = 'Acemi Yetistirici',
}) =>
    {
      'id': id,
      'user_id': userId,
      'total_xp': totalXp,
      'level': level,
      'current_level_xp': currentLevelXp,
      'next_level_xp': nextLevelXp,
      'title': title,
      'updated_at': '2026-04-01T10:00:00Z',
    };

Map<String, dynamic> _makeXpTransactionRow({
  required String id,
  String userId = 'u1',
  String action = 'addBird',
  int amount = 10,
  String? referenceId,
}) =>
    {
      'id': id,
      'user_id': userId,
      'action': action,
      'amount': amount,
      if (referenceId != null) 'reference_id': referenceId,
      'created_at': '2026-04-01T10:00:00Z',
    };

void main() {
  late MockGamificationRemoteSource mockRemoteSource;
  late GamificationRepository repository;

  setUp(() {
    mockRemoteSource = MockGamificationRemoteSource();
    repository = GamificationRepository(remoteSource: mockRemoteSource);
  });

  group('getBadges', () {
    test('returns parsed Badge list from remote source', () async {
      when(() => mockRemoteSource.fetchBadges()).thenAnswer(
        (_) async => [
          _makeBadgeRow(id: 'b1', key: 'first_bird'),
          _makeBadgeRow(
            id: 'b2',
            key: 'bird_lover_10',
            tier: 'silver',
            requirement: 10,
            sortOrder: 1,
          ),
        ],
      );

      final badges = await repository.getBadges();

      expect(badges, hasLength(2));
      expect(badges[0], isA<Badge>());
      expect(badges[0].id, 'b1');
      expect(badges[0].key, 'first_bird');
      expect(badges[0].tier, BadgeTier.bronze);
      expect(badges[0].xpReward, 50);
      expect(badges[1].id, 'b2');
      expect(badges[1].key, 'bird_lover_10');
      expect(badges[1].tier, BadgeTier.silver);
      expect(badges[1].requirement, 10);
      verify(() => mockRemoteSource.fetchBadges()).called(1);
    });

    test('returns empty list when no badges', () async {
      when(() => mockRemoteSource.fetchBadges())
          .thenAnswer((_) async => []);

      final badges = await repository.getBadges();

      expect(badges, isEmpty);
    });

    test('rethrows exception from remote source', () async {
      when(() => mockRemoteSource.fetchBadges())
          .thenThrow(Exception('Network error'));

      expect(
        () => repository.getBadges(),
        throwsA(isA<Exception>()),
      );
    });

    test('parses unknown badge category to unknown', () async {
      final row = _makeBadgeRow(id: 'b1', category: 'nonexistent_category');
      when(() => mockRemoteSource.fetchBadges())
          .thenAnswer((_) async => [row]);

      final badges = await repository.getBadges();

      expect(badges[0].category, BadgeCategory.unknown);
    });

    test('parses unknown badge tier to unknown', () async {
      final row = _makeBadgeRow(id: 'b1', tier: 'diamond');
      when(() => mockRemoteSource.fetchBadges())
          .thenAnswer((_) async => [row]);

      final badges = await repository.getBadges();

      expect(badges[0].tier, BadgeTier.unknown);
    });
  });

  group('getUserBadges', () {
    test('returns parsed UserBadge list for a user', () async {
      when(() => mockRemoteSource.fetchUserBadges('u1')).thenAnswer(
        (_) async => [
          _makeUserBadgeRow(id: 'ub1', badgeKey: 'first_bird', isUnlocked: true),
          _makeUserBadgeRow(
            id: 'ub2',
            badgeKey: 'bird_lover_10',
            progress: 5,
          ),
        ],
      );

      final userBadges = await repository.getUserBadges('u1');

      expect(userBadges, hasLength(2));
      expect(userBadges[0], isA<UserBadge>());
      expect(userBadges[0].id, 'ub1');
      expect(userBadges[0].badgeKey, 'first_bird');
      expect(userBadges[0].isUnlocked, isTrue);
      expect(userBadges[1].progress, 5);
      expect(userBadges[1].isUnlocked, isFalse);
      verify(() => mockRemoteSource.fetchUserBadges('u1')).called(1);
    });

    test('returns empty list when user has no badges', () async {
      when(() => mockRemoteSource.fetchUserBadges('u1'))
          .thenAnswer((_) async => []);

      final userBadges = await repository.getUserBadges('u1');

      expect(userBadges, isEmpty);
    });

    test('rethrows exception from remote source', () async {
      when(() => mockRemoteSource.fetchUserBadges(any()))
          .thenThrow(Exception('Network error'));

      expect(
        () => repository.getUserBadges('u1'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('getUserLevel', () {
    test('returns parsed UserLevel when found', () async {
      when(() => mockRemoteSource.fetchUserLevel('u1')).thenAnswer(
        (_) async => _makeUserLevelRow(totalXp: 250, level: 3),
      );

      final level = await repository.getUserLevel('u1');

      expect(level, isNotNull);
      expect(level, isA<UserLevel>());
      expect(level!.userId, 'u1');
      expect(level.totalXp, 250);
      expect(level.level, 3);
      expect(level.title, 'Acemi Yetistirici');
      verify(() => mockRemoteSource.fetchUserLevel('u1')).called(1);
    });

    test('returns null when user has no level', () async {
      when(() => mockRemoteSource.fetchUserLevel('u1'))
          .thenAnswer((_) async => null);

      final level = await repository.getUserLevel('u1');

      expect(level, isNull);
    });

    test('rethrows exception from remote source', () async {
      when(() => mockRemoteSource.fetchUserLevel(any()))
          .thenThrow(Exception('Network error'));

      expect(
        () => repository.getUserLevel('u1'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('getXpHistory', () {
    test('returns parsed XpTransaction list with default limit', () async {
      when(() => mockRemoteSource.fetchXpTransactions('u1', limit: 50))
          .thenAnswer(
        (_) async => [
          _makeXpTransactionRow(id: 'xp1', action: 'addBird', amount: 10),
          _makeXpTransactionRow(
            id: 'xp2',
            action: 'createBreeding',
            amount: 25,
          ),
        ],
      );

      final history = await repository.getXpHistory('u1');

      expect(history, hasLength(2));
      expect(history[0], isA<XpTransaction>());
      expect(history[0].id, 'xp1');
      expect(history[0].action, XpAction.addBird);
      expect(history[0].amount, 10);
      expect(history[1].action, XpAction.createBreeding);
      expect(history[1].amount, 25);
      verify(
        () => mockRemoteSource.fetchXpTransactions('u1', limit: 50),
      ).called(1);
    });

    test('passes custom limit to remote source', () async {
      when(() => mockRemoteSource.fetchXpTransactions('u1', limit: 10))
          .thenAnswer((_) async => []);

      await repository.getXpHistory('u1', limit: 10);

      verify(
        () => mockRemoteSource.fetchXpTransactions('u1', limit: 10),
      ).called(1);
    });

    test('returns empty list when no transactions', () async {
      when(() => mockRemoteSource.fetchXpTransactions('u1', limit: 50))
          .thenAnswer((_) async => []);

      final history = await repository.getXpHistory('u1');

      expect(history, isEmpty);
    });

    test('parses unknown action to XpAction.unknown', () async {
      final row = _makeXpTransactionRow(
        id: 'xp1',
        action: 'nonexistent_action',
      );
      when(() => mockRemoteSource.fetchXpTransactions('u1', limit: 50))
          .thenAnswer((_) async => [row]);

      final history = await repository.getXpHistory('u1');

      expect(history[0].action, XpAction.unknown);
    });

    test('rethrows exception from remote source', () async {
      when(() => mockRemoteSource.fetchXpTransactions(any(), limit: any(named: 'limit')))
          .thenThrow(Exception('Network error'));

      expect(
        () => repository.getXpHistory('u1'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('getLeaderboard', () {
    test('returns sorted UserLevel list with default limit', () async {
      when(() => mockRemoteSource.fetchLeaderboard(limit: 100)).thenAnswer(
        (_) async => [
          _makeUserLevelRow(
            id: 'l1',
            userId: 'u1',
            totalXp: 1000,
            level: 5,
          ),
          _makeUserLevelRow(
            id: 'l2',
            userId: 'u2',
            totalXp: 500,
            level: 3,
          ),
        ],
      );

      final leaderboard = await repository.getLeaderboard();

      expect(leaderboard, hasLength(2));
      expect(leaderboard[0], isA<UserLevel>());
      expect(leaderboard[0].userId, 'u1');
      expect(leaderboard[0].totalXp, 1000);
      expect(leaderboard[1].userId, 'u2');
      expect(leaderboard[1].totalXp, 500);
      verify(() => mockRemoteSource.fetchLeaderboard(limit: 100)).called(1);
    });

    test('passes custom limit to remote source', () async {
      when(() => mockRemoteSource.fetchLeaderboard(limit: 10))
          .thenAnswer((_) async => []);

      await repository.getLeaderboard(limit: 10);

      verify(() => mockRemoteSource.fetchLeaderboard(limit: 10)).called(1);
    });

    test('returns empty list when no users on leaderboard', () async {
      when(() => mockRemoteSource.fetchLeaderboard(limit: 100))
          .thenAnswer((_) async => []);

      final leaderboard = await repository.getLeaderboard();

      expect(leaderboard, isEmpty);
    });

    test('rethrows exception from remote source', () async {
      when(() => mockRemoteSource.fetchLeaderboard(limit: any(named: 'limit')))
          .thenThrow(Exception('Network error'));

      expect(
        () => repository.getLeaderboard(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('recordAction', () {
    test('delegates to gamification service', () async {
      // recordAction delegates to GamificationService which uses the remote source.
      // Since GamificationService is created internally with the real remote source,
      // we need to stub the remote source methods that the service calls.
      when(() => mockRemoteSource.fetchDailyActionCount(any(), any()))
          .thenAnswer((_) async => 0);
      when(() => mockRemoteSource.insertXpTransaction(any()))
          .thenAnswer((_) async {});
      when(() => mockRemoteSource.fetchUserLevel(any()))
          .thenAnswer((_) async => _makeUserLevelRow());
      when(() => mockRemoteSource.upsertUserLevel(any()))
          .thenAnswer((_) async {});
      when(() => mockRemoteSource.updateProfileLevelInfo(
            any(),
            level: any(named: 'level'),
            title: any(named: 'title'),
          )).thenAnswer((_) async {});
      when(() => mockRemoteSource.fetchBadges())
          .thenAnswer((_) async => []);
      when(() => mockRemoteSource.fetchUserBadges(any()))
          .thenAnswer((_) async => []);

      await repository.recordAction('u1', XpAction.addBird);

      verify(() => mockRemoteSource.insertXpTransaction(any())).called(1);
    });

    test('passes referenceId to service', () async {
      when(() => mockRemoteSource.fetchDailyActionCount(any(), any()))
          .thenAnswer((_) async => 0);
      when(() => mockRemoteSource.insertXpTransaction(any()))
          .thenAnswer((_) async {});
      when(() => mockRemoteSource.fetchUserLevel(any()))
          .thenAnswer((_) async => _makeUserLevelRow());
      when(() => mockRemoteSource.upsertUserLevel(any()))
          .thenAnswer((_) async {});
      when(() => mockRemoteSource.updateProfileLevelInfo(
            any(),
            level: any(named: 'level'),
            title: any(named: 'title'),
          )).thenAnswer((_) async {});
      when(() => mockRemoteSource.fetchBadges())
          .thenAnswer((_) async => []);
      when(() => mockRemoteSource.fetchUserBadges(any()))
          .thenAnswer((_) async => []);

      await repository.recordAction(
        'u1',
        XpAction.addBird,
        referenceId: 'bird-123',
      );

      final captured = verify(
        () => mockRemoteSource.insertXpTransaction(captureAny()),
      ).captured;
      final txData = captured.first as Map<String, dynamic>;
      expect(txData['reference_id'], 'bird-123');
      expect(txData['action'], 'addBird');
    });

    test('does not throw on service error (swallowed by service)', () async {
      // GamificationService catches all errors internally
      when(() => mockRemoteSource.fetchDailyActionCount(any(), any()))
          .thenThrow(Exception('Network error'));

      // Should not throw — service catches internally
      await repository.recordAction('u1', XpAction.addBird);
    });
  });

  group('checkVerifiedBreeder', () {
    test('delegates to gamification service', () async {
      when(() => mockRemoteSource.fetchUserLevel('u1')).thenAnswer(
        (_) async => _makeUserLevelRow(level: 5),
      );
      when(() => mockRemoteSource.fetchUserBadges('u1'))
          .thenAnswer((_) async => []);

      await repository.checkVerifiedBreeder('u1');

      verify(() => mockRemoteSource.fetchUserLevel('u1')).called(1);
    });

    test('does not throw on service error (swallowed by service)', () async {
      when(() => mockRemoteSource.fetchUserLevel(any()))
          .thenThrow(Exception('Network error'));

      // Should not throw — service catches internally
      await repository.checkVerifiedBreeder('u1');
    });
  });
}
