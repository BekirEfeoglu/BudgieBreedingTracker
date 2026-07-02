# BudgieBreedingTracker — İnceleme Raporu ve İyileştirme Planı

**Tarih:** 2026-07-03 · **Sürüm:** v1.1.4+51 · **HEAD:** `8e52c37` (main, CI yeşil)
**Önceki plan:** 2026-05-17 tarihli plan `82a7061` ile uygulandı; P0/P1 maddeleri bugün
aktif checker'larla doğrulandı (bkz. § 9). Bu belge onun yerini alır.

> **Uygulayıcılar için:** Görevler `- [ ]` checkbox'larıyla izlenir. Her görev kendi
> doğrulama komutlarıyla biter. Commit öncesi: `scripts/run_local_quality_gate.sh` (§ 8).

---

## 1. Yönetici Özeti

Uygulama **olağanüstü sağlıklı durumda**. 2026-07-02'deki iki tam kapsamlı audit'in
(~50 + 13 bulgu, 1 hariç tamamı remediate) ardından bugünkü bağımsız incelemede
**yeni bug bulunamadı**: statik analiz 0, 27 anti-pattern tarayıcısı 0/0, güvenlik
37/37, **11.912/11.912 test geçti**, l10n 3 dilde senkron, sıfır TODO/FIXME, sıfır
skip'li test, remote CI yeşil (17 success + 1 bilinçli skip).

Bu plan bu yüzden "yangın söndürme" değil, üç eksende ilerleme planıdır:

