# Gamification & Verified Breeder Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rozet + seviye/XP + liderlik tablosu sistemi ve dogrulanmis yetistirici rozeti.

**Architecture:** 4 Freezed model (Badge, UserBadge, UserLevel, XpTransaction), 4 Supabase tablosu, GamificationService domain servisi. Feature 4 (Verified Breeder) gamification'in ozel bir rozeti olarak uygulanir — ayri tablo gerekmez, profiles tablosuna `is_verified_breeder` eklenir.

**Tech Stack:** Flutter, Riverpod 3, GoRouter, Supabase, Freezed 3, easy_localization

**Spec:** `docs/superpowers/specs/2026-04-02-community-social-features-design.md` — Feature 3 + 4

---

### Task 1: Enum Dosyasi

**Files:**
- Create: `lib/core/enums/gamification_enums.dart`

- [ ] **Step 1: Enum dosyasini olustur**

```dart
enum BadgeCategory {
  breeding,
  community,
  marketplace,
  health,
  milestone,
  special,
  unknown;

  String toJson() => name;

  static BadgeCategory fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return BadgeCategory.unknown;
    }
  }
}

enum BadgeTier {
  bronze,
  silver,
  gold,
  platinum,
  unknown;

  String toJson() => name;

  static BadgeTier fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return BadgeTier.unknown;
    }
  }
}

enum XpAction {
  dailyLogin,
  addBird,
  createBreeding,
  recordChick,
  addHealthRecord,
  completeProfile,
  sharePost,
  addComment,
  receiveLike,
  createListing,
  sendMessage,
  unlockBadge,
  unknown;

  String toJson() => name;

  static XpAction fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return XpAction.unknown;
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/enums/gamification_enums.dart
git commit -m "feat(gamification): add badge category, tier, and XP action enums"
```

---

### Task 2: Freezed Models (4 model)

**Files:**
- Create: `lib/data/models/badge_model.dart`
- Create: `lib/data/models/user_badge_model.dart`
- Create: `lib/data/models/user_level_model.dart`
- Create: `lib/data/models/xp_transaction_model.dart`

- [ ] **Step 1: Badge model**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:budgie_breeding_tracker/core/enums/gamification_enums.dart';

part 'badge_model.freezed.dart';
part 'badge_model.g.dart';

@freezed
abstract class Badge with _$Badge {
  const Badge._();

  const factory Badge({
    required String id,
    required String key,
    @JsonKey(unknownEnumValue: BadgeCategory.unknown)
    @Default(BadgeCategory.milestone)
    BadgeCategory category,
    @JsonKey(unknownEnumValue: BadgeTier.unknown)
    @Default(BadgeTier.bronze)
    BadgeTier tier,
    @Default('') String nameKey,
    @Default('') String descriptionKey,
    @Default('') String iconPath,
    @Default(0) int xpReward,
    @Default(0) int requirement,
    @Default(0) int sortOrder,
  }) = _Badge;

  factory Badge.fromJson(Map<String, dynamic> json) =>
      _$BadgeFromJson(json);
}
```

- [ ] **Step 2: UserBadge model**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_badge_model.freezed.dart';
part 'user_badge_model.g.dart';

@freezed
abstract class UserBadge with _$UserBadge {
  const UserBadge._();

  const factory UserBadge({
    required String id,
    required String userId,
    required String badgeId,
    @Default('') String badgeKey,
    @Default(0) int progress,
    @Default(false) bool isUnlocked,
    DateTime? unlockedAt,
    DateTime? createdAt,
  }) = _UserBadge;

  factory UserBadge.fromJson(Map<String, dynamic> json) =>
      _$UserBadgeFromJson(json);
}

extension UserBadgeX on UserBadge {
  double progressPercent(int requirement) {
    if (requirement <= 0) return 0;
    return (progress / requirement).clamp(0.0, 1.0);
  }
}
```

- [ ] **Step 3: UserLevel model**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_level_model.freezed.dart';
part 'user_level_model.g.dart';

@freezed
abstract class UserLevel with _$UserLevel {
  const UserLevel._();

