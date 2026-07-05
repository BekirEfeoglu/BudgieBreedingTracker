abstract final class LevelCalculator {
  static int xpForLevel(int level) => level * 100;

  static int totalXpForLevel(int level) {
    int total = 0;
    for (int i = 1; i < level; i++) {
      total += xpForLevel(i);
    }
    return total;
  }

  static ({int level, int currentLevelXp, int nextLevelXp}) calculateLevel(
    int totalXp,
  ) {
    int level = 1;
    int remaining = totalXp;
    while (remaining >= xpForLevel(level)) {
      remaining -= xpForLevel(level);
      level++;
    }
    return (
      level: level,
      currentLevelXp: remaining,
      nextLevelXp: xpForLevel(level),
    );
  }

  /// Maps a level to its rank title l10n key.
  ///
  /// MUST stay byte-for-byte identical to the SQL `private.xp_title_for_level`
  /// (migration `20260705120000_expand_rank_ladder`) — the gamification RLS
  /// `WITH CHECK` enforces `xp_title = private.xp_title_for_level(level)`, so a
  /// divergence silently rejects XP/level writes. Change both together.
  static String titleForLevel(int level) => switch (level) {
    <= 1 => 'gamification.title_beginner',
    >= 2 && <= 3 => 'gamification.title_novice',
    >= 4 && <= 6 => 'gamification.title_enthusiast',
    >= 7 && <= 10 => 'gamification.title_experienced',
    >= 11 && <= 15 => 'gamification.title_expert',
    >= 16 && <= 22 => 'gamification.title_master',
    >= 23 && <= 32 => 'gamification.title_grand_master',
    >= 33 && <= 49 => 'gamification.title_legendary',
    >= 50 && <= 74 => 'gamification.title_champion',
    _ => 'gamification.title_bird_whisperer',
  };
}
