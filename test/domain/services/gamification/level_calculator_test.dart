import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/domain/services/gamification/level_calculator.dart';

void main() {
  group('LevelCalculator', () {
    test('xpForLevel returns level * 100', () {
      expect(LevelCalculator.xpForLevel(1), 100);
      expect(LevelCalculator.xpForLevel(5), 500);
      expect(LevelCalculator.xpForLevel(10), 1000);
      expect(LevelCalculator.xpForLevel(20), 2000);
    });

    test('totalXpForLevel accumulates correctly', () {
      expect(LevelCalculator.totalXpForLevel(1), 0);
      expect(LevelCalculator.totalXpForLevel(2), 100);
      expect(LevelCalculator.totalXpForLevel(3), 300);
      // 100 + 200 + 300 + 400 = 1000
      expect(LevelCalculator.totalXpForLevel(5), 1000);
    });

    test('calculateLevel at 0 XP', () {
      final result = LevelCalculator.calculateLevel(0);
      expect(result.level, 1);
      expect(result.currentLevelXp, 0);
      expect(result.nextLevelXp, 100);
    });

    test('calculateLevel at 50 XP', () {
      final result = LevelCalculator.calculateLevel(50);
      expect(result.level, 1);
      expect(result.currentLevelXp, 50);
      expect(result.nextLevelXp, 100);
    });

    test('calculateLevel at exactly 100 XP (level up)', () {
      final result = LevelCalculator.calculateLevel(100);
      expect(result.level, 2);
      expect(result.currentLevelXp, 0);
      expect(result.nextLevelXp, 200);
    });

    test('calculateLevel at 150 XP', () {
      final result = LevelCalculator.calculateLevel(150);
      expect(result.level, 2);
      expect(result.currentLevelXp, 50);
      expect(result.nextLevelXp, 200);
    });

    test('calculateLevel at 300 XP (level 3)', () {
      final result = LevelCalculator.calculateLevel(300);
      expect(result.level, 3);
      expect(result.currentLevelXp, 0);
      expect(result.nextLevelXp, 300);
    });

    test('calculateLevel at 1000 XP (level 5)', () {
      final result = LevelCalculator.calculateLevel(1000);
      expect(result.level, 5);
      expect(result.currentLevelXp, 0);
      expect(result.nextLevelXp, 500);
    });

    test('titleForLevel returns correct titles', () {
      expect(LevelCalculator.titleForLevel(1), 'gamification.title_beginner');
      expect(LevelCalculator.titleForLevel(2), 'gamification.title_novice');
      expect(LevelCalculator.titleForLevel(3), 'gamification.title_experienced');
      expect(LevelCalculator.titleForLevel(5), 'gamification.title_expert');
      expect(LevelCalculator.titleForLevel(10), 'gamification.title_master');
      expect(LevelCalculator.titleForLevel(15), 'gamification.title_grand_master');
      expect(LevelCalculator.titleForLevel(20), 'gamification.title_legendary');
      expect(LevelCalculator.titleForLevel(25), 'gamification.title_legendary');
    });
  });
}
