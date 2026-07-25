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
Sabit XP miktarları `XpConstants.xpValues` (`xp_constants.dart`) içinde tanımlı — **11 giriş**, aşağıdaki tablo o map'in birebir kopyasıdır. Günlük limit sütunu `XpConstants.dailyLimits`'ten gelir ve **yalnız 3 action** için tanımlıdır; geri kalanlar XP tarafında kasıtlı olarak capsizdir (bkz. Anti-Pattern #4).

| `XpAction` | XP | Günlük limit |
|------------|---:|-------------:|
| `dailyLogin` | 5 | 1 |
| `addBird` | 10 | yok |
| `createBreeding` | 15 | yok |
| `recordChick` | 10 | yok |
| `addHealthRecord` | 5 | yok |
| `completeProfile` | 20 | 1 |
| `sharePost` | 5 | yok |
| `addComment` | 3 | yok |
| `receiveLike` | 1 | yok |
| `createListing` | 10 | yok |
| `sendMessage` | 2 | 5 |

İki `XpAction` değeri `xpValues`'ta YOKTUR, miktarı başka yerden gelir:
- `unlockBadge` → `badges.xp_reward` (rozet tanımından)
- `streakBonus` → `private.streak_bonus_for` (+2/+5/+7/+10/+12), yalnız `record_daily_checkin` RPC'si yazar (§ Streak Sistemi)

Her ikisi için `private.xp_action_amount(...)` kasıtlı olarak `NULL` döner — istemcinin doğrudan `xp_transactions` insert'i RLS `WITH CHECK` tarafından reddedilir; tek yazma yolu DEFINER RPC/trigger'dır.

Günlük limitler farm/spam engellemek için; `GamificationService.recordAction` client-side ön-kontrol yapar, `private.enforce_xp_daily_limit` `BEFORE INSERT` trigger'ı server-side zorlar (§ Server-Side Write Enforcement → Günlük limit).

## Level Curve
- Formül: `LevelCalculator.xpForLevel(level) = level * 100` (lineer) — `lib/domain/services/gamification/level_calculator.dart`
- **Level cap YOK.** `calculateLevel` sınırsız bir `while (remaining >= xpForLevel(level))` döngüsüdür; clamp/max sabiti yok, "Master Breeder" diye bir kademe de yok. Üst kademe rütbe merdiveninin son bandıdır (`≥75 → title_bird_whisperer`) ve o da bir cap değil, açık uçlu bir aralıktır
- Level-up notification: in-app banner + opsiyonel push (settings'te kapatılabilir)

### Rütbe Merdiveni (10 kademe)
`LevelCalculator.titleForLevel(level)` seviyeyi bir rütbe l10n **anahtarına**
eşler (`gamification.title_*`). `profiles.xp_title` / `user_levels.title` bu
ANAHTARI saklar; UI göstermeden önce `.tr()` çağırır (2026-07-05'te community
yazar rozetinde ham anahtar sızıyordu — düzeltildi).

| Seviye | Anahtar | tr |
|--------|---------|----|
| ≤1 | `title_beginner` | Acemi Yetiştirici |
| 2–3 | `title_novice` | Çaylak Yetiştirici |
| 4–6 | `title_enthusiast` | Hevesli Yetiştirici |
| 7–10 | `title_experienced` | Deneyimli Yetiştirici |
| 11–15 | `title_expert` | Uzman Yetiştirici |
| 16–22 | `title_master` | Usta Yetiştirici |
| 23–32 | `title_grand_master` | Büyük Usta |
| 33–49 | `title_legendary` | Efsanevi Yetiştirici |
| 50–74 | `title_champion` | Şampiyon Yetiştirici |
| ≥75 | `title_bird_whisperer` | Kuş Fısıldayan |

**Kritik:** Dart `titleForLevel` ile SQL `private.xp_title_for_level` **birebir
aynı** olmak zorunda — gamification RLS `WITH CHECK` `title =
private.xp_title_for_level(level)` zorlar, ayrışma XP/level yazımını sessizce
reddeder. Bandları/anahtarları değiştirmek üçünü (Dart + SQL migration + l10n
tr/en/de) BİRLİKTE değiştirmeyi + mevcut satırların backfill'ini gerektirir
(bkz. migration `20260705165421_expand_rank_ladder`, prod'a uygulandı).
Rollout: SQL migration istemci sürümüyle birlikte gitmeli; güncellenmemiş
istemci remapped seviyede eski anahtar yazarsa o tek XP yazımı reddedilir
(recordAction yutar, veri kaybı yok).

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
Shipped kapsam **tek bir tablo**: tüm-zaman XP sıralamasının ilk 100'ü.
- Kaynak: `public.get_leaderboard(p_limit)` (INVOKER wrapper → `private.get_leaderboard`, SECURITY DEFINER) — `user_levels`'i `total_xp DESC` sıralar, `LIMIT GREATEST(1, LEAST(p_limit, 100))` ile clamp'ler
- Privacy: opt-out var (`profiles.show_in_leaderboard`); RPC opt-out'ları WHERE ile eler. `anon` grant'ı revoke edilmiştir, yalnız `authenticated` çağırabilir
- İstemci: `leaderboardProvider` (`gamification_providers.dart`) düz bir `FutureProvider` — TTL/`keepAlive` YOK. Tazeleme yalnız `LeaderboardScreen`'in pull-to-refresh'i (`ref.invalidate(leaderboardProvider)`) ile olur
- **Aylık board, self-rank (top 100 dışı konum) ve 5dk cache SHIPPED DEĞİL** — tasarım hedefi (`obsidian-brain/known-gaps.md`). Eklenirse RPC + provider + bu bölüm birlikte güncellenir

## Streak Sistemi
**Shipped (2026-07-12), server-authoritative.** `public.user_streaks` tablosu
(`current_streak, longest_streak, last_check_in_date, grace_used_this_month,
grace_month`) — owner-scope SELECT-only RLS, tek yazıcı `public.record_daily_checkin(p_time_zone)`
RPC'si (`SECURITY INVOKER` public wrapper → `private.record_daily_checkin`
`SECURITY DEFINER`, migrations `20260712100000_gamification_streaks.sql` +
`20260719012443_fix_streak_checkin_wrapper_privilege.sql`). Public wrapper
yalnızca `auth.uid()` ile çağıran kullanıcıyı türetir. REST'e kapalı private
core ve public wrapper `authenticated`/`service_role` için executable'dır;
`PUBLIC`/`anon` kapalı kalır. İlk migration private core'a authenticated
`EXECUTE` vermediği için prod'da `42501 permission denied` veriyordu.
Hotfix 2026-07-19'da production'a uygulandı; authenticated-role canlı çağrısı
`current_streak=1, awarded_xp=5` döndürdü ve simülatör yeniden başlatması
sonrasında aynı gün `dailyLogin` XP satırının tekil kaldığı doğrulandı.

- **Tetikleme:** İstemci `runDailyCheckin` (`streak_providers.dart`) app-init'te
  `InitStep.ready` sonrası deferred microtask'te çalışır — `tz.local.name`
  (bildirim servisinin set ettiği IANA zone) ile RPC'yi çağırır, kritik yolu
  bloklamaz (performance.md § Startup)
- **Local gün hesabı:** RPC `now() AT TIME ZONE p_time_zone` ile kullanıcının
  yerel gününü hesaplar (geçersiz tz → UTC fallback); aynı gün ikinci
  check-in no-op (`awarded_xp: 0`, streak değişmez)
- **Grace (otomatik affetme):** Ay başına **2 grace günü**. Tek günlük boşluk
  (`gap = 2`) grace hakkı varken affedilir (streak devam, `grace_consumed: true`);
  `gap >= 3` veya grace tükenmişse streak **1**'e resetlenir. Ay değişince
  grace sayacı sıfırlanır (`grace_month`)
- **XP ödülü:** Her check-in temel `dailyLogin` (5 XP, günlük limit 1 zaten
  var) + kademeli `streakBonus` (`private.streak_bonus_for`: `≥3→+2 · ≥7→+5 ·
  ≥14→+7 · ≥30→+10 · ≥60→+12`) — RPC içinde iki ayrı `xp_transactions` insert'i,
  var olan `AFTER INSERT` trigger `user_levels`/`profiles`'i SUM'dan senkronlar
  (bkz. § Server-Side Write Enforcement → Atomik level türetme)
- **UTC-cap toleransı (migration `20260712140000`):** RPC no-op guard'ı **yerel
  gün**le, `dailyLogin` günlük-limit trigger'ı **UTC gün**le çalışır. İki yerel
  check-in günü aynı UTC güne düşerse (offset zone'da akşam + ertesi sabah) ikinci
  `dailyLogin` insert'i `check_violation` fırlatır; RPC bunu **yutar** (streak yine
  ilerler, o UTC günü ikinci base XP verilmez, `streakBonus` korunur, `awarded_xp`
  base'i düşer). Bu insert'i guard'sız bırakma — tüm RPC abort edip streak/grace kaybettirir
- **Milestone rozetler:** streak tam 7/30/100'e ulaştığında `streak_7`
  (bronze, 30 XP) / `streak_30` (gold, 100 XP) / `streak_100` (platinum, 250 XP)
  `user_badges`'a idempotent upsert edilir (`ON CONFLICT (user_id, badge_id)`)
  + karşılık gelen `unlockBadge` XP'si (duplicate-guard'lı)
- **UI:** `StreakChip` (`lib/features/home/widgets/streak_chip.dart`) ana
  ekranda aktif streak'i gösterir (streak 0 ise gizli); launch sonrası
  `showStreakCelebration` (`lib/shared/widgets/gamification.dart` facade) bir
  kerelik SnackBar gösterir (milestone / grace-saved / normal varyant),
  `lastStreakCheckinProvider` temizlenince tekrar tetiklenmez
- **Bildirim:** `StreakReminderScheduler` her check-in sonrası (no-op dahil)
  yeniden koşar — toggle açık VE `currentStreak >= 3` ise **tek** hatırlatmayı
  yarın 20:00 local'e (`tz.TZDateTime`, field-addition gün offset'i) schedule
  eder; her zaman önce cancel-then-schedule. Kanal + toggle: bkz. notifications.md
  § Notification Categories ve `NotificationToggleSettings.streakReminder`
  (opt-out, `allEnabled`'a DAHİL DEĞİL)

## Anti-Gambling Pattern
- XP **shown but never spent** (loot box, gacha pattern YOK)
- Premium ile XP satın alma YOK (pay-to-win engeli)
- Random reward YOK (deterministic outcomes)
- Apple/Google policy uyumu — gambling content değil

## Sync Strategy
- `GamificationRepository` online-first — local Drift mirror YOK, server XP/badge ledger'ı source of truth
- Her aksiyon server'a direkt yazılır (`xp_transactions` tablosu); `user_levels` + `profiles.level`/`xp_title` bu insert'i izleyen trigger'la SUM'dan türetilir (bkz. § Server-Side Write Enforcement → Atomik level türetme)
- ValidatedSyncMixin bu repo'da kullanılmaz (offline-first değil, exemption listesine dahil — architecture.md § Online-First Exemption)

### Server-Side Write Enforcement (2026-07-02'de eklendi)
`xp_transactions`/`user_levels`/`user_badges`/`profiles` (level/xp_title/is_verified_breeder alanları) yazma işlemleri authenticated client'tan doğrudan yapılır (RPC değil) — bu yüzden RLS `WITH CHECK` kısıtlamaları TEK savunma hattıdır:
- `xp_transactions.amount` → `private.xp_action_amount(action)` (veya `unlockBadge` için `badges.xp_reward`) ile eşleşmeli
- `user_levels.total_xp` → gerçek `SUM(xp_transactions.amount)` ile eşleşmeli; `level`/`current_level_xp`/`next_level_xp`/`title` → `private.xp_calculate_level()`/`private.xp_title_for_level()` (Dart `LevelCalculator` mantığının SQL karşılığı) ile yeniden türetilmeli
- `user_badges.is_unlocked = true` → `progress >= badges.requirement`; `verified_breeder` rozeti için ayrıca `private.meets_verified_breeder_criteria(user_id)` gerekir (generic progress sayacı bu rozet için kullanılmaz)
- `profiles.level`/`xp_title` → kullanıcının kendi `user_levels` satırıyla eşleşmeli; `is_verified_breeder = true` → `private.meets_verified_breeder_criteria()` gerekir

Migration'lar: `20260702175125_gamification_server_side_helpers.sql`, `20260702175232_gamification_lock_down_self_grant.sql`. Canlıda `SET LOCAL ROLE authenticated` + sahte JWT ile rollback'li saldırı simülasyonuyla doğrulandı (doğrudan self-grant, keyfi XP miktarı, keyfi seviye üzerine yazma, sahte satırdan seviye uydurma, `verified_breeder` rozetini progress-eşitleme ile açma — hepsi reddedildi; meşru akış hâlâ çalışıyor).

**Atomik level türetme (audit K12/G2) — 2026-07-09'da kapatıldı:** `user_levels` artık **her zaman** `SUM(xp_transactions.amount)`'tan türetilir. `xp_transactions`'a bir `AFTER INSERT` trigger (`private.sync_user_level_from_xp`, SECURITY DEFINER + `search_path=''`) aynı transaction içinde SUM'ı yeniden hesaplar, `user_levels`'i upsert eder ve `profiles.level`/`xp_title`'ı senkronlar. Client **artık `total_xp` hesaplamaz/yazmaz** — eski artımlı yol (`existing + addedXp` → `upsertUserLevel`) kaldırıldı. Bu, önceki "brick" hatasını yapısal olarak imkânsız kılar: insert ile level-upsert arasında bir istek düşse bile `user_levels` bir sonraki insert'te SUM'a hizalanır (eskiden kalıcı desync → RLS WITH CHECK her level yazımını sessizce reddediyordu). Migration `20260709113822_gamification_atomic_level_sync.sql` mevcut drift'li satırları da SUM'dan yeniden hesaplayarak iyileştirir (backfill). RLS WITH CHECK kısıtları defense-in-depth olarak kalır (doğrudan client yazım denemesi hâlâ reddedilir). `GamificationService._updateUserLevel` ve badge-bonus manuel level upsert bloğu silindi; badge bonus XP'si de aynı trigger'la türetilir.

**Günlük limit (audit K12) — 2026-07-03'te kapatıldı:** `XpConstants.dailyLimits` artık server-side de zorlanıyor. WITH CHECK per-row olduğu için aggregate/count bazlı günlük limiti uygulayamaz; bu yüzden ayrı bir `BEFORE INSERT` trigger (`private.enforce_xp_daily_limit`, SECURITY DEFINER + `search_path=''`) UTC-günü içindeki aynı-action satır sayısını sayar ve limiti aşan insert'i `check_violation` ile reddeder. Limitler `private.xp_daily_limit()` ile mirror'lanır (`dailyLogin: 1`, `completeProfile: 1`, `sendMessage: 5`; diğerleri capsiz = NULL). Reddedilen insert client'ta `GamificationService.recordAction`'ın try/catch'iyle yutulur (XP opsiyonel yan etki) — happy path zaten client-side ön-kontrolle erken döndüğü için trigger yalnızca doğrudan-API kötüye kullanımında veya nadir race'te ateşler. Migration: `20260702234608_xp_daily_limit_enforcement.sql`. Canlıda rollback'li transaction ile doğrulandı (5 `sendMessage` kabul, 6. reddedildi, capsiz `addBird` kabul; test satırları rollback edildi, `security` advisor yeni bulgu 0).

## Performance
- XP award = **ağ yazımı** (`xp_transactions` insert), local Drift yazımı DEĞİL — bu repo online-first (§ Sync Strategy). Bu yüzden latency ağa bağlıdır ve XP her zaman opsiyonel bir yan etkidir: `recordAction` hatayı yutar, kullanıcı akışını bloklamaz
- Leaderboard fetch: tek `get_leaderboard` RPC çağrısı (`user_levels` + `profiles` join, `LIMIT 100`). Materialized view YOK — repoda hiç `MATERIALIZED VIEW` tanımı bulunmuyor
- Badge unlock check: trigger-time evaluation, polling YOK

## Notification
- Level up: in-app + opsiyonel push
- Badge unlock: in-app sadece (push gürültüsü)
- Leaderboard top 10 giriş: opt-in push
- Streak hatırlatması: **shipped** — her check-in sonrası tek reminder yarın 20:00 local'e schedule edilir, sadece streak≥3 VE toggle açıksa (§ Streak Sistemi); günde birden fazla veya kısa-aralıklı "bugün giriş yap" nag'i EKLEME (aşırı push anti-pattern'i geçerli kalır)

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
3. Client-side XP hesabı authoritative saymak (2026-07-02'de RLS WITH CHECK ile miktar/seviye/rozet server-enforce edildi; 2026-07-03'te günlük limit `BEFORE INSERT` trigger ile; 2026-07-09'da `total_xp`/level artımlı client hesabı tamamen kaldırılıp `AFTER INSERT` trigger ile SUM'dan türetildi — client'ta yeniden `upsertUserLevel`/artımlı `total_xp` EKLEME, bkz. § Server-Side Write Enforcement)
4. Cooldown'sız spam-able XP source: günlük limitli action'lar (`dailyLogin`/`completeProfile`/`sendMessage`) artık server-side capped; capsiz action'lar (örn. `sharePost`, `addComment`) hâlâ yalnızca içerik-moderation/rate-limit ile sınırlı — XP tarafında kasıtlı capsiz
5. Leaderboard'a opt-out koymamak (privacy)
6. Badge unlock'ı her widget rebuild'de check (perf — trigger-time only)
7. Level up push'unu zorunlu yapmak (anti-pattern: notification fatigue)
8. Streak mantığını istemciye taşımak (`user_streaks`'e client insert/update denemek — RLS SELECT-only reddeder; `record_daily_checkin` RPC dışında yazma yolu YOK)

> **İlgili**: premium-revenuecat.md (premium cosmetic badge), community.md (verified badge gösterim), architecture.md (§ Online-First Exemption), notifications.md (level up push, streak kanalı)
