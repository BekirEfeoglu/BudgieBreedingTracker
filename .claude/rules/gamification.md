# Gamification

XP, level, badge, leaderboard, verified breeder sistemi. `GamificationService` (`lib/domain/services/gamification/`) tüm hesabı yönetir. Amaç: kullanıcı engagement + uzun vadeli retention, NOT gambling pattern.

## Stack
| Bileşen | Yer |
|---------|-----|
| Service | `GamificationService` |
| Level curve | `level_calculator.dart` |
| XP constants | `xp_constants.dart` |
| Feature | `lib/features/gamification/` |
| Storage | Drift `user_progress` + Supabase sync |
| Badge metadata | `lib/core/constants/badge_definitions.dart` |

## XP Award Mantığı
Sabit XP miktarları `xp_constants.dart` içinde tanımlı. Her aksiyon trigger edildiğinde service tarafından yazılır:

| Aksiyon | XP | Cooldown |
|---------|----|---------:|
| Kuş ekle | 10 | yok |
| Yumurta lifecycle complete | 50 | yok |
| İlk başarılı kuluçka | 100 | bir kez |
| Topluluk post (moderation passed) | 5 | günde max 10 |
| Helpful comment (like > N) | 15 | günde max 3 |
| Daily login streak | 5 + bonus | günlük |
| Profile completion | 20 | bir kez |
| Genetics calculator kullanım | 2 | günde max 5 |

Cooldown'lar farm/spam engellemek için. Server-side enforce (`gamification_events` table + unique constraint).

## Level Curve
- Formül: `xpRequired(level) = 100 * level * (level + 1) / 2` (quadratic — early levels fast, late slow)
- Max level: 100 (cap, sonrası "Master Breeder" cosmetic)
- Level-up notification: in-app banner + opsiyonel push (settings'te kapatılabilir)

## Badge Sistemi
- Badge'ler `badge_definitions.dart` içinde immutable definition
- Achievement-based: tek seferlik unlock (örn. "İlk kuluçka")
- Progress-based: kademeli (örn. "10 kuş", "50 kuş")
- Skill-based: nadiren (örn. "Pure white spangle yetiştir")
- Badge unlock'ı server-side hesap (`gamification_service` edge fn — implementing detail, may vary)

## Verified Breeder
- Premium kullanıcılar için ek doğrulama tier
- Kriterler: 6 ay aktif, 10+ başarılı kuluçka, KYC (opsiyonel doc upload)
- Manuel admin approval (audit + dispute resolution)
- Profile + community + marketplace'te mavi tik
- Revoke edilebilir (moderation ihlali sonrası)

## Leaderboard
- Global: tüm zaman XP toplamı (cap top 100)
- Aylık: bu ay kazanılan XP (resetlenir)
- Privacy: opt-out var (`profile.show_in_leaderboard`)
- Self rank: kullanıcı kendi konumunu görür (top 100 dışında bile)
- Update frequency: 5dk cache (real-time gereksiz, cost)

## Streak Mantığı
- "Daily login": 24 saat içinde app açma (UTC-based değil, local timezone)
- Miss tolerance: 1 gün miss → streak korur, 2 gün → reset
- Bonus: 7 gün streak = +20 XP, 30 gün = +100 XP, 100 gün = badge
- Streak gaming engeli: aynı IP'den 5+ hesap detect (anti-fraud)

## Anti-Gambling Pattern
- XP **shown but never spent** (loot box, gacha pattern YOK)
- Premium ile XP satın alma YOK (pay-to-win engeli)
- Random reward YOK (deterministic outcomes)
- Apple/Google policy uyumu — gambling content değil

## Sync Strategy
- Local Drift `user_progress` source of truth (offline support)
- Supabase'e push: her award sonrası
- Conflict: server XP > local XP (server kazanır, anti-cheat)
- ValidatedSyncMixin: `gamification_events` user_id FK validate

## Performance
- XP award < 50ms (local Drift write)
- Leaderboard fetch p95 < 1s (server materialized view)
- Badge unlock check: trigger-time evaluation, polling YOK
- Cache: kullanıcı progress 1dk TTL

## Notification
- Level up: in-app + opsiyonel push
- Badge unlock: in-app sadece (push gürültüsü)
- Leaderboard top 10 giriş: opt-in push
- Streak miss uyarısı: 22 saat sonra "Bugün giriş yap" (anti-pattern: aşırı push)

## Free vs Premium
- XP earn rate aynı (premium accelerator YOK — pay-to-win engeli)
- Premium extras: özel cosmetic badge ("Founder", "Beta tester")
- Leaderboard rozeti premium işareti — premium destekleyici sinyal

## Empty / Error State
- Yeni kullanıcı: "İlk XP'nizi kuş ekleyerek kazanın" + CTA
- Leaderboard'da kimse yok: "Yarışmayı sen başlat" pozitif framing
- Sync fail: cached değer göster + soft retry

## Testing
- Unit: level curve eşik testleri (level 1→2, 50→51, 99→100)
- Unit: streak miss tolerance (1 gün OK, 2 gün reset)
- Integration: badge unlock trigger (action → badge row exists)
- E2E: full XP flow (action → server → leaderboard update)

```dart
test('streak survives 1 day miss', () {
  final yesterday = DateTime.now().subtract(const Duration(hours: 25));
  final dayBefore = yesterday.subtract(const Duration(hours: 25));
  final progress = UserProgress(lastLoginAt: dayBefore, streak: 10);
  final updated = service.checkStreak(progress, today: DateTime.now());
  expect(updated.streak, 10); // 1 gün miss tolere edilir
});

test('badge unlock fires on threshold', () async {
  // 9 bird varken add → 10. eklendiğinde "10 kuş" badge unlock
  await service.awardXp(userId, BirdAddedEvent());
  final badges = await badgeRepository.getUnlocked(userId);
  expect(badges.map((b) => b.id), contains('ten_birds'));
});
```

## Anti-Patterns
1. XP satın almak / premium hızlandırıcı (pay-to-win, gambling policy)
2. Random reward / loot box (Apple policy ihlali)
3. Client-side XP hesabı authoritative (cheat trivial — server enforce)
4. Cooldown'sız spam-able XP source (topluluk post farm)
5. Streak'i UTC-only hesaplamak (timezone bug, kullanıcı haksız reset)
6. Leaderboard'a opt-out koymamak (privacy)
7. Badge unlock'ı her widget rebuild'de check (perf — trigger-time only)
8. Verified breeder mavi tiki otomatik vermek (audit gerek + dispute riski)
9. Level up push'unu zorunlu yapmak (anti-pattern: notification fatigue)
10. Anti-fraud (multi-account streak farm) detection yokluğu (leaderboard bütünlüğü)

> **İlgili**: premium-revenuecat.md (premium cosmetic badge), community.md (verified badge gösterim), datetime-format.md (streak day math), background-sync.md (gamification_events sync), notifications.md (level up push)
