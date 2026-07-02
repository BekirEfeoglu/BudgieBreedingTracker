# Gamification

XP, level, badge, leaderboard, verified breeder sistemi. `GamificationService` (`lib/domain/services/gamification/`) tüm hesabı yönetir. Amaç: kullanıcı engagement + uzun vadeli retention, NOT gambling pattern.

## Stack
| Bileşen | Yer |
|---------|-----|
| Service | `GamificationService` |
| Level curve | `level_calculator.dart` |
| XP constants | `xp_constants.dart` |
| Feature | `lib/features/gamification/` |
| Storage | `GamificationRepository` — **online-first**, server-authoritative XP/badge ledger, no local Drift mirror by design |
| Badge metadata | Server-driven (`GamificationRemoteSource.fetchBadges()`) + model `lib/data/models/badge_model.dart` |

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

Cooldown'lar farm/spam engellemek için. Server-side enforce (`xp_transactions` table + unique constraint).

## Level Curve
- Formül: `LevelCalculator.xpForLevel(level) = level * 100` (lineer) — `lib/domain/services/gamification/level_calculator.dart`
- Max level: 100 (cap, sonrası "Master Breeder" cosmetic)
- Level-up notification: in-app banner + opsiyonel push (settings'te kapatılabilir)

## Badge Sistemi
- Badge tanımları server'dan gelir (`GamificationRemoteSource.fetchBadges()`); local model `badge_model.dart`. Hardcoded definitions dosyası YOK
- Achievement-based: tek seferlik unlock (örn. "İlk kuluçka")
- Progress-based: kademeli (örn. "10 kuş", "50 kuş")
- Skill-based: nadiren (örn. "Pure white spangle yetiştir")
- Badge unlock'ı server-side hesap (`gamification_service` edge fn — implementing detail, may vary)

## Verified Breeder
- `GamificationService.checkVerifiedBreeder` ile **otomatik** hesaplanır (admin onayı YOK)
- Kriterler: `level >= 5 AND birds >= 3 AND breeding_pairs >= 1 AND chicks >= 1` (`lib/domain/services/gamification/gamification_service.dart`)
- Profile + community + marketplace'te mavi tik
- 6 ay aktiflik, kuluçka sayısı eşiği veya KYC şu an kod tabanında YOK — bu bölüm önceki bir tasarım hedefiydi, gerçek implementasyonla eşleşmiyordu

## Leaderboard
- Global: tüm zaman XP toplamı (cap top 100)
- Aylık: bu ay kazanılan XP (resetlenir)
- Privacy: opt-out var (`profile.show_in_leaderboard`)
- Self rank: kullanıcı kendi konumunu görür (top 100 dışında bile)
- Update frequency: 5dk cache (real-time gereksiz, cost)

## Streak Mantığı
**Henüz implement edilmedi (2026-07-02 audit):** miss-tolerance, gün bazlı bonus
(7/30/100 gün), IP bazlı anti-fraud detection kod tabanında YOKTUR — bu bölüm
gelecek tasarım hedefidir. Bugün var olan tek şey: `xp_constants.dart`'ta düz
`dailyLogin: 5` XP değeri + `dailyLimit: 1` (streak/consecutive-day takibi
yok). Eklenirse bu bölüm gerçek implementasyonla güncellenmelidir.

## Anti-Gambling Pattern
- XP **shown but never spent** (loot box, gacha pattern YOK)
- Premium ile XP satın alma YOK (pay-to-win engeli)
- Random reward YOK (deterministic outcomes)
- Apple/Google policy uyumu — gambling content değil

## Sync Strategy
- `GamificationRepository` online-first — local Drift mirror YOK, server XP/badge ledger'ı source of truth
- Her aksiyon server'a direkt yazılır (`xp_transactions` tablosu)
- ValidatedSyncMixin bu repo'da kullanılmaz (offline-first değil, exemption listesine dahil — architecture.md § Online-First Exemption)

### Server-Side Write Enforcement (2026-07-02'de eklendi)
`xp_transactions`/`user_levels`/`user_badges`/`profiles` (level/xp_title/is_verified_breeder alanları) yazma işlemleri authenticated client'tan doğrudan yapılır (RPC değil) — bu yüzden RLS `WITH CHECK` kısıtlamaları TEK savunma hattıdır:
- `xp_transactions.amount` → `private.xp_action_amount(action)` (veya `unlockBadge` için `badges.xp_reward`) ile eşleşmeli
- `user_levels.total_xp` → gerçek `SUM(xp_transactions.amount)` ile eşleşmeli; `level`/`current_level_xp`/`next_level_xp`/`title` → `private.xp_calculate_level()`/`private.xp_title_for_level()` (Dart `LevelCalculator` mantığının SQL karşılığı) ile yeniden türetilmeli
- `user_badges.is_unlocked = true` → `progress >= badges.requirement`; `verified_breeder` rozeti için ayrıca `private.meets_verified_breeder_criteria(user_id)` gerekir (generic progress sayacı bu rozet için kullanılmaz)
- `profiles.level`/`xp_title` → kullanıcının kendi `user_levels` satırıyla eşleşmeli; `is_verified_breeder = true` → `private.meets_verified_breeder_criteria()` gerekir

Migration'lar: `20260702175125_gamification_server_side_helpers.sql`, `20260702175232_gamification_lock_down_self_grant.sql`. Canlıda `SET LOCAL ROLE authenticated` + sahte JWT ile rollback'li saldırı simülasyonuyla doğrulandı (doğrudan self-grant, keyfi XP miktarı, keyfi seviye üzerine yazma, sahte satırdan seviye uydurma, `verified_breeder` rozetini progress-eşitleme ile açma — hepsi reddedildi; meşru akış hâlâ çalışıyor).

**Hâlâ açık (audit K12, bu fix'in kapsamı dışında):** günlük limit/cooldown (`XpConstants.dailyLimits`) sadece client-side kontrol edilir — WITH CHECK per-row olduğu için aggregate/count bazlı günlük limiti burada uygulayamaz. Bir kullanıcı `dailyLogin`/`completeProfile`/`sendMessage` için GEÇERLİ miktarda ama GÜNDE BİRDEN FAZLA `xp_transactions` satırı ekleyebilir (spam, cheat DEĞİL — her satır kendi başına geçerli). Kalıcı çözüm: `(user_id, action, date_trunc('day', created_at))` üzerinde unique constraint veya cooldown'u da doğrulayan bir trigger/RPC.

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
- Integration: badge unlock trigger (action → badge row exists)
- E2E: full XP flow (action → server → leaderboard update)

```dart
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
3. Client-side XP hesabı authoritative saymak (2026-07-02'de RLS WITH CHECK ile server-enforce edildi — bkz. § Server-Side Write Enforcement; günlük limit/cooldown hâlâ client-only, ayrı bilinen boşluk)
4. Cooldown'sız spam-able XP source (topluluk post farm — günlük limit boşluğu nedeniyle hâlâ geçerli, § Server-Side Write Enforcement'taki not)
5. Leaderboard'a opt-out koymamak (privacy)
6. Badge unlock'ı her widget rebuild'de check (perf — trigger-time only)
7. Level up push'unu zorunlu yapmak (anti-pattern: notification fatigue)

> **İlgili**: premium-revenuecat.md (premium cosmetic badge), community.md (verified badge gösterim), architecture.md (§ Online-First Exemption), notifications.md (level up push)
