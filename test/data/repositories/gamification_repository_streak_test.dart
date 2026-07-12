import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/data/models/user_streak_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/gamification_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/gamification_repository.dart';

class _MockRemote extends Mock implements GamificationRemoteSource {}

void main() {
  test('recordDailyCheckin delegates to remote source', () async {
    final remote = _MockRemote();
    when(() => remote.recordDailyCheckin('UTC')).thenAnswer(
      (_) async => const StreakCheckinResult(currentStreak: 2, awardedXp: 5),
    );
    final repo = GamificationRepository(remoteSource: remote);

    final r = await repo.recordDailyCheckin('UTC');

    expect(r.currentStreak, 2);
    expect(r.awardedXp, 5);
    verify(() => remote.recordDailyCheckin('UTC')).called(1);
  });

  test('getStreak delegates to remote source fetchStreak', () async {
    final remote = _MockRemote();
    when(() => remote.fetchStreak('user-1')).thenAnswer(
      (_) async => const UserStreak(userId: 'user-1', currentStreak: 4),
    );
    final repo = GamificationRepository(remoteSource: remote);

    final r = await repo.getStreak('user-1');

    expect(r, isNotNull);
    expect(r!.userId, 'user-1');
    expect(r.currentStreak, 4);
    verify(() => remote.fetchStreak('user-1')).called(1);
  });

  test('getStreak returns null when remote returns null', () async {
    final remote = _MockRemote();
    when(() => remote.fetchStreak('user-1')).thenAnswer((_) async => null);
    final repo = GamificationRepository(remoteSource: remote);

    final r = await repo.getStreak('user-1');

    expect(r, isNull);
  });
}
