@Tags(['gamification'])
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/data/repositories/gamification_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/gamification/providers/gamification_providers.dart';

class MockGamificationRepository extends Mock
    implements GamificationRepository {}

void main() {
  late MockGamificationRepository mockRepo;

  setUp(() {
    mockRepo = MockGamificationRepository();
  });

  // ── Test Fixtures ──

  Badge createTestBadge({
    String id = 'badge-1',
    String key = 'first_bird',
    BadgeCategory category = BadgeCategory.breeding,
    BadgeTier tier = BadgeTier.bronze,
    int requirement = 10,
    int xpReward = 50,
  }) {
    return Badge(
      id: id,
      key: key,
      category: category,
      tier: tier,
      requirement: requirement,
      xpReward: xpReward,
    );
  }

  UserBadge createTestUserBadge({
    String id = 'ub-1',
    String userId = 'user-1',
    String badgeId = 'badge-1',
    int progress = 5,
    bool isUnlocked = false,
  }) {
    return UserBadge(
      id: id,
      userId: userId,
      badgeId: badgeId,
      progress: progress,
      isUnlocked: isUnlocked,
    );
  }

  UserLevel createTestUserLevel({
    String id = 'ul-1',
    String userId = 'user-1',
    int totalXp = 250,
    int level = 3,
    int currentLevelXp = 50,
    int nextLevelXp = 100,
    String title = 'Novice Breeder',
  }) {
    return UserLevel(
      id: id,
      userId: userId,
      totalXp: totalXp,
      level: level,
      currentLevelXp: currentLevelXp,
      nextLevelXp: nextLevelXp,
      title: title,
    );
  }

  XpTransaction createTestXpTransaction({
    String id = 'xp-1',
    String userId = 'user-1',
    XpAction action = XpAction.addBird,
    int amount = 10,
  }) {
    return XpTransaction(
      id: id,
      userId: userId,
      action: action,
      amount: amount,
    );
  }

  // ── badgesProvider ──

  group('badgesProvider', () {
    test('returns badge list on success', () async {
      final badges = [
        createTestBadge(id: 'b1', category: BadgeCategory.breeding),
        createTestBadge(id: 'b2', category: BadgeCategory.community),
      ];
      when(() => mockRepo.getBadges()).thenAnswer((_) async => badges);

      final container = ProviderContainer(overrides: [
        gamificationRepositoryProvider.overrideWithValue(mockRepo),
      ]);
      addTearDown(container.dispose);

      final result = await container.read(badgesProvider.future);
      expect(result, badges);
      expect(result.length, 2);
      verify(() => mockRepo.getBadges()).called(1);
    });

    test('returns empty list when no badges exist', () async {
      when(() => mockRepo.getBadges()).thenAnswer((_) async => []);

      final container = ProviderContainer(overrides: [
        gamificationRepositoryProvider.overrideWithValue(mockRepo),
      ]);
      addTearDown(container.dispose);

      final result = await container.read(badgesProvider.future);
      expect(result, isEmpty);
    });

    test('exposes error state on repository failure', () async {
      when(() => mockRepo.getBadges())
          .thenAnswer((_) async => throw Exception('Network error'));

      final container = ProviderContainer(overrides: [
        gamificationRepositoryProvider.overrideWithValue(mockRepo),
      ]);
      addTearDown(container.dispose);

      final sub = container.listen(badgesProvider, (_, __) {},
          fireImmediately: true);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final value = container.read(badgesProvider);
      expect(value.hasError, isTrue);
      expect(value.error, isA<Exception>());
      sub.close();
    });
  });

  // ── userBadgesProvider ──

  group('userBadgesProvider', () {
    test('returns user badges for given userId', () async {
      final userBadges = [
        createTestUserBadge(id: 'ub-1', badgeId: 'b1', progress: 5),
        createTestUserBadge(
          id: 'ub-2',
          badgeId: 'b2',
          progress: 10,
          isUnlocked: true,
        ),
      ];
      when(() => mockRepo.getUserBadges('user-1'))
          .thenAnswer((_) async => userBadges);

      final container = ProviderContainer(overrides: [
        gamificationRepositoryProvider.overrideWithValue(mockRepo),
      ]);
      addTearDown(container.dispose);

      final result =
          await container.read(userBadgesProvider('user-1').future);
      expect(result, userBadges);
      expect(result.length, 2);
      verify(() => mockRepo.getUserBadges('user-1')).called(1);
    });

    test('returns empty list when user has no badges', () async {
      when(() => mockRepo.getUserBadges('user-1'))
          .thenAnswer((_) async => []);

      final container = ProviderContainer(overrides: [
        gamificationRepositoryProvider.overrideWithValue(mockRepo),
      ]);
      addTearDown(container.dispose);

      final result =
          await container.read(userBadgesProvider('user-1').future);
      expect(result, isEmpty);
    });

    test('exposes error state on repository failure', () async {
      when(() => mockRepo.getUserBadges('user-1'))
          .thenAnswer((_) async => throw Exception('Fetch failed'));

      final container = ProviderContainer(overrides: [
        gamificationRepositoryProvider.overrideWithValue(mockRepo),
      ]);
      addTearDown(container.dispose);

      final sub = container.listen(
          userBadgesProvider('user-1'), (_, __) {},
          fireImmediately: true);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final value = container.read(userBadgesProvider('user-1'));
      expect(value.hasError, isTrue);
      expect(value.error, isA<Exception>());
      sub.close();
    });
  });

  // ── userLevelProvider ──

  group('userLevelProvider', () {
    test('returns user level on success', () async {
      final level = createTestUserLevel(level: 5, totalXp: 500);
      when(() => mockRepo.getUserLevel('user-1'))
          .thenAnswer((_) async => level);

      final container = ProviderContainer(overrides: [
        gamificationRepositoryProvider.overrideWithValue(mockRepo),
      ]);
      addTearDown(container.dispose);

      final result =
          await container.read(userLevelProvider('user-1').future);
      expect(result, level);
      expect(result!.level, 5);
      expect(result.totalXp, 500);
    });

    test('returns null when user has no level', () async {
      when(() => mockRepo.getUserLevel('user-1'))
          .thenAnswer((_) async => null);

      final container = ProviderContainer(overrides: [
        gamificationRepositoryProvider.overrideWithValue(mockRepo),
      ]);
      addTearDown(container.dispose);

      final result =
          await container.read(userLevelProvider('user-1').future);
      expect(result, isNull);
    });

    test('exposes error state on repository failure', () async {
      when(() => mockRepo.getUserLevel('user-1'))
          .thenAnswer((_) async => throw Exception('Server error'));

      final container = ProviderContainer(overrides: [
        gamificationRepositoryProvider.overrideWithValue(mockRepo),
      ]);
      addTearDown(container.dispose);

      final sub = container.listen(
          userLevelProvider('user-1'), (_, __) {},
          fireImmediately: true);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final value = container.read(userLevelProvider('user-1'));
      expect(value.hasError, isTrue);
      expect(value.error, isA<Exception>());
      sub.close();
    });
  });

  // ── xpHistoryProvider ──

  group('xpHistoryProvider', () {
    test('returns XP transaction history', () async {
      final transactions = [
        createTestXpTransaction(id: 'xp-1', action: XpAction.addBird),
        createTestXpTransaction(
          id: 'xp-2',
          action: XpAction.createBreeding,
          amount: 25,
        ),
        createTestXpTransaction(
          id: 'xp-3',
          action: XpAction.dailyLogin,
          amount: 5,
        ),
      ];
      when(() => mockRepo.getXpHistory('user-1'))
          .thenAnswer((_) async => transactions);

      final container = ProviderContainer(overrides: [
        gamificationRepositoryProvider.overrideWithValue(mockRepo),
      ]);
      addTearDown(container.dispose);

      final result =
          await container.read(xpHistoryProvider('user-1').future);
      expect(result.length, 3);
      expect(result.first.action, XpAction.addBird);
    });

    test('returns empty list when no XP history', () async {
      when(() => mockRepo.getXpHistory('user-1'))
          .thenAnswer((_) async => []);

      final container = ProviderContainer(overrides: [
        gamificationRepositoryProvider.overrideWithValue(mockRepo),
      ]);
      addTearDown(container.dispose);

      final result =
          await container.read(xpHistoryProvider('user-1').future);
      expect(result, isEmpty);
    });

    test('exposes error state on repository failure', () async {
      when(() => mockRepo.getXpHistory('user-1'))
          .thenAnswer((_) async => throw Exception('Timeout'));

      final container = ProviderContainer(overrides: [
        gamificationRepositoryProvider.overrideWithValue(mockRepo),
      ]);
      addTearDown(container.dispose);

      final sub = container.listen(
          xpHistoryProvider('user-1'), (_, __) {},
          fireImmediately: true);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final value = container.read(xpHistoryProvider('user-1'));
      expect(value.hasError, isTrue);
      expect(value.error, isA<Exception>());
      sub.close();
    });
  });

  // ── leaderboardProvider ──

  group('leaderboardProvider', () {
    test('returns sorted leaderboard', () async {
      final leaderboard = [
        createTestUserLevel(
          id: 'ul-1',
          userId: 'top-user',
          totalXp: 1000,
          level: 10,
        ),
        createTestUserLevel(
          id: 'ul-2',
          userId: 'mid-user',
          totalXp: 500,
          level: 5,
        ),
        createTestUserLevel(
          id: 'ul-3',
          userId: 'new-user',
          totalXp: 50,
          level: 1,
        ),
      ];
      when(() => mockRepo.getLeaderboard()).thenAnswer(
        (_) async => leaderboard,
      );

      final container = ProviderContainer(overrides: [
        gamificationRepositoryProvider.overrideWithValue(mockRepo),
      ]);
      addTearDown(container.dispose);

      final result = await container.read(leaderboardProvider.future);
      expect(result.length, 3);
      expect(result.first.totalXp, 1000);
      expect(result.last.totalXp, 50);
    });

    test('returns empty list when no users on leaderboard', () async {
      when(() => mockRepo.getLeaderboard()).thenAnswer((_) async => []);

      final container = ProviderContainer(overrides: [
        gamificationRepositoryProvider.overrideWithValue(mockRepo),
      ]);
      addTearDown(container.dispose);

      final result = await container.read(leaderboardProvider.future);
      expect(result, isEmpty);
    });

    test('exposes error state on repository failure', () async {
      when(() => mockRepo.getLeaderboard())
          .thenAnswer((_) async => throw Exception('Network error'));

      final container = ProviderContainer(overrides: [
        gamificationRepositoryProvider.overrideWithValue(mockRepo),
      ]);
      addTearDown(container.dispose);

      final sub = container.listen(leaderboardProvider, (_, __) {},
          fireImmediately: true);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final value = container.read(leaderboardProvider);
      expect(value.hasError, isTrue);
      expect(value.error, isA<Exception>());
      sub.close();
    });
  });

  // ── badgeCategoryFilterProvider ──

  group('badgeCategoryFilterProvider', () {
    test('defaults to all', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(badgeCategoryFilterProvider),
        BadgeCategoryFilter.all,
      );
    });

    test('can be updated to breeding', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(badgeCategoryFilterProvider.notifier).state =
          BadgeCategoryFilter.breeding;

      expect(
        container.read(badgeCategoryFilterProvider),
        BadgeCategoryFilter.breeding,
      );
    });

    test('can cycle through all filter values', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      for (final filter in BadgeCategoryFilter.values) {
        container.read(badgeCategoryFilterProvider.notifier).state = filter;
        expect(container.read(badgeCategoryFilterProvider), filter);
      }
    });
  });

  // ── filteredBadgesProvider ──

  group('filteredBadgesProvider', () {
    final breedingBadge = createTestBadge(
      id: 'b1',
      category: BadgeCategory.breeding,
    );
    final communityBadge = createTestBadge(
      id: 'b2',
      category: BadgeCategory.community,
    );
    final healthBadge = createTestBadge(
      id: 'b3',
      category: BadgeCategory.health,
    );

    test('returns all badges when filter is all', () {
      final allBadges = [breedingBadge, communityBadge, healthBadge];

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = container.read(filteredBadgesProvider(allBadges));
      expect(result, allBadges);
      expect(result.length, 3);
    });

    test('filters by breeding category', () {
      final allBadges = [breedingBadge, communityBadge, healthBadge];

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(badgeCategoryFilterProvider.notifier).state =
          BadgeCategoryFilter.breeding;

      final result = container.read(filteredBadgesProvider(allBadges));
      expect(result.length, 1);
      expect(result.first.category, BadgeCategory.breeding);
    });

    test('filters by community category', () {
      final allBadges = [breedingBadge, communityBadge, healthBadge];

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(badgeCategoryFilterProvider.notifier).state =
          BadgeCategoryFilter.community;

      final result = container.read(filteredBadgesProvider(allBadges));
      expect(result.length, 1);
      expect(result.first.category, BadgeCategory.community);
    });

    test('returns empty list when no badges match filter', () {
      final allBadges = [breedingBadge];

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(badgeCategoryFilterProvider.notifier).state =
          BadgeCategoryFilter.special;

      final result = container.read(filteredBadgesProvider(allBadges));
      expect(result, isEmpty);
    });

    test('returns empty list when input is empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(badgeCategoryFilterProvider.notifier).state =
          BadgeCategoryFilter.breeding;

      final result = container.read(filteredBadgesProvider([]));
      expect(result, isEmpty);
    });
  });

  // ── enrichedBadgesProvider ──

  group('enrichedBadgesProvider', () {
    test('enriches badges with matching user badges', () {
      final badges = [
        createTestBadge(id: 'b1', requirement: 10),
        createTestBadge(id: 'b2', requirement: 5),
      ];
      final userBadges = [
        createTestUserBadge(badgeId: 'b1', progress: 7),
      ];

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = container.read(
        enrichedBadgesProvider(
          (badges: badges, userBadges: userBadges),
        ),
      );

      expect(result.length, 2);

      // First badge has user progress
      expect(result[0].badge.id, 'b1');
      expect(result[0].userBadge, isNotNull);
      expect(result[0].progress, 7);
      expect(result[0].isUnlocked, false);
      expect(result[0].progressPercent, closeTo(0.7, 0.01));

      // Second badge has no user progress
      expect(result[1].badge.id, 'b2');
      expect(result[1].userBadge, isNull);
      expect(result[1].progress, 0);
      expect(result[1].isUnlocked, false);
      expect(result[1].progressPercent, 0);
    });

    test('handles unlocked badges', () {
      final badges = [
        createTestBadge(id: 'b1', requirement: 10),
      ];
      final userBadges = [
        createTestUserBadge(
          badgeId: 'b1',
          progress: 10,
          isUnlocked: true,
        ),
      ];

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = container.read(
        enrichedBadgesProvider(
          (badges: badges, userBadges: userBadges),
        ),
      );

      expect(result.length, 1);
      expect(result[0].isUnlocked, true);
      expect(result[0].progressPercent, closeTo(1.0, 0.01));
    });

    test('handles empty badges list', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = container.read(
        enrichedBadgesProvider(
          (badges: <Badge>[], userBadges: <UserBadge>[]),
        ),
      );

      expect(result, isEmpty);
    });

    test('handles empty user badges list', () {
      final badges = [
        createTestBadge(id: 'b1'),
        createTestBadge(id: 'b2'),
      ];

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = container.read(
        enrichedBadgesProvider(
          (badges: badges, userBadges: <UserBadge>[]),
        ),
      );

      expect(result.length, 2);
      expect(result.every((e) => e.userBadge == null), true);
      expect(result.every((e) => e.progress == 0), true);
    });

    test('preserves badge order from input', () {
      final badges = [
        createTestBadge(id: 'b3'),
        createTestBadge(id: 'b1'),
        createTestBadge(id: 'b2'),
      ];

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = container.read(
        enrichedBadgesProvider(
          (badges: badges, userBadges: <UserBadge>[]),
        ),
      );

      expect(result[0].badge.id, 'b3');
      expect(result[1].badge.id, 'b1');
      expect(result[2].badge.id, 'b2');
    });
  });

  // ── EnrichedBadge computed properties ──

  group('EnrichedBadge', () {
    test('progress returns 0 when no userBadge', () {
      final enriched = EnrichedBadge(badge: createTestBadge());
      expect(enriched.progress, 0);
    });

    test('isUnlocked returns false when no userBadge', () {
      final enriched = EnrichedBadge(badge: createTestBadge());
      expect(enriched.isUnlocked, false);
    });

    test('progressPercent returns 0 when no userBadge', () {
      final enriched = EnrichedBadge(
        badge: createTestBadge(requirement: 10),
      );
      expect(enriched.progressPercent, 0);
    });

    test('progressPercent calculates correctly with userBadge', () {
      final enriched = EnrichedBadge(
        badge: createTestBadge(requirement: 20),
        userBadge: createTestUserBadge(progress: 10),
      );
      expect(enriched.progressPercent, closeTo(0.5, 0.01));
    });

    test('progressPercent clamps to 1.0 when over requirement', () {
      final enriched = EnrichedBadge(
        badge: createTestBadge(requirement: 5),
        userBadge: createTestUserBadge(progress: 10),
      );
      expect(enriched.progressPercent, 1.0);
    });

    test('progressPercent returns 0 when requirement is 0', () {
      final enriched = EnrichedBadge(
        badge: createTestBadge(requirement: 0),
        userBadge: createTestUserBadge(progress: 5),
      );
      expect(enriched.progressPercent, 0);
    });
  });

  // ── BadgeCategoryFilter enum ──

  group('BadgeCategoryFilter', () {
    test('all values have a non-empty label', () {
      for (final filter in BadgeCategoryFilter.values) {
        // In test environment .tr() returns the key itself
        expect(filter.label, isNotEmpty);
      }
    });

    test('all filter has common.all label key', () {
      expect(
        BadgeCategoryFilter.all.label,
        'common.all',
      );
    });

    test('breeding filter has correct label key', () {
      expect(
        BadgeCategoryFilter.breeding.label,
        'badges.category_breeding',
      );
    });
  });
}