1. **P1 — Güvenlik/operasyon:** server-side günlük XP limiti (bilinen K12 açığı),
   OAuth Phase 2 cutover (bir sonraki imzalı release'i bloklar), mesaj gönderiminde
   failed/retry durumu.
2. **P2 — Ürün açıkları + bağımlılık borcu:** send-push quiet-hours, post edit,
   attachment stub'ı, Flutter 3.44 ve bağımlılık yükseltme zinciri.
3. **P3 — Backlog:** mute, streak, kill-switch, faz seçici UI, eski plandan devreden
   kalemler.

## 2. Mevcut Sağlık Durumu (2026-07-03 ölçümleri)

| Kontrol | Sonuç |
|---|---|
| `flutter analyze --no-fatal-infos` | ✅ 0 sorun |
| `verify_code_quality.py` (27 checker) | ✅ 0 error / 0 warning |
| `flutter test --exclude-tags golden` | ✅ **11.912/11.912** (4dk55sn) |
| `check_l10n_sync.py` | ✅ 3.015 anahtar × tr/en/de senkron |
| `verify_rules.py` / `check_obsidian_brain.py` / `check_platform_targets.py` | ✅ 24/24 · OK · OK |
| `verify_security.py` | ✅ 37/37 güvenlik kontrolü |
| Remote CI (`check_remote_status.py`, `8e52c37`) | ✅ 17 success + 1 bilinçli skip |
| TODO/FIXME/HACK + skip'li test taraması | ✅ 0 + 0 adet |
| Supabase security advisor (canlı) | ⚠️ 1 INFO — bilinçli, aksiyon yok (§ 6.7) |
| Supabase performance advisor (canlı) | ⚠️ 110 `unused_index` INFO (§ 6.6) |

**Bağımlılık görünümü:** Flutter 3.41.4 (stable ~3.44'e 1-2 sürüm geride) ·
`supabase_flutter` bilinçli pin `<2.13.0` (latest 2.15.3, passkeys/visionOS sorunu) ·
`connectivity_plus` bilinçli pin `<7.1.0` (iOS 26 SDK bekliyor) ·
`sqlite3_flutter_libs 0.5.42` → 0.6.0 **EOL işaretli** · drift 2.31→2.34 analyzer
zinciri bloklu (Flutter yükseltmesi açar) · risksiz küçük bump'lar hazır
(sentry 9.23, purchases 10.4, image_picker 1.2.3, timezone 0.11.1).

## 3. Öncelik Matrisi

| # | Görev | Öncelik | Etki | Efor | Bölüm |
|---|---|---|---|---|---|
| 1 | Günlük XP limiti server-side (K12) | **P1** | Güvenlik/anti-spam | S | § 4.1 |
| 2 | OAuth Phase 2 cutover (env + doğrulama) | **P1** | Release blocker | S | § 4.2 |
| 3 | Mesaj delivery-status + failed/retry UI | **P1** | Veri kaybı algısı | M | § 4.3 |
| 4 | Messaging attachment stub'ını gizle | **P2** | UX tuzağı | XS | § 5.1 |
| 5 | send-push server-side quiet hours (DND) | **P2** | Kullanıcı beklentisi | M | § 5.2 |
| 6 | Community post edit (5 dk window) | **P2** | Ürün açığı | M | § 5.3 |
| 7 | Admin moderation queue per-card loading | **P2** | UX (dün ertelenen) | XS | § 5.4 |
| 8 | Calendar hatırlatma offset seçimi | **P2** | Ürün açığı | S | § 5.5 |
| 9 | Bağımlılık yükseltme zinciri (4 faz) | **P2** | Bakım/güvenlik | M | § 7 |
| 10-17 | Backlog kalemleri | P3 | — | — | § 6 |

Efor: XS < 2 saat · S ≈ yarım-1 gün · M ≈ 1-3 gün.
**Önerilen sıra:** 2 → 4 → 1 → 7 → 3 → 9(Faz-1) → 8 → 5 → 6 → 9(Faz-2/3) → P3.

---

## 4. P1 Görevleri

### 4.1 Günlük XP limitini server-side uygula (audit K12)

**Sorun:** `XpConstants.dailyLimits` (`lib/domain/services/gamification/xp_constants.dart:18-22`)
yalnız client'ta. RLS `WITH CHECK` per-row olduğundan aggregate sayamıyor; kullanıcı
geçerli miktarda ama günde sınırsız `xp_transactions` satırı ekleyebilir. Kaynak:
`.claude/rules/gamification.md` § Server-Side Write Enforcement → "Hâlâ açık (K12)".

**Gerçek limitler (SQL'e birebir):** `dailyLogin: 1`, `completeProfile: 1`,
`sendMessage: 5`. Not: `completeProfile` gün bazlı değil **ömür boyu 1** sayılmalı.

**Dosyalar:** Oluştur `supabase/migrations/<UTC-timestamp>_xp_daily_limit_enforcement.sql`;
güncelle `.claude/rules/gamification.md`, `obsidian-brain/domain/gamification-service.md`, `obsidian-brain/log.md`.

- [ ] **1. Migration'ı yaz** — `20260702175125_gamification_server_side_helpers.sql`
  stilinde (private şema, `SET search_path = ''`, idempotent):

```sql
-- Mirrors XpConstants.dailyLimits (lib/domain/services/gamification/xp_constants.dart).
CREATE OR REPLACE FUNCTION private.xp_daily_limit(p_action text)
RETURNS integer LANGUAGE sql STABLE SET search_path = ''
AS $$
  SELECT CASE p_action
    WHEN 'dailyLogin' THEN 1
    WHEN 'completeProfile' THEN 1
    WHEN 'sendMessage' THEN 5
    ELSE NULL  -- limitsiz aksiyonlar
  END;
$$;

CREATE OR REPLACE FUNCTION private.xp_within_daily_limit()
RETURNS trigger LANGUAGE plpgsql SET search_path = ''
AS $$
DECLARE
  v_limit integer;
  v_count integer;
BEGIN
  v_limit := private.xp_daily_limit(NEW.action);
  IF v_limit IS NULL THEN RETURN NEW; END IF;

  IF NEW.action = 'completeProfile' THEN
    SELECT count(*) INTO v_count FROM public.xp_transactions
      WHERE user_id = NEW.user_id AND action = NEW.action;          -- ömür boyu
  ELSE
    SELECT count(*) INTO v_count FROM public.xp_transactions
      WHERE user_id = NEW.user_id AND action = NEW.action
        AND created_at >= date_trunc('day', now() AT TIME ZONE 'utc'); -- UTC gün
  END IF;

  IF v_count >= v_limit THEN
    RAISE EXCEPTION 'daily XP limit exceeded for action %', NEW.action
      USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_xp_daily_limit ON public.xp_transactions;
CREATE TRIGGER trg_xp_daily_limit
  BEFORE INSERT ON public.xp_transactions
  FOR EACH ROW EXECUTE FUNCTION private.xp_within_daily_limit();
```

- [ ] **2. Client hata yolunu doğrula** — XP yazımı opsiyonel yan etkidir; trigger
  reddi (`PostgrestException`, `check_violation`) primary mutation'ı ASLA geri
  almamalı (breeding-eggs.md yan-etki ilkesi). `GamificationService`/`GamificationRepository`
  çağrı zincirinde catch + `AppLogger.warning` olduğunu test et; yoksa ekle.
- [ ] **3. Canlı simülasyonla doğrula** — dünkü pattern: rollback'li transaction'da
  `SET LOCAL ROLE authenticated` + sahte JWT; aynı gün 2. `dailyLogin` → reject,
  6. `sendMessage` → reject, meşru ilk satırlar → kabul. Ardından `get_advisors`
  (security) → yeni bulgu 0.
- [ ] **4. Prod'a uygula** — MCP `apply_migration` veya `supabase db push`; sonra
  `supabase migration list --linked` senkron kontrolü (otomatik deploy YOK —
  2026-05-29 drift olayını hatırla).
- [ ] **5. Doküman + kalite kapıları + commit:**
  `fix(gamification): enforce daily XP limits server-side via trigger`

### 4.2 OAuth Migration Phase 2'yi tamamla (bir sonraki imzalı release'i bloklar)

**Sorun:** Yeni Google OAuth client ID'leri kodda/`.env.example`'da hazır ama
**local `.env`, Codemagic env group'ları ve GitHub secrets güncellenmedi**. Bu
yapılmadan imzalı release çıkarsa iOS Google Sign-In kırılır (binary rebuild +
~24s store review maliyeti). Kaynak: `.claude/rules/security.md` § Google Sign-In
OAuth Topology (yeni ID değerleri orada).

- [ ] **1.** Local `.env` → `GOOGLE_WEB_CLIENT_ID` + `GOOGLE_IOS_CLIENT_ID` yeni
  değerlere (`720334450619-...`); değerler security.md'de.
- [ ] **2.** Debug build'de gerçek Google Sign-In testi:
  `flutter run --dart-define-from-file=.env` → login + logout + token refresh.
- [ ] **3.** Codemagic env group'ları + GitHub Actions secrets aynı değerlerle
  (dashboard işi).
- [ ] **4.** Release sonrası: eski Web Client ID trafiği 14 gün ~0 olunca legacy
  ID'yi Supabase Auth "Client IDs" listesinden çıkar; `security.md` § Rollout
  state'i her adımda güncelle. Legacy GCP projesini SİLME (sadece OAuth client).

### 4.3 Mesajlaşma delivery-status + failed/retry balonu

**Sorun:** `Message` modelinde durum alanı yok (`lib/data/models/message_model.dart`).
Dünkü fix'lerle başarıda optimistic append + input temizleme var, hatada taslak
korunuyor; ama başarısız mesaj thread'de "gönderilemedi → tekrar dene" balonu olarak
görünmüyor. Kaynak: `.claude/rules/messaging.md` § Delivery Status (tasarım hedefi).

**Dosyalar:** Değiştir `lib/data/models/message_model.dart`, yeni enum
`lib/core/enums/` altına, `lib/features/messaging/widgets/message_input_bar.dart`,
`addLocalMessage`'ın sahibi realtime/thread notifier (`lib/features/messaging/providers/`),
mesaj balonu widget'ı. Test: `test/features/messaging/` mevcut send-path testlerinin yanı.

**Tasarım kararları:**
1. `MessageDeliveryStatus { sending, sent, failed }` **client-only** enum —
   delivered/read zaten `readBy` ile ayrı.
2. Alan JSON'a sızmamalı: `@JsonKey(includeFromJson: false, includeToJson: false)
   @Default(MessageDeliveryStatus.sent) MessageDeliveryStatus deliveryStatus` —
   Supabase şemasına kolon eklenmez.
3. Akış: send tap → `sending` balon + input hemen temizlenir → başarıda `sent`'e
   swap (id dedup mevcut) → hatada `failed` + retry/sil aksiyonu. Retry aynı client
   UUID ile `upsert` → idempotent.
4. Retry butonu `AppIconButton` (48dp + `semanticLabel`); race için `_requestId`
   pattern'i (providers.md).

- [ ] **1.** Testleri önce yaz: send fail → thread'de `failed` mesaj + input'a geri
  yazılmaz; retry başarılı → aynı id tek mesaj `sent`; widget testi: failed balonda
  retry ikonu görünür.
- [ ] **2.** Enum + model alanı → `dart run build_runner build`.
- [ ] **3.** Notifier'a `markFailed(clientId)` / `retry(clientId)`; `addLocalMessage`
  dedup'ını yeniden kullan.
- [ ] **4.** Input bar: anında temizle; hata yönetimi balona taşınır. "Clear only
  on accept" testlerini yeni akışa uyarla.
- [ ] **5.** L10n: `messaging.send_failed`, `messaging.retry` (tr→en→de) +
  `check_l10n_sync.py`.
- [ ] **6.** Kalite kapıları + commit:
  `feat(messaging): client-side delivery status with failed/retry bubble`

---

## 5. P2 Görevleri

### 5.1 Messaging attachment stub'ını gizle (hızlı kazanım)

`message_input_bar.dart:160-182` — "ekle" butonu seçenekleri sadece
`Navigator.pop(context)` yapıyor: kullanıcı tıklıyor, hiçbir şey olmuyor (UX tuzağı).
Gerçek attachment pipeline'ı (10MB guard + moderation + `message-photos` bucket)
ayrı, büyük bir iş (§ 6 backlog).

- [ ] Butonu ve sheet'ini `kDebugMode` arkasına al **veya** tamamen kaldır (widget
  testleriyle birlikte). Kullanılmayan `messagePhotosBucket` sabitine
  (`supabase_constants.dart:173`) "wiring bekliyor" yorumu ekle — sabit kalabilir.
- [ ] `messaging.md` § Attachments'a "buton UI'dan kaldırıldı" notu düş.
- [ ] Commit: `fix(messaging): remove non-functional attachment button stub`

### 5.2 send-push'a server-side quiet hours (DND) enforcement

Client'ta `notification_settings_dnd.dart` ekranı var ama
`supabase/functions/send-push/push_core.ts` DND kontrolü YAPMIYOR — kullanıcının
kapattığı saatte push gidiyor. Kaynak: `.claude/rules/notifications.md` § Quiet Hours.

- [ ] **1.** DND ayarını server'ın okuyabileceği yere taşı: `profiles.notification_preferences`
  JSONB'ine `quiet_hours: {enabled, start, end, tz}` şeması (migration + client yazımı).
- [ ] **2.** `push_core.ts`: token fetch'ten önce hedef kullanıcıların quiet-hours
  penceresini değerlendir; pencere içindeyse kategori `High` değilse **drop** (veya
  erteleme kuyruğu — v1'de drop yeterli, davranışı fonksiyon README'sine yaz).
- [ ] **3.** Deno testleri: pencere içi/dışı, tz sınırı, `enabled: false`, malformed
  pref (fail-open: gönder). CI `edge-functions-test` deploy gate'i zaten var.
- [ ] **4.** `notifications.md` § Quiet Hours'u "server-side enforced" olarak güncelle.
- [ ] Commit: `feat(notifications): enforce quiet hours server-side in send-push`

### 5.3 Community post edit (5 dk window)

`CommunityPostRepository`'de `update` yok; RLS'te 5dk window tasarımı dokümante ama
client akışı hiç yazılmadı. Kaynak: `community.md` § Post Lifecycle.

- [ ] **1.** RLS'i doğrula/ekle: UPDATE policy `author + created_at > now()-'5 min'`
  (+ migration; idempotent `DROP POLICY IF EXISTS`).
- [ ] **2.** Moderation zorunlu: düzenlenen içerik de `create-community-post`'taki
  pipeline'dan geçmeli — mevcut edge function'a `mode: 'update'` desteği eklemek,
  client'tan doğrudan `update` çağrısından daha güvenli (fail-closed korunur).
- [ ] **3.** Repository'ye `update(postId, body)` + remote source endpoint;
  feed/detail provider invalidate; UI'da "Düzenle" (yalnız kendi postu + 5dk içinde,
  `edited` rozeti).
- [ ] **4.** L10n (tr/en/de) + testler (window dışı reject, moderation reject,
  optimistic revert).
- [ ] Commit: `feat(community): post edit within 5-minute window`

### 5.4 Admin moderation queue per-card loading (dünkü ertelenen bulgu)

Tek global loading flag'i tüm kartları kilitleyor; aksiyon alınan kartın spinner'ı
diğerlerini etkilememeli (UX-only, 2026-07-02 second-pass'te deferred).

- [ ] Notifier'da `Set<String> processingIds` state'i; kart butonları yalnız kendi
  id'si işlemdeyken disable + spinner. Widget testi: A kartı işlemdeyken B tıklanabilir.
- [ ] Commit: `fix(admin): per-card loading state in moderation queue`

### 5.5 Calendar hatırlatma offset seçimi

`calendar_form_providers.dart:16` sabit `_kDefaultReminderMinutesBefore = 30`.
Kullanıcı "1 saat önce / 1 gün önce / tam zamanında" seçemiyor (calendar.md'de
dokümante boşluk).

- [ ] Event formuna offset dropdown'u (`0/30dk/1sa/1gün` — `DropdownButtonFormField`
  ile `initialValue:`, anti-pattern #2'ye dikkat); `EventFormNotifier.createEvent`
  parametresi; reminder yeniden planlamada cancel+reschedule pattern'i korunur
  (`NotificationIds.generate()` deterministik).
- [ ] L10n + form testi + provider testi.
- [ ] Commit: `feat(calendar): user-selectable reminder offset`

---

## 6. P3 / Backlog

| # | Kalem | Not |
|---|---|---|
| 6.1 | **Community mute** | Block'un yumuşak versiyonu; `community_social_repository.dart` + feed filtresi + RLS gerekmez (client-side görünürlük). Tasarım: community.md § Block/Mute. |
| 6.2 | **Read-receipt privacy toggle** | `Settings → Messaging`; kapalıysa `read_by` yazma. Karşılıklılık kuralı (kapatanın kendisi de görmesin) ürün kararı ister. |
| 6.3 | **Gamification streak** | Miss-tolerance + 7/30/100 gün bonus (gamification.md tasarımı). 4.1'deki server-side limit altyapısı önkoşul — önce onu bitir. |
| 6.4 | **Server-side kill switch** | `app_config` tablosu + `remoteConfigProvider` (feature-flags.md tasarım hedefi). Realtime rollout ramp'i (%5→%25→%100) da buna bağlı — eski planın P3/16'sı. |
| 6.5 | **Genetics linked-pair faz seçici UI** | İki linked mutasyon seçilince coupling/repulsion'ı netleştiren kontrol/tooltip (genetics.md Anti-Pattern #6, bilinen UX boşluğu). |
| 6.6 | **110 unused index gözden geçirme** | INFO seviyesi. DİKKAT: trigram/`.ilike` index'lerini DÜŞÜRME (2026-05-29 Postgres audit'i — Dart tarafı bunlara bağlı). Aday: gerçekten hiç sorgulanmayan FK-dışı index'ler; 3-6 ayda bir bak. |
| 6.7 | **`private.edge_rate_limits` RLS-no-policy INFO** | Bilinçli deny-all (service_role bypass). Aksiyon yok; istenirse migration'a açıklayıcı `COMMENT ON TABLE` eklenebilir. |
| 6.8 | **Marketing site** | en/de statik lokalizasyon + alt sayfalarda GSAP uyarıları (2026-06-21 audit'inden devreden). |
| 6.9 | **Deprecated feedback alias'ları** | `FeedbackRepository` typedef + eski provider alias'ı (`repository_providers.dart:228`). Çağrı kalmadıysa 2 release kuralına göre sil. |
| 6.10 | **>500 satır dosyalar (4 adet)** | `egg_actions_notifier.dart` (695), `breeding_form_providers.dart` (590), `marketplace_form_screen.dart` (560), `bird_list_screen.dart` (513). Dokunulduğunda sorumluluk bazlı böl (~300 satır hedefi) — drive-by refactor yapma. |
| 6.11 | **Eski plandan devreden** | Sync-conflict banner'ının 2 cihazlı manuel QA senaryosu; performans budget'larının CI assert'e bağlanması; local-ai üretim telemetrisi (token/latency rollup); multi-locale golden kapsamını hot-path widget'lara genişletme; RTL `EdgeInsetsDirectional` migration'ı. |

## 7. Bağımlılık Yükseltme Yol Haritası (fazlı, her faz ayrı commit)

**Faz 1 — Risksiz bump'lar (hemen):** `flutter pub upgrade` ile gelenler:
`sentry_flutter 9.23.0`, `purchases_flutter 10.4.0`, `image_picker 1.2.3`,
`timezone 0.11.1`, `cross_file` vb. → tam kalite kapıları + iOS/Android debug build.
Commit: `chore(deps): patch/minor dependency bumps`.

**Faz 2 — Flutter 3.41.4 → 3.44.x stable:** `flutter upgrade` → `build_runner` →
tam gate + golden'lar (Linux baseline CI'da) + her iki platform build. Bu,
analyzer zincirini açarak **drift 2.34 / drift_dev / json_serializable / riverpod**
yükseltmelerini mümkün kılar (Faz 2b olarak ayrı commit). Xcode Cloud post-clone
simülasyonunu unutma (temiz clone'da `ci_post_clone.sh`).

**Faz 3 — Pinli paketleri yeniden dene (ayrı branch'te):**
- `supabase_flutter <2.13.0` pini: 2.15.3'ü branch'te dene; sorun passkeys →
  `device_info_plus 12.4.0` (visionOS selector, iOS CI'da kırılıyor, lokalde
  görünmüyor) — kanıt: `pubspec.lock` + `ios/Podfile.lock` + analyze/test +
  **Xcode Cloud/CI iOS build** yeşil olmadan merge etme (memory: supabase_flutter iOS cap).
- `connectivity_plus <7.1.0` pini: CI Xcode'u iOS 26 SDK'ya geçince aç
  (pubspec'teki pin yorumu güncel tutulsun).

**Faz 4 — Yapısal:** `sqlite3_flutter_libs 0.6.0+eol` → paket EOL; drift'in önerdiği
yeni native yükleme yoluna geçiş planı (drift 2.34 sonrası, drift dokümantasyonundaki
migration rehberiyle). `share_plus 12→13`, `package_info_plus 9→10` major'ları
changelog okuyarak tek tek.

Kural: her fazda `pubspec.lock` + `ios/Podfile.lock` birlikte commit; bump sonrası
`flutter pub get` lockfile diff'i CI'a yansımalı (ci-actions.md).

## 8. Kalite Kapıları (her görev sonrası)

```bash
scripts/run_local_quality_gate.sh        # kanonik giriş
flutter analyze --no-fatal-infos         # 0 error
flutter test                             # ilgili suite + tam paket (push öncesi)
python3 scripts/check_l10n_sync.py       # l10n dokunulduysa
python3 scripts/verify_rules.py --fix    # stats drift'i varsa, sonra --strict
python3 scripts/check_remote_status.py   # push sonrası exact SHA doğrulaması
```

Migration içeren görevlerde ek olarak: staging doğrulaması → prod apply →
`supabase migration list --linked` → `get_advisors` (security) temiz.

## 9. Eski Planın (2026-05-17) Kapanış Durumu

Bugünkü ölçümlerle doğrulandı: **P0/1** ProviderContainer dispose ✅ (checker aktif, 0
sorun) · **P0/2** IconButton 48dp ✅ (checker aktif) · **P0/3** Sentry kapsaması ✅
(sonraki audit'lerde tamamlandı) · **P1/4** insert→upsert ✅ (checker "0 sorun") ·
**P1/5** Drift index'leri ✅ (`app_database_indexes.dart`) · **P1/8** katman sızıntısı ✅
(Layer checker 0) · **P2/9** JWT posture ✅ (`verify_security.py` 37/37) · **P2/14**
memCacheWidth ✅ (checker) · **P3/18** cert pinning ✅ (aktif + rotation prosedürü).
Başarı kriteri "checker 24→27" karşılandı. Kapanmayan kalemler § 6.10-6.11'e taşındı.

---

*Bu plan 2026-07-03 incelemesinin çıktısıdır: tüm kalite kapıları + 11.912 test +
canlı Supabase advisor'ları + 2 paralel keşif ajanı (teknik borç envanteri; 12
dokümante açığın dosya-kanıtlı doğrulaması). Statik/dokümante bulgulara dayanır;
runtime profiling (DevTools, Sentry performance) ayrıca değerlendirilmelidir.*

