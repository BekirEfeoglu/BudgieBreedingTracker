import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/data/models/user_streak_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/gamification_repository.dart';
import 'package:budgie_breeding_tracker/domain/services/gamification/streak_service.dart';

class _MockRepo extends Mock implements GamificationRepository {}

void main() {
  test('checkIn returns null for anonymous user without calling repo', () async {
    final repo = _MockRepo();
    final service = StreakService(repo);
    final r = await service.checkIn('anonymous', 'UTC');
    expect(r, isNull);
    verifyNever(() => repo.recordDailyCheckin(any()));
  });

  test('checkIn delegates and returns result', () async {
    final repo = _MockRepo();
    when(() => repo.recordDailyCheckin('UTC')).thenAnswer(
      (_) async => const StreakCheckinResult(currentStreak: 4, awardedXp: 7),
    );
    final service = StreakService(repo);
    final r = await service.checkIn('u1', 'UTC');
    expect(r!.currentStreak, 4);
  });

  test('checkIn swallows errors and returns null', () async {
    final repo = _MockRepo();
    when(() => repo.recordDailyCheckin(any())).thenThrow(Exception('boom'));
    final service = StreakService(repo);
    expect(await service.checkIn('u1', 'UTC'), isNull);
  });

  test('getStreak returns null for anonymous user without calling repo', () async {
    final repo = _MockRepo();
    final service = StreakService(repo);
    final r = await service.getStreak('anonymous');
    expect(r, isNull);
    verifyNever(() => repo.getStreak(any()));
  });

  test('getStreak delegates and returns result', () async {
    final repo = _MockRepo();
    when(() => repo.getStreak('u1')).thenAnswer(
      (_) async => const UserStreak(userId: 'u1', currentStreak: 6),
    );
    final service = StreakService(repo);
    final r = await service.getStreak('u1');
    expect(r!.currentStreak, 6);
  });

  test('getStreak swallows errors and returns null', () async {
    final repo = _MockRepo();
    when(() => repo.getStreak(any())).thenThrow(Exception('boom'));
    final service = StreakService(repo);
    expect(await service.getStreak('u1'), isNull);
  });
}
