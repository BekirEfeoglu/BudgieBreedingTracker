# BudgieBreedingTracker — İyileştirme Planı

**Tarih:** 2026-05-17
**Kapsam:** lib/ (975 dosya), test/ (896 dosya), supabase/ (156 migration), 25 feature modülü
**Mevcut durum:** `flutter analyze` 0 issue · `verify_code_quality.py` 0 violation · l10n 3 dil senkron · 24 anti-pattern checker temiz

Genel kod sağlığı yüksek. Plan, statik tarayıcıların yakalamadığı **sistemik riskleri** ve **performans/sürdürülebilirlik kazanımlarını** önceliklendirir.

---

## P0 — Acil / Risk (Bu sprint)

### 1. Test ProviderContainer leak'i (kritik)
- **Bulgu:** 667 `ProviderContainer(...)` oluşturuluyor, **sıfır** `addTearDown(container.dispose)` çağrısı tespit edildi. `test-stability.md` zorunlu kuralı ihlal ediliyor (2026-04-17 audit'inde 644 leak'ten arınıldığı raporlanmıştı — regression).
- **Risk:** CI'da test memory growth, paralel runner OOM, intermittent flaky failure.
- **Aksiyon:**
  1. `scripts/verify_code_quality.py` içindeki `check_provider_container_dispose` checker'ının **gerçekten çalıştığını** doğrula (warning → error seviyesine çek).
  2. Tek seferlik codemod ile her `ProviderContainer(...)` sonrası `addTearDown(container.dispose)` ekle.
  3. CI `code-quality` job'unda bu kuralı **blocking** yap.
- **Çıktı:** PR `test: enforce ProviderContainer disposal across suite`

### 2. IconButton 48dp tap-target eksiği (a11y release-blocker)
- **Bulgu:** 73 `IconButton` kullanımı, sadece **2 tanesi** `BoxConstraints(minWidth: 48, minHeight: 48)` ile sarılmış. `accessibility.md` WCAG 2.5.5 zorunlu.
- **Risk:** App Store/Play accessibility audit reddi, yaşlı kuşbaz hedef kitlesinde kullanılamazlık.
- **Aksiyon:**
  1. `scripts/verify_code_quality.py`'a `check_iconbutton_constraints` checker'ı ekle (audit-flagged listede zaten var, statik tarayıcıya bağla).
  2. Tek codemod ile tüm `IconButton` çağrılarını `constraints: const BoxConstraints(minWidth: 48, minHeight: 48)` ile sar.
  3. Tooltip eksik olanları da bu pass'te yakala (`Semantics.label` zorunluluğu).
- **Çıktı:** PR `feat(a11y): enforce 48dp tap targets on all IconButtons`

### 3. Sentry kaplaması eksik kritik path'ler
- **Bulgu:** 83 `Sentry.captureException` vs **15+** bare `catch (e)` (Sentry yok). Etkilenen kritik dosyalar:
  - `lib/bootstrap.dart:306` — startup hatası sessiz
  - `lib/app.dart:156, 164` — global error path
  - `lib/features/.../backup_screen.dart:177, 217` — yedekleme hatası
  - `lib/features/.../privacy_security_section.dart:107, 171` — auth/MFA path
- **Risk:** Üretim hataları görünmez, regression triage imkânsız.
- **Aksiyon:** `observability.md` § "Sentry'ye GİDEN olaylar" listesine göre her kritik catch'i `AppLogger.error(..., e, st)` + `Sentry.captureException(e, stackTrace: st)` ile sar.
- **Çıktı:** PR `fix(observability): instrument critical catch blocks with Sentry`

---

## P1 — Yapısal Borç (Önümüzdeki 2-3 sprint)

### 4. `insert()` → `upsert()` idempotency tutarsızlığı
- **Bulgu:** Remote source'larda `.upsert()` yaygın ama bazı repository'lerde hâlâ `.insert()` aktif. `data-layer.md` § Write Safety zorunlu kılıyor; retry/sync replay duplicate üretebilir.
- **Aksiyon:**
  1. `grep -rn "\.insert(" lib/data/remote --include="*.dart"` ile tüm `.insert()` çağrılarını listele.
  2. Her birini `.upsert(..., onConflict: 'id')` haline çevir.
  3. `verify_code_quality.py`'a `check_remote_insert_usage` checker ekle.
