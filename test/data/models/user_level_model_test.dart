import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/data/models/user_level_model.dart';

void main() {
  group('UserLevel', () {
    test('toJson/fromJson round-trip', () {
      final level = UserLevel(
        id: 'l1',
        userId: 'u1',
        totalXp: 350,
        level: 3,
        currentLevelXp: 50,
        nextLevelXp: 300,
        title: 'gamification.title_experienced',
      );

      final json = level.toJson();
      final restored = UserLevel.fromJson(json);

      expect(restored.id, level.id);
      expect(restored.userId, level.userId);
      expect(restored.totalXp, level.totalXp);
      expect(restored.level, level.level);
      expect(restored.currentLevelXp, level.currentLevelXp);
      expect(restored.nextLevelXp, level.nextLevelXp);
      expect(restored.title, level.title);
    });

    test('levelProgress returns correct ratio', () {
      final level = UserLevel(
        id: 'l1',
        userId: 'u1',
        currentLevelXp: 50,
        nextLevelXp: 200,
      );
      expect(level.levelProgress, 0.25);
    });

    test('levelProgress clamps to 1.0', () {
      final level = UserLevel(
        id: 'l1',
        userId: 'u1',
        currentLevelXp: 300,
        nextLevelXp: 200,
      );
      expect(level.levelProgress, 1.0);
    });

    test('levelProgress returns 0 when nextLevelXp is 0', () {
      final level = UserLevel(
        id: 'l1',
        userId: 'u1',
        nextLevelXp: 0,
      );
      expect(level.levelProgress, 0);
    });

    test('default values are correct', () {
      final level = UserLevel(id: 'l1', userId: 'u1');
      expect(level.totalXp, 0);
      expect(level.level, 1);
      expect(level.currentLevelXp, 0);
      expect(level.nextLevelXp, 100);
      expect(level.title, '');
    });
  });
}