  const factory UserLevel({
    required String id,
    required String userId,
    @Default(0) int totalXp,
    @Default(1) int level,
    @Default(0) int currentLevelXp,
    @Default(100) int nextLevelXp,
    @Default('') String title,
    DateTime? updatedAt,
  }) = _UserLevel;

  factory UserLevel.fromJson(Map<String, dynamic> json) =>
      _$UserLevelFromJson(json);
}

extension UserLevelX on UserLevel {
  double get levelProgress {
    if (nextLevelXp <= 0) return 0;
    return (currentLevelXp / nextLevelXp).clamp(0.0, 1.0);
  }
}
```

- [ ] **Step 4: XpTransaction model**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:budgie_breeding_tracker/core/enums/gamification_enums.dart';

part 'xp_transaction_model.freezed.dart';
part 'xp_transaction_model.g.dart';

@freezed
abstract class XpTransaction with _$XpTransaction {
  const XpTransaction._();

  const factory XpTransaction({
    required String id,
    required String userId,
    @JsonKey(unknownEnumValue: XpAction.unknown)
    @Default(XpAction.unknown)
    XpAction action,
    @Default(0) int amount,
    String? referenceId,
    DateTime? createdAt,
  }) = _XpTransaction;

  factory XpTransaction.fromJson(Map<String, dynamic> json) =>
      _$XpTransactionFromJson(json);
}
```

- [ ] **Step 5: Code generation + analiz + commit**

Run: `dart run build_runner build --delete-conflicting-outputs`
Run: `flutter analyze lib/data/models/badge_model.dart lib/data/models/user_badge_model.dart lib/data/models/user_level_model.dart lib/data/models/xp_transaction_model.dart`

```bash
git add lib/data/models/badge_model.dart lib/data/models/user_badge_model.dart lib/data/models/user_level_model.dart lib/data/models/xp_transaction_model.dart
git commit -m "feat(gamification): add Badge, UserBadge, UserLevel, XpTransaction freezed models"
```

---

### Task 3: Supabase Constants + Migration

**Files:**
- Modify: `lib/core/constants/supabase_constants.dart`
- Create: `supabase/migrations/20260402120000_create_gamification_tables.sql`

- [ ] **Step 1: Constants ekle**

```dart
  // Gamification
  static const String badgesTable = 'badges';
  static const String userBadgesTable = 'user_badges';
  static const String userLevelsTable = 'user_levels';
  static const String xpTransactionsTable = 'xp_transactions';
```

- [ ] **Step 2: Migration olustur**

4 tablo: `badges`, `user_badges`, `user_levels`, `xp_transactions`
RLS: badges public read, user_badges public read + own management, user_levels public read + own management, xp_transactions own only
Indexler: category, tier, sort_order, user_id, badge_id, is_unlocked, total_xp DESC, created_at DESC, action
Seed data: 15 rozet + verified_breeder rozeti (toplam 16)
profiles tablosuna `is_verified_breeder` boolean, `level` integer, `xp_title` text ekleme

- [ ] **Step 3: Commit**

```bash
git add lib/core/constants/supabase_constants.dart supabase/migrations/20260402120000_create_gamification_tables.sql
git commit -m "feat(gamification): add supabase constants and database migration with badge seed data"
```

---

### Task 4: Remote Sources + Providers

**Files:**
- Create: `lib/data/remote/api/gamification_remote_source.dart`
- Modify: `lib/data/remote/api/remote_source_providers.dart`

- [ ] **Step 1: Remote source olustur**

Methods: `fetchBadges()`, `fetchUserBadges(userId)`, `upsertUserBadge(data)`, `fetchUserLevel(userId)`, `upsertUserLevel(data)`, `insertXpTransaction(data)`, `fetchXpTransactions(userId, {limit})`, `fetchLeaderboard({limit})`, `fetchDailyXpCount(userId, action)`.

- [ ] **Step 2: Provider kaydi**

```dart
final gamificationRemoteSourceProvider = Provider<GamificationRemoteSource>((ref) {
  return GamificationRemoteSource(ref.watch(supabaseClientProvider));
});
```

- [ ] **Step 3: Commit**