- **Risk:** Sync replay sonrası duplicate row, offline-first user'da veri tutarsızlığı.

### 5. Drift index eksikliği (sorgu performansı)
- **Bulgu:** Tablolarda yalnızca primary key index var. `userId`, `entityId`, `breedingPairId`, `eggId` gibi sık filtrelenen sütunlarda **index yok** (20 tablo).
- **Aksiyon:**
  1. DAO'larda `.where((t) => t.userId.equals(...))` veya FK sütun filter'larını listele.
  2. `app_database.dart` `onUpgrade` v22 → v23: ilgili `CREATE INDEX` SQL'lerini ekle.
  3. Performans budget'a göre query timing log'la (`performance.md` § budget < 20ms p50).
- **Beklenen kazanım:** 100+ kayıtlı tablolarda %30-70 query süresi düşüşü.

### 6. `ref.watch` rebuild scope optimizasyonu
- **Bulgu:** 644 `ref.watch` çağrısı, sadece 56 `.select()` (oran 11:1). Geniş watch'lar gereksiz rebuild tetikliyor.
- **Aksiyon:**
  1. `bird_list_screen.dart`, `home_screen.dart`, `breeding_*_screen.dart` gibi hot path'lerde `.select()` audit'i.
  2. Profile flow'u `Theme.of(context)`'i dinleyen ama gerçekte alt-field kullanan widget'larda `.select()` zorunlu.
  3. Code review checklist'ine ekle (`code-review.md` § Performans).
- **Beklenen kazanım:** List scroll FPS, form input latency.

### 7. Büyük dosya refactor (sürdürülebilirlik)
- **Bulgu:** 7 dosya >500 satır:
  - `local_ai_service.dart` (732) — backend routing + cache + prompt + parsing tek yerde
  - `admin_users_providers.dart` (628) — admin user CRUD + filter + bulk action
  - `bird_list_screen.dart` (614) — list + filter + sort + search UI hepsi tek widget
  - `community_feed_guides.dart` (558), `community_guidelines_view.dart` (540)
  - `marketplace_form_screen.dart` (539), `admin_settings_content.dart` (508)
- **Aksiyon:** Her dosyayı sorumluluk bazlı 2-3 dosyaya böl. `coding-standards.md` § File Organization "max ~300 lines" hedefi.
- **Öncelik:** `local_ai_service.dart` (backend abstraction + cache + redaction ayrı sınıflar), `bird_list_screen.dart` (filter/sort/search widget extraction).

### 8. Domain → Features ters import (katman sızıntısı)
- **Bulgu:** `home_widget_service.dart:4` `features/home/providers/home_providers.dart`'tan import ediyor (`HomeWidgetDashboardSnapshot` model'i features'da, ama domain servisi tüketiyor).
- **Aksiyon:** Model'i `lib/data/models/home_widget_dashboard_snapshot.dart`'a taşı, features ve domain her ikisi de data'dan import etsin.
- **Risk:** Architecture.md import kuralı ihlali, gelecekte cycle riski.

---

## P2 — Kalite & Operasyon (Backlog)

### 9. Edge Function JWT verify smoke check
- **Bulgu:** `supabase/functions` ve workflow'larda `--no-verify-jwt` veya `verify_jwt` referansı bulunamadı (audit-blocker'ın yokluğunu **doğrulamak** gerekli).
- **Aksiyon:** Her edge function `index.ts` başında `Deno.env`'den JWT verify default'unu açıkça assert eden helper kullan. CI'da statik check.

### 10. Drift FK constraint & composite index dokümantasyonu
- **Bulgu:** 20 tabloda FK ilişkileri var ama composite index / cascade rule'ları wiki'de yok.
- **Aksiyon:** `data-layer/tables-catalog.md` (obsidian wiki) altına FK parent → child grafiği + cascade policy.

