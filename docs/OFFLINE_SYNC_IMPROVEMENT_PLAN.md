# Offline-First Sync — İyileştirme ve Geliştirme Planı

> **Tarih:** 2026-05-16
> **Kapsam:** `lib/domain/services/sync/`, `lib/data/repositories/`, syncable entity repository'leri, UI sync feedback
> **Hedef:** Offline-first sistemini production-grade'den "best-in-class"a taşımak — background sync, realtime, global offline UX, gözlemlenebilirlik

---

## 1. Mevcut Durum (Audit Özeti)

### Güçlü Yanlar (korunacak)
- **Mimari:** `SyncOrchestrator` → `SyncPushHandler` / `SyncPullHandler` katmanlı yapı; FK bağımlılık zinciri (`sync_push_handler_table.dart`) açık.
- **Repository sözleşmesi:** `BaseRepository<T>` + `SyncableRepository<T>` + `ValidatedSyncMixin<T>` — 16 syncable entity, 7 online-first exempt (community/messaging/marketplace/gamification).
- **Idempotency:** UUID v7 client-side, tüm push'lar `upsert` (`bird_repository.dart:163` ve eş muadiller).
- **Connectivity:** `connectivity_plus` + DNS lookup (`dns.google`, 3s) ile captive portal yakalama (`network_status_provider.dart`).
- **Conflict tracking:** `lastPullConflicts` + `ConflictHistoryDao` (FIFO 50, 30 gün retention) — last-write-wins server side.
- **Retry:** Exponential backoff `30 * 2^retryCount + ±20% jitter`, max 10 dk cap, 5 attempt sonra unrecoverable (`retry_scheduler.dart`).
- **Persistence:** `SyncMetadata` Drift tablosu, app restart'a dayanıklı.
- **Test:** ~27 sync test dosyası, ~5.7K satır (orchestrator, push/pull, retry, conflict, orphan cleanup).

### Kapatılması Gereken Boşluklar
| # | Boşluk | Etki | Öncelik |
|---|--------|------|---------|
| G1 | **Background sync yok** (WorkManager / BGTaskScheduler) — app kapalıysa hiçbir şey senkronize olmaz | Yüksek — uzun süre offline kullanıcılar gecikmiş veri yansıması yaşar | P0 |
| G2 | **Realtime subscription yok** — multi-device kullanıcı 15 dk pencerede stale veri görür | Yüksek — collaboration UX'ini bozar | P1 |
| G3 | **Global `OfflineBanner` yok** — sync hata/offline durumu sadece profil ekranında görünür | Orta — kullanıcı yazma kaybı endişesi yaşar | P0 |
| G4 | **Stale error silmeden önce uyarı yok** — 24h sonra silinen unrecoverable kayıt için kullanıcıya bildirim yok | Orta — sessiz veri kaybı ihtimali | P1 |
| G5 | **Conflict UI sadece history** — etkilenen entity ekranında görsel işaret yok | Orta — kullanıcı kaybedilen edit'inden haberdar olmayabilir | P1 |
| G6 | **Max retry 5 sabit**, kısa network kesintilerinde tükenebilir | Düşük — manuel force sync zaten var | P2 |
| G7 | **Sync observability dar** — Sentry breadcrumb var ama structured event metriği (retry success rate, conflict frequency, offline duration) yok | Düşük — ileri triage zor | P2 |
| G8 | **Realtime saat farkı (clock skew)** durumunda sessiz tam reconcile — log seviyesi info, kullanıcıya görünmez | Düşük | P2 |
| G9 | **Differential / partial sync yok** — değişen entity'nin tamamı pull edilir (büyük foto URL'leri dahil) | Düşük → orta (data volume büyürse) | P3 |

---

## 2. Yol Haritası

