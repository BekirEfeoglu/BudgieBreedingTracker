@Tags(['gamification'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:budgie_breeding_tracker/data/models/user_streak_model.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/repositories/gamification_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/gamification/streak_providers.dart';

class _MockRepo extends Mock implements GamificationRepository {}

/// Exposes the container's [Ref] so `runDailyCheckin(Ref ref)` can be called
/// directly in tests — [ProviderContainer] itself does not implement [Ref].
final _refProvider = Provider<Ref>((ref) => ref);

void main() {
  // runDailyCheckin reads tz.local.name; the notification-service init that
  // normally seeds it in app startup does not run in this test harness.
  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  test('streakProvider returns repo streak', () async {
    final repo = _MockRepo();
    when(() => repo.getStreak(any())).thenAnswer(
      (_) async => const UserStreak(userId: 'u1', currentStreak: 6),
    );
    final container = ProviderContainer(
      overrides: [
        gamificationRepositoryProvider.overrideWithValue(repo),
        currentUserIdProvider.overrideWithValue('u1'),
      ],
    );
    addTearDown(container.dispose);

    final streak = await container.read(streakProvider.future);
    expect(streak?.currentStreak, 6);
  });

  test('streakProvider returns null for anonymous user without calling repo', () async {
    final repo = _MockRepo();
    final container = ProviderContainer(
      overrides: [
        gamificationRepositoryProvider.overrideWithValue(repo),
        currentUserIdProvider.overrideWithValue('anonymous'),
      ],
    );
    addTearDown(container.dispose);

    final streak = await container.read(streakProvider.future);
    expect(streak, isNull);
    verifyNever(() => repo.getStreak(any()));
  });

  test(
    'lastStreakCheckinProvider defaults to null and can be updated',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(lastStreakCheckinProvider), isNull);

      const result = StreakCheckinResult(currentStreak: 3, awardedXp: 5);
      container.read(lastStreakCheckinProvider.notifier).state = result;

      expect(container.read(lastStreakCheckinProvider), result);
    },
  );

  test(
    'runDailyCheckin sets lastStreakCheckinProvider when streak is positive',
    () async {
      final repo = _MockRepo();
      when(() => repo.recordDailyCheckin(any())).thenAnswer(
        (_) async => const StreakCheckinResult(currentStreak: 2, awardedXp: 5),
      );
      when(() => repo.getStreak(any())).thenAnswer(
        (_) async => const UserStreak(userId: 'u1', currentStreak: 2),
      );
      final container = ProviderContainer(
        overrides: [
          gamificationRepositoryProvider.overrideWithValue(repo),
          currentUserIdProvider.overrideWithValue('u1'),
        ],
      );
      addTearDown(container.dispose);

      await runDailyCheckin(container.read(_refProvider));

      final last = container.read(lastStreakCheckinProvider);
      expect(last?.currentStreak, 2);
    },
  );

  test(
    'runDailyCheckin does not set lastStreakCheckinProvider when '
    'awardedXp is 0 (same-day no-op)',
    () async {
      final repo = _MockRepo();
      // Same-day RPC no-op: currentStreak stays positive but no XP awarded.
      when(() => repo.recordDailyCheckin(any())).thenAnswer(
        (_) async => const StreakCheckinResult(currentStreak: 4, awardedXp: 0),
      );
      when(() => repo.getStreak(any())).thenAnswer(
        (_) async => const UserStreak(userId: 'u1', currentStreak: 4),
      );
      final container = ProviderContainer(
        overrides: [
          gamificationRepositoryProvider.overrideWithValue(repo),
          currentUserIdProvider.overrideWithValue('u1'),
        ],
      );
      addTearDown(container.dispose);

      await runDailyCheckin(container.read(_refProvider));

      expect(container.read(lastStreakCheckinProvider), isNull);
    },
  );

  test(
    'runDailyCheckin sets lastStreakCheckinProvider when awardedXp is '
    'positive (real check-in)',
    () async {
      final repo = _MockRepo();
      when(() => repo.recordDailyCheckin(any())).thenAnswer(
        (_) async => const StreakCheckinResult(currentStreak: 5, awardedXp: 10),
      );
      when(() => repo.getStreak(any())).thenAnswer(
        (_) async => const UserStreak(userId: 'u1', currentStreak: 5),
      );
      final container = ProviderContainer(
        overrides: [
          gamificationRepositoryProvider.overrideWithValue(repo),
          currentUserIdProvider.overrideWithValue('u1'),
        ],
      );
      addTearDown(container.dispose);

      await runDailyCheckin(container.read(_refProvider));

      final last = container.read(lastStreakCheckinProvider);
      expect(last?.awardedXp, 10);
    },
  );

  test(
    'runDailyCheckin does nothing for anonymous user',
    () async {
      final repo = _MockRepo();
      final container = ProviderContainer(
        overrides: [
          gamificationRepositoryProvider.overrideWithValue(repo),
          currentUserIdProvider.overrideWithValue('anonymous'),
        ],
      );
      addTearDown(container.dispose);

      await runDailyCheckin(container.read(_refProvider));

      expect(container.read(lastStreakCheckinProvider), isNull);
      verifyNever(() => repo.recordDailyCheckin(any()));
    },
  );
}