### 11. Sync conflict UI banner gerçek hayatta görünüyor mu?
- **Bulgu:** `conflictNotifierProvider` ve `lastPullConflicts` mekanizması kodda var ama gerçek bir conflict senaryosunda banner test edilmemiş.
- **Aksiyon:** Manual QA senaryosu: iki cihazdan offline edit → online → conflict çözümü banner'ı.

### 12. Performance budget'ların CI'a bağlanması
- **Bulgu:** `performance.md` § budget table tanımlı ama regression detection manuel.
- **Aksiyon:** Drift query'lerde `AppLogger.warning` budget aşımında otomatik (zaten patternde var), CI'da test fixture ile assert et (`expect(elapsedMs, lessThan(20))`).

### 13. `local-ai` cost guard production telemetrisi
- **Bulgu:** Token usage, latency, fallback chain hit-rate üretimde izlenmiyor (sadece debug log).
- **Aksiyon:** Sentry custom metric veya basit `app_metrics` Supabase table'ına günlük rollup.

### 14. CachedNetworkImage `memCacheWidth/Height` zorlaması
- **Bulgu:** `CachedNetworkImage` yaygın ama list item'larda `memCacheWidth` set edilmiyor — full-res decode memory'i şişirir.
- **Aksiyon:** Shared `BirdAvatar`, `MarketplaceListingImage` widget'larında `memCacheWidth` zorunlu prop.

### 15. Test golden multi-locale eksik
- **Bulgu:** `test-stability.md` § Multi-Locale Golden 3 dil için snapshot öneriyor, mevcut golden test'lerin çoğunluğu tek locale.
- **Aksiyon:** Hot path widget'lar (`BirdCard`, `EggCard`, `BreedingPairCard`, formlar) için tr/en/de golden — Almanca overflow yakalamak için.

---

## P3 — Stratejik / Uzun Vadeli

### 16. Realtime sync subscription rollout
- `feature_flags.md` § `syncRealtimeEnabledProvider` default `false`. Production'da %5 → %25 → %100 ramp planı yok.
- **Aksiyon:** Server-side kill switch + remote config % ramp altyapısı.

### 17. RTL / yeni dil hazırlığı
- `accessibility.md` § RTL Hazırlığı önerileri var ama `EdgeInsetsDirectional` audit'i yapılmamış.
- **Aksiyon:** `EdgeInsets.only(left:|right:)` → `EdgeInsetsDirectional.only(start:|end:)` migration.

### 18. Certificate pinning değerlendirmesi
- `security.md` § Certificate Pinning şu an pasif. Rotation prosedürü olmadan eklenmemeli ama değerlendirme zamanı.

### 19. Background sync iOS güvenilirliği
- `BGTaskScheduler` 30s window'da kritik sync garanti edilemiyor. Foreground sync yeterli mi metrikle ölç.

---

## Uygulama Sırası (Önerilen)

| Sprint | Hedef |
|--------|-------|
| Sprint N | P0/1 + P0/2 + P0/3 (3 PR) |
| Sprint N+1 | P1/4 + P1/5 (insert→upsert + Drift index → schema v23) |
| Sprint N+2 | P1/6 + P1/7 (ref.watch select + büyük dosya refactor) |
| Sprint N+3 | P1/8 + P2/9 + P2/10 |
| Backlog | P2/11–15, P3/16–19 |

## Başarı Kriterleri
- `verify_code_quality.py` checker sayısı 24 → 27 (ProviderContainer dispose + IconButton constraints + insert-vs-upsert)
- `Sentry.captureException` kapsaması bare catch'lere göre **>95%**
- Drift query p99 < 50ms (CI test fixture ile assert)
- 500+ satır dosya sayısı 7 → 0
- A11y golden test'leri 3 dil için yeşil

---

## Notlar
- Bu plan **statik analiz + grep tabanlı** bulguları yansıtır; runtime profiling (DevTools timeline, Sentry performance) ile doğrulanmalı.
- Her PR `branch-workflow.md` main-only akışına uymalı; CI quality gate'lerini (ai-workflow.md § Quality Gates) tetiklemeli.
- 2026-04-19 audit kapsamında 9/10 item kapatılmış — bu plan onun ardından kalan **strukturel** maddeleri önceliklendirir, regression'ları (özellikle #1 test leak) hızlı kapatır.
