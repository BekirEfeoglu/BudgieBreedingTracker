abstract final class LevelCalculator {
  static int xpForLevel(int level) => level * 100;

  static int totalXpForLevel(int level) {
    int total = 0;
    for (int i = 1; i < level; i++) {
      total += xpForLevel(i);
    }
    return total;
  }

  static ({int level, int currentLevelXp, int nextLevelXp}) calculateLevel(int totalXp) {
    int level = 1;
    int remaining = totalXp;
    while (remaining >= xpForLevel(level)) {
      remaining -= xpForLevel(level);
      level++;
    }
    return (level: level, currentLevelXp: remaining, nextLevelXp: xpForLevel(level));
  }

  static String titleForLevel(int level) => switch (level) {
    1 => 'gamification.title_beginner',
    2 => 'gamification.title_novice',
    >= 3 && <= 4 => 'gamification.title_experienced',
    >= 5 && <= 9 => 'gamification.title_expert',
    >= 10 && <= 14 => 'gamification.title_master',
    >= 15 && <= 19 => 'gamification.title_grand_master',
    >= 20 => 'gamification.title_legendary',
    _ => 'gamification.title_beginner',
  };
}