```bash
git add lib/data/remote/api/gamification_remote_source.dart lib/data/remote/api/remote_source_providers.dart
git commit -m "feat(gamification): add gamification remote source"
```

---

### Task 5: GamificationService (Domain Service)

**Files:**
- Create: `lib/domain/services/gamification/gamification_service.dart`
- Create: `lib/domain/services/gamification/xp_constants.dart`
- Create: `lib/domain/services/gamification/level_calculator.dart`

- [ ] **Step 1: XP constants**

```dart
abstract final class XpConstants {
  static const Map<XpAction, int> xpValues = {
    XpAction.dailyLogin: 5,
    XpAction.addBird: 10,
    XpAction.createBreeding: 15,
    XpAction.recordChick: 10,
    XpAction.addHealthRecord: 5,
    XpAction.completeProfile: 20,
    XpAction.sharePost: 5,
    XpAction.addComment: 3,
    XpAction.receiveLike: 1,
    XpAction.createListing: 10,
    XpAction.sendMessage: 2,
  };

  static const Map<XpAction, int> dailyLimits = {
    XpAction.dailyLogin: 1,
    XpAction.completeProfile: 1,
    XpAction.sendMessage: 5,  // 5 * 2 = 10 XP/day max
  };
}
```

- [ ] **Step 2: Level calculator**

```dart
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
```

- [ ] **Step 3: GamificationService**

```dart
class GamificationService {
  final GamificationRemoteSource _remoteSource;

  GamificationService(this._remoteSource);

  Future<void> recordAction(String userId, XpAction action, {String? referenceId}) async {
    // 1. Check daily limit
    // 2. Get XP amount from XpConstants
    // 3. Insert XP transaction
    // 4. Update user level (recalculate)
    // 5. Update badge progress for relevant badges
    // 6. Check if any badge unlocked → add bonus XP
  }

  Future<void> checkVerifiedBreeder(String userId) async {
    // Check all 6 criteria
    // If all met → unlock verified_breeder badge + set profiles.is_verified_breeder
    // If not met but was verified → revoke badge + clear flag
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/domain/services/gamification/
git commit -m "feat(gamification): add GamificationService with XP constants and level calculator"
```

---

### Task 6: Repository + Provider

**Files:**
- Create: `lib/data/repositories/gamification_repository.dart`
- Modify: `lib/data/repositories/repository_providers.dart`

- [ ] **Step 1: Repository**

Wraps remote source + GamificationService:
- `getBadges()`, `getUserBadges(userId)`, `getUserLevel(userId)`, `getXpHistory(userId)`, `getLeaderboard()`, `recordAction(userId, action, referenceId)`, `checkVerifiedBreeder(userId)`

- [ ] **Step 2: Provider**

```dart
final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  return GamificationRepository(
    remoteSource: ref.watch(gamificationRemoteSourceProvider),
  );
});
```

- [ ] **Step 3: Commit**

```bash
git add lib/data/repositories/gamification_repository.dart lib/data/repositories/repository_providers.dart
git commit -m "feat(gamification): add gamification repository"
```

---

### Task 7: Feature Providers

**Files:**
- Create: `lib/features/gamification/providers/gamification_providers.dart`

- [ ] **Step 1: Providers**

- `badgesProvider` — FutureProvider (all badges)
- `userBadgesProvider(userId)` — FutureProvider.family
- `userLevelProvider(userId)` — FutureProvider.family
- `xpHistoryProvider(userId)` — FutureProvider.family
- `leaderboardProvider` — FutureProvider
- `badgeCategoryFilterProvider` — NotifierProvider
- `filteredBadgesProvider` — Provider.family (filter by category)
- `enrichedBadgesProvider` — Provider.family (combine Badge + UserBadge for progress display)

- [ ] **Step 2: Commit**

```bash
git add lib/features/gamification/providers/gamification_providers.dart
git commit -m "feat(gamification): add feature providers"
```

---

### Task 8: Lokalizasyon

**Files:**
- Modify: `assets/translations/tr.json`, `en.json`, `de.json`

- [ ] **Step 1: badges + gamification + leaderboard keyleri ekle (~120 key)**