### Faz 0 — Ön hazırlık (1 gün)
- [ ] `docs/OFFLINE_SYNC_IMPROVEMENT_PLAN.md` (bu doküman) review + paydaş onayı (solo dev → kendine onay)
- [ ] Mevcut sync metric'leri için baseline ölç (manuel telemetri): 7 gün boyunca p50/p99 sync süresi, retry oranı, conflict sayısı — gelecek karşılaştırma için
- [ ] Feature flag tanımları (`feature-flags.md` lifecycle):
  - `sync_background_enabled` (runtime kill switch)
  - `sync_realtime_enabled` (runtime, entity bazlı: `breeding_pairs`, `clutches`, `eggs`)
  - `sync_offline_banner_enabled` (runtime, kademeli rollout)

### Faz 1 — Hızlı kazanımlar (3–5 gün) [P0]

#### 1.1 Global `OfflineBanner` (G3)
- **Konum:** `lib/core/widgets/offline_banner.dart` — yeni shared widget
- **Bağlam:** `Scaffold` üzerinde global wrapper (router'da root shell)
- **Davranış:**
  - `networkStatusProvider` + `syncErrorProvider` izle
  - Offline → "Çevrimdışı — değişiklikleriniz kaydedildi" (sarı banner)
  - Sync error + online → "Senkronizasyon başarısız — yeniden dene" + retry button
  - Geri online → 2s "Senkronize edildi" toast, sonra kaybol
- **L10n keys:** `sync.offline_banner`, `sync.error_banner`, `sync.reconnected_toast`
- **Test:** Widget test 3 state için + 3 dil (tr/en/de) overflow golden
- **Accessibility:** `Semantics.label`, banner 48dp min height, retry button 48dp tap target

#### 1.2 Stale error pre-deletion warning (G4)
- **Konum:** `retry_scheduler.dart` — `cleanupStaleErrors` öncesi 20h marker
- **Davranış:**
  - 20h üzeri + retryCount ≥ 5 → `pendingDeletionProvider` listesine ekle
  - Kullanıcıya in-app banner: "X kayıt 4 saat içinde silinecek, manuel sync deneyin"
  - Tıklanırsa `forceFullSync()` çağır
  - 24h'ta hâlâ fail ise sil + Sentry warn (mevcut davranış)
- **Test:** `retry_scheduler_test.dart` yeni timeline test'i

#### 1.3 Max retry + backoff tuning (G6)
- **Değişiklik:** `RetryScheduler` — max 5 → 7, base 30s → 45s, jitter 20% kalsın
- **Gerekçe:** Tipik mobil kesintiler 5–15 dk; 7 retry × backoff ≈ 95 dk kapsama
- **Test:** Backoff tablosu doğrulama

#### 1.4 Conflict UI badge (G5 kısmi)
- **Konum:** Etkilenen entity list/detail screens (birds, eggs, breeding pairs ilk dalga)
- **Davranış:** `conflictHistoryProvider` üzerinden `entityId` eşleşmesi var mı kontrol et; varsa kart üzerinde küçük "⚠ çakışma — incele" rozeti
- **Tap action:** `sync_detail_sheet.dart` aç + ilgili kaydı highlight et
- **L10n:** `sync.conflict_badge`, `sync.conflict_detail_title`

**Faz 1 çıktı:** Kullanıcı offline durumunu her ekranda görüyor, veri kaybı ihtimallerinden önceden haberdar oluyor, çakışmaları noktasal görüyor.

---

### Faz 2 — Background & realtime (1–2 hafta) [P1]

#### 2.1 Background sync (G1)
- **Paket:** `workmanager: ^0.5.x` (Android + iOS unified API)
- **Android:** `WorkManager` periodic 15 dk + constraint `NetworkType.CONNECTED` + `requiresBatteryNotLow: true`
- **iOS:** `BGTaskScheduler` — `BGAppRefreshTask` (opportunistic, 30s budget); `Info.plist`'e `BGTaskSchedulerPermittedIdentifiers` ekle
- **Logic:**
  - Background task → `syncOrchestratorProvider.pushChanges()` (sadece push, pull yok — battery + cost)
  - Auth token expired ise sessizce başarısız ol (kullanıcı login açtığında foreground sync devralır)
  - Max çalışma süresi guard (iOS 30s, Android 10dk)
- **Feature flag:** `sync_background_enabled` ile kill switch (`feature-flags.md`)
- **Observability:** Her background run için Sentry breadcrumb + AppLogger
- **Test:**
  - Unit: handler doğru sync metoduyla başlatıyor
  - Manual QA: TestFlight + Play internal — battery + termination senaryoları
- **Risk:** iOS background task'ı opportunistic — garanti çalışma yok; doc'ta açıkça belirt

#### 2.2 Realtime subscriptions (G2)
- **Kapsam (faz 2.2):** `breeding_pairs`, `clutches`, `eggs` — multi-device collaboration için kritik tablolar
- **API:** Supabase `channel().on('postgres_changes', ...)` — RLS otomatik filtrele
- **Davranış:**
  - App foreground + online ise subscribe
  - INSERT/UPDATE event geldiğinde → ilgili entity'yi pull (tek kayıt, full table değil)
  - DELETE event → local soft delete + provider invalidate
  - Background veya offline'a düşünce unsubscribe
- **Conflict:** Local dirty kayıt varsa mevcut conflict path'i kullan (pull sırasında zaten ele alınır)
- **Feature flag:** `sync_realtime_enabled` runtime toggle + entity-level allowlist
- **Cost:** Supabase realtime free tier limit'i kontrol; rate limit log'la
- **Test:**
  - Unit: subscription lifecycle (connect/disconnect/error)
  - Integration: 2 device simülasyon (test'te mock channel)
- **Risk:** Realtime SDK reconnection — exponential backoff, 5 fail sonra polling'e geri dön

#### 2.3 Sync detail sheet iyileştirmesi
- Çakışmaya tıklandığında "remote versiyonu uygula" / "local versiyonu geri yükle" (last-write-wins override)
- Conflict timeline (kim ne zaman değiştirdi) — `updated_at` + device metadata

**Faz 2 çıktı:** App kapalı olsa bile veri akıyor; multi-device kullanıcı 15 dk değil saniyeler içinde görüyor; çakışmada kullanıcı tarafı override edebiliyor.

---

### Faz 3 — Observability & polish (1 hafta) [P2]

#### 3.1 Structured sync events (G7)
- **Konum:** `AppLogger` tag `sync` + Sentry tag map
- **Events:**
  - `sync_started` (trigger: periodic/resume/network/manual)
  - `sync_completed` (duration_ms, pushed_count, pulled_count, conflicts_count)
  - `sync_failed` (phase: push/pull, error_code, retry_count)
  - `conflict_resolved` (entity_type, resolution: server_won/user_override)
  - `background_sync_run` (platform, success, duration_ms)
- **Sentry sample:** %10 production, %100 staging (mevcut budget'a uyumlu)
- **Dashboard:** Sentry'de saved query — retry success rate haftalık trend

#### 3.2 Clock skew kullanıcı bildirimi (G8)
- `sync_pull_handler.dart` clock skew tespit ettiğinde tek seferlik banner: "Cihaz saatiniz hatalı olabilir, lütfen kontrol edin"
- L10n: `sync.clock_skew_warning`
- Test: mock device clock future → banner gösterilir

#### 3.3 Sync settings UX
- Settings → "Senkronizasyon" sayfası:
  - Manuel sync button (mevcut)
  - Background sync toggle (G1 ile birlikte)
  - Realtime toggle (per-feature)
  - Last sync time + retry queue boyutu
  - "Hata kayıtlarını temizle" (advanced, confirm dialog)

#### 3.4 Test gap kapama
- Network fault injection test'i (`MockClient` ile flaky network)
- Conflict storm test'i (50+ paralel conflict)
- Background sync handler unit test (workmanager mock)

---

### Faz 4 — Stratejik (opsiyonel, 2–4 hafta) [P3]

#### 4.1 Differential sync (G9)
- **Strateji:** Server-side RPC `sync_delta(user_id, table, since_timestamp)` — sadece değişen satırları döndür
- **Migration:** Supabase fonksiyon + edge function değil (basit RPC yeterli)
- **Client:** Pull handler `since=lastPulledAt` parametresi ile çağır
- **Kazanım:** Foto URL'leri ve büyük JSON field'ları için bandwidth tasarrufu

#### 4.2 Field-level merge (3-way)
- Sadece text field'lar için (notlar, açıklamalar)
- Local + remote + common ancestor (last server snapshot) ile basic 3-way
- Conflict UI'da diff göster, kullanıcı seçsin

#### 4.3 Sync analytics dashboard
- Admin panelinde sync sağlığı:
  - Toplam kullanıcı / aktif sync sayısı
  - p50/p99 sync süresi
  - Retry başarı oranı
  - Conflict trend (haftalık)
- Veri kaynağı: structured sync events → Supabase aggregate

---

## 3. Anti-Pattern Sınırları (Yapılmayacaklar)

Yeni kod ekleme sırasında ihlal edilmemesi gereken kurallar (`data-layer.md`, `background-sync.md`):

1. `.insert()` kullanma → `.upsert()` zorunlu (idempotency #G)
2. FK parent'lı sync repo `ValidatedSyncMixin` olmadan eklenemez
3. Background sync handler içinde UI çağrısı yok (BuildContext yok)
4. Realtime payload'ı direkt UI provider'a yazma — pull handler'dan geçir (conflict path korunsun)
5. Sentry'ye PII (kuş adı OK, kullanıcı email/full name NO)
6. Stale error silme öncesi kullanıcı bildirimi atlanamaz (G4)
7. Realtime subscription auth'sız bırakılamaz — JWT refresh akışına bağla
8. Background sync battery-not-low ve charging constraint'i ihlal etme

---

## 4. Test Stratejisi Özeti

| Faz | Yeni unit | Yeni widget | Yeni integration | Manual QA |
|-----|-----------|-------------|------------------|-----------|
| 1 | OfflineBanner state'leri, stale error timer, max retry tuning | OfflineBanner 3-state + 3-locale golden, conflict badge | — | Offline/online toggle akışı |
| 2 | WorkManager handler, BGTask handler, realtime channel lifecycle | Sync settings toggle UI | 2-device realtime conflict | TestFlight + Play internal background termination |
| 3 | Structured event emit assertion, clock skew banner | Sync settings page golden | Network fault sim | — |
| 4 | Delta RPC client, 3-way merge resolver | Diff viewer | Differential pull e2e | Production canary |

Tüm yeni test'ler:
- `addTearDown(container.dispose)` zorunlu (`test-stability.md`)
- `pumpAndSettle` infinite animation'a karşı korumalı
- Mock'lar `test/helpers/mocks.dart`'a eklensin

---

## 5. Rollout & Kill Switch Stratejisi

| Faz | Rollout | Kill switch |
|-----|---------|-------------|
| 1.1 OfflineBanner | %100 (low risk) | `sync_offline_banner_enabled` |
| 1.2 Stale warning | %100 | — (kapatılamaz, safety net) |
| 1.3 Retry tuning | %100 | hardcoded → revert PR ile |
| 1.4 Conflict badge | %100 | conflict_badge_enabled |
| 2.1 Background sync | %10 → %50 → %100 (haftalık) | `sync_background_enabled` |
| 2.2 Realtime | Entity bazlı allowlist, %10 → %100 | `sync_realtime_enabled` + entity list |
| 3.x Observability | %100 (read-only) | Sentry sample rate |
| 4.x Stratejik | Beta dev menüsü → opt-in → genel | `experimental_*` flags |

Her faz sonrası 1 hafta gözlem; Sentry error rate %0.5 üstüne çıkarsa kill switch çek + post-mortem.

---

## 6. Tahmini Efor & Sıralama

| Faz | Süre | Risk | Bağımlılık |
|-----|------|------|------------|
| 0 | 1 gün | Düşük | — |
| 1 | 3–5 gün | Düşük | Faz 0 |
| 2 | 7–10 gün | Orta (iOS background sınırlı garanti) | Faz 1 (banner ile feedback şart) |
| 3 | 5 gün | Düşük | Faz 2 (event'ler 2'de doğar) |
| 4 | 10–20 gün | Orta-yüksek (server fonksiyonu + migration) | Faz 3 (metric ile karar) |

**Toplam minimum viable (Faz 0–3): ~3 hafta solo dev.**

---

## 7. Uygulama Durumu (2026-05-16)

- Faz 0–1 başlatıldı: plan dokümanı repo kapsamına alındı, global `OfflineBanner`, retry tuning, stale error pre-warning ve record-level conflict badge altyapısı eklendi.
- Faz 2 kısmen uygulandı: `workmanager` tabanlı background sync servisi eklendi. Kill switch varsayılan kapalıdır; task sadece pending push yapar, pull yapmaz.
- Faz 2 realtime kısmı kısmen uygulandı: foreground-only `RealtimeSyncService` eklendi. İlk allowlist `breeding_pairs`, `clutches`, `eggs`; eventler UI state'e direkt yazılmaz, mevcut pull path üzerinden reconcile edilir.
- Faz 3 başlatıldı: `SyncTelemetry` event helper'ı ve clock skew warning provider/UI yüzeyi eklendi. PII filtrelemesi helper seviyesinde yapılır.
- Faz 4 bilinçli olarak açılmadı: differential sync/RPC çalışması, Faz 3 telemetry verisi ve payload/bandwidth ölçümü olmadan başlanmayacak. Mevcut client zaten `lastSyncedAt` ile incremental pull kullanır; server-side delta RPC ayrı migration ve canary gerektirir.

---

## 7. Başarı Kriterleri

- **Kullanıcı algısı:** "Sync hâlâ çalışıyor mu?" sorusunun in-app yanıtı her zaman görünür → OfflineBanner + sync tile yeterli sinyal
- **Veri kaybı:** Stale cleanup öncesi kullanıcıya bildirilen kayıt oranı %100 (G4)
- **Latency:** Multi-device aynı hesap görünürlük süresi 15 dk → <5 saniye (G2)
- **Resilience:** App 24h kapalı kalsa bile reconnect sonrası 5 dk içinde tam sync (G1 + retry)
- **Observability:** Conflict ve retry trendleri Sentry'de izlenebilir (G7)
- **Test:** Sync coverage %80+ kalır, yeni path'ler için yeni test zorunlu
- **Regression:** Mevcut 27 sync test'i kırılmaz; CI yeşil kalır

---

## 8. Açık Sorular / Karar Noktaları

1. **Realtime maliyeti:** Supabase free tier realtime connection limiti? Production'da paid tier gerekli mi?
2. **Background sync battery policy:** Charging-only zorla mı, opt-in mi? (kullanıcı tercihi olmalı)
3. **Conflict UI severity:** Tüm conflict eşit mi gösterilsin yoksa "kritik field" (örn. egg status) ayrı renk mi?
4. **Differential sync ROI:** Bandwidth ölçümü Faz 3 sonrası — gerçek veri olmadan Faz 4 başlatma
5. **Realtime ↔ background sync etkileşimi:** Background'da realtime gerekli mi yoksa sadece foreground'da mı? (battery için: sadece foreground)

---

## 9. İlgili Kural Dosyaları

- `.claude/rules/background-sync.md` — sync sözleşmesi (güncellenecek: background task + realtime bölümü)
- `.claude/rules/data-layer.md` — upsert/idempotency/ValidatedSyncMixin
- `.claude/rules/observability.md` — Sentry tag konvansiyonu (faz 3 event'leri eklenecek)
- `.claude/rules/feature-flags.md` — sync_background, sync_realtime, offline_banner flag lifecycle
- `.claude/rules/empty-loading-error-states.md` — OfflineBanner shared widget catalog'a girecek
- `.claude/rules/accessibility.md` — banner + badge 48dp + semantic label
- `.claude/rules/notifications.md` — stale cleanup local notification kanalı
- `.claude/rules/edge-functions.md` — Faz 4 delta RPC eklendiğinde

---

## 10. Sonraki Adım

1. Bu planı oku, Faz 1 scope'unu onayla
2. Faz 0 baseline metric'leri için manuel test çalıştır (7 gün)
3. Faz 1 implementation'ı yeni branch'te aç: `feature/offline-banner` → ilk PR
4. Her faz sonu bu dokümana ✅ işaretle, deviation varsa not düş