Kategoriler:
- `badges.` — rozet adlari (first_bird, bird_lover_10, ..., verified_breeder), aciklamalari, tier labels, category labels, UI
- `gamification.` — seviye unvanlari, XP aksiyon aciklamalari, UI
- `leaderboard.` — liderlik tablosu UI

- [ ] **Step 2: L10n sync + commit**

```bash
git add assets/translations/
git commit -m "feat(gamification): add localization keys for badges, gamification, and leaderboard"
```

---

### Task 9: Routes + Screens

**Files:**
- Modify: `lib/router/route_names.dart`
- Create: `lib/router/routes/gamification_routes.dart`
- Modify: `lib/router/app_router.dart`
- Create: `lib/features/gamification/screens/badges_screen.dart`
- Create: `lib/features/gamification/screens/badge_detail_screen.dart`
- Create: `lib/features/gamification/screens/leaderboard_screen.dart`

- [ ] **Step 1: Route sabitleri**

```dart
  // Gamification
  static const badges = '/badges';
  static const badgeDetail = '/badges/:id';
  static const leaderboard = '/leaderboard';
```

- [ ] **Step 2: Route builder**

`buildGamificationRoutes()` — badges (list), badges/:id (detail), leaderboard

- [ ] **Step 3: Screens**

BadgesScreen: grid/list of badges grouped by category, progress bars, filter chips
BadgeDetailScreen: large badge icon, description, progress, requirement, XP reward, tier
LeaderboardScreen: ranked list of users by total XP, current user highlighted

- [ ] **Step 4: Commit**

```bash
git add lib/router/ lib/features/gamification/screens/
git commit -m "feat(gamification): add routes and screens for badges, detail, and leaderboard"
```

---

### Task 10: Badge Widgets

**Files:**
- Create: `lib/features/gamification/widgets/badge_card.dart`
- Create: `lib/features/gamification/widgets/xp_progress_bar.dart`
- Create: `lib/features/gamification/widgets/leaderboard_tile.dart`

- [ ] **Step 1: Badge card**

Shows badge icon, name, tier, progress bar, locked/unlocked state.

- [ ] **Step 2: XP progress bar**

Shows current XP / next level XP with animated progress.

- [ ] **Step 3: Leaderboard tile**

Shows rank, avatar, username, level, total XP, verified badge.

- [ ] **Step 4: Commit**

```bash
git add lib/features/gamification/widgets/
git commit -m "feat(gamification): add badge card, XP progress bar, and leaderboard tile widgets"
```

---

### Task 11: Model + Service Tests

**Files:**
- Create: `test/data/models/badge_model_test.dart`
- Create: `test/data/models/user_level_model_test.dart`
- Create: `test/domain/services/gamification/level_calculator_test.dart`

- [ ] **Step 1: Badge model test**

Round-trip, unknown category/tier, defaults.

- [ ] **Step 2: UserLevel model test**

Round-trip, levelProgress extension, defaults.

- [ ] **Step 3: LevelCalculator test**

```
xpForLevel(1) == 100
xpForLevel(5) == 500
calculateLevel(0) == (level: 1, currentLevelXp: 0, nextLevelXp: 100)
calculateLevel(150) == (level: 2, currentLevelXp: 50, nextLevelXp: 200)
calculateLevel(4500) == (level: 10, ...)
titleForLevel(1) == 'gamification.title_beginner'
titleForLevel(10) == 'gamification.title_master'
titleForLevel(20) == 'gamification.title_legendary'
```

- [ ] **Step 4: Commit**

```bash
git add test/data/models/badge_model_test.dart test/data/models/user_level_model_test.dart test/domain/services/gamification/
git commit -m "test(gamification): add model and level calculator tests"
```

---

### Task 12: CLAUDE.md Stats + Final Dogrulama

- [ ] **Step 1: verify_rules.py --fix**
- [ ] **Step 2: verify_code_quality.py**
- [ ] **Step 3: check_l10n_sync.py**
- [ ] **Step 4: flutter analyze --no-fatal-infos**
- [ ] **Step 5: Commit**

```bash
git add CLAUDE.md
git commit -m "chore: update CLAUDE.md stats for gamification feature"
```
