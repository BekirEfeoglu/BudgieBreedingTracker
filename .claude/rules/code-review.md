# Code Review

PR review checklist'i. Her PR yazarı kendi PR'ını bu listeyle gözden geçirmeli; reviewer aynı listeyle onaylar.

## Self-Review (PR Açmadan Önce)

### Kalite Kapıları
Tümü local'de geçmeli (CI tekrar koşar):
```bash
flutter analyze --no-fatal-infos
python3 scripts/verify_code_quality.py
python3 scripts/check_l10n_sync.py
python3 scripts/verify_rules.py --strict
flutter test
```
Stats veya inline rule referans drift'i varsa önce `python3 scripts/verify_rules.py --fix`, sonra `--strict` çalıştır.
Detaylı liste: ai-workflow.md § Quality Gates (canonical).

### Diff Sanity
- [ ] Sadece task scope'u değişti — drive-by refactor yok
- [ ] Generated dosyalar (`.g.dart`, `.freezed.dart`) commit edildi
- [ ] `dart run build_runner build` çalıştırıldı
- [ ] Geçici debug kodu kaldırıldı (`AppLogger.debug` izleri, `print`, comment'li kod)
- [ ] Dosya sonu newline + trailing whitespace temiz
- [ ] Conflict marker yok (`<<<<<<<`)

## Reviewer Checklist

### 1. Mimari & Katman
- [ ] Feature → Feature import yok (cross-feature drift)
- [ ] UI'dan `client.from()` çağrısı yok (admin/ hariç)
- [ ] Repository → DAO + RemoteSource yapısı korunmuş
- [ ] Yeni `*Repository` offline-first mi? Drift table + DAO + SyncMetadata var mı?
- [ ] Online-only ise `*RemoteService` / `*OnlineSource` adı kullanılıyor mu? (data-layer.md)
- [ ] Yeni shared widget gerekiyor mu, yoksa mevcut biri mi? (`lib/core/widgets/`)
- [ ] Üreme/Yumurta değişikliği varsa lifecycle, rollback, bildirim/takvim yan etkileri `breeding-eggs.md` ile uyumlu mu?

### 2. Anti-Pattern Taraması
24 kuralın spot-check'i:
- [ ] `withValues(alpha:)` kullanılmış (`.withOpacity()` yok)
- [ ] `ref.watch()` callback içinde değil
- [ ] `setState` async sonrası `mounted` kontrolü
- [ ] `context.push()` ileri navigation'da
- [ ] `AppIcon(AppIcons.x)` domain ikonları için
- [ ] Hardcoded text yok (her şey `.tr()`)
- [ ] `print()` yok (`AppLogger`)
- [ ] `Theme.of(context)` ve `AppSpacing` kullanımı (hardcoded değer yok)
- [ ] `controller.dispose()` ConsumerStatefulWidget'larda
- [ ] `const Model._()` Freezed model'lerde
- [ ] `@JsonKey(unknownEnumValue:)` enum field'larda
- [ ] `switch` üzerinde `unknown` case
- [ ] `client.upsert()` (insert değil) — idempotent yazma
- [ ] `ProviderContainer` sonrası `addTearDown(container.dispose)` (test-stability.md)

Tam liste: CLAUDE.md § Critical Anti-Patterns

### 3. Veri Katmanı
- [ ] Drift query'lerde `.equalsValue()` enum için
- [ ] DAO direkt table'dan import (app_database üzerinden değil)
- [ ] `SupabaseConstants` kullanımı (hardcoded string yok)
- [ ] `.toSupabase()` extension `created_at`/`updated_at` strip
- [ ] FK parent'lı sync repo `ValidatedSyncMixin` kullanıyor mu?
- [ ] Schema migration varsa: `schemaVersion` arttı + `onUpgrade` + `supabase/migrations/` SQL eklendi

### 4. Güvenlik
- [ ] RLS policy değişikliği YOK client kodda
- [ ] Auth/Premium guard gerekli rotalarda
- [ ] Secret hardcoded değil (`--dart-define` veya `.env`)
- [ ] PII log/Sentry'ye gitmiyor
- [ ] Edge function: JWT verify aktif (`--no-verify-jwt` yok)
- [ ] Edge function: `user_id` body'den DEĞİL JWT claim'inden okunuyor

### 5. Test
- [ ] Yeni davranış için test eklendi/güncellendi
- [ ] `skip:`, `@Skip` veya tag-based exclusion eklenmediyse doğrulandı; eklendiyse issue/reason/alternatif coverage açık
- [ ] Provider test'lerinde `addTearDown(container.dispose)`
- [ ] Mock setup'lar gerçekçi (overly-permissive `any()` kötüye kullanım yok)
- [ ] `pumpAndSettle()` infinite animation üzerinde değil (timeout riski)
- [ ] Hard wait (`sleep`, `Future.delayed`) yok (test-stability.md)
- [ ] Edge case'ler kapsanmış (null, empty, error path)
- [ ] Coverage düşmedi (Codecov diff)

### 6. UI / UX
- [ ] AsyncValue: loading + error + data tüm dalları handle edilmiş
- [ ] Boş durum (`EmptyState`) ve hata durumu (`ErrorState`) kapsanmış
- [ ] Form: `_formKey.validate()` + `mounted` check
- [ ] Erişilebilirlik: tooltip + min 48dp tap target (accessibility.md)
- [ ] Dark mode test edilmiş (Theme renkleri)
- [ ] 3 dil için string'ler eklendi (tr/en/de)

### 7. Performans
- [ ] List → `ListView.builder` (lazy)
- [ ] `ref.watch().select(...)` ile rebuild scope daraltılmış
- [ ] `const` constructor mümkün her yerde
- [ ] N+1 query yok (Drift `.get()` döngü içinde değil)
- [ ] Image: cached + sized (full resolution değil)

### 8. Hata Yönetimi
- [ ] Typed `AppException` subclass kullanımı (`NetworkException`, `AuthException`, vb.)
- [ ] `AsyncValue.guard()` provider'da
- [ ] Bare `catch (e)` yok — log + typed exception
- [ ] Kritik path'te `Sentry.captureException` (observability.md)
- [ ] Error mesajı l10n key (kullanıcıya raw exception gitmiyor)

### 9. L10n
- [ ] `tr.json` master, sonra `en.json` + `de.json`
- [ ] `python3 scripts/check_l10n_sync.py` geçti
- [ ] Key naming: `category.key_name` (snake_case)
- [ ] Plural / namedArgs gerekiyorsa kullanılmış

### 10. Dokümantasyon
- [ ] Public API (`Repository`, `Service`) için doc comment
- [ ] Yeni edge function: README veya header comment
- [ ] CLAUDE.md stats `verify_rules.py --fix` ile güncel
- [ ] Yeni anti-pattern eklenirse: kural dosyası + CLAUDE.md liste güncellendi

## Onay Kuralları

### Approve
- Tüm kalite kapıları yeşil
- Checklist'in alakalı maddeleri ✓
- Test coverage düşmedi
- Anti-pattern bulgusu yok

### Request Changes
- Anti-pattern violation (CLAUDE.md kural numarası belirtilerek)
- Test eksikliği yeni davranış için
- Güvenlik regression
- Performans regression (gerekçeli)

### Comment (öneri, blocking değil)
- Stilistik tercihler
- Refactor fırsatı (bu PR scope dışı)
- İlgili future-work TODO

## Kısa Dönüş Süreleri
- PR < 200 satır → 24 saat içinde review
- PR > 500 satır → "split this PR" comment'i meşru
- Hotfix PR → 4 saat içinde, en az 1 göz
- Dependabot → otomatik triage, manuel approve büyük major bumps için

## Anti-Patterns (Reviewer Tarafı)
1. "LGTM" demek diff'i okumadan
2. Stilistik nitpick'leri blocking yapmak
3. PR scope'u dışı refactor talep etmek (ayrı issue aç)
4. Performans regression'ı "later" diye geçmek
5. Yazarın test eksikliğini reviewer'ın tamamlaması gerektiği varsayımı
6. CI yeşilse derin review'i atlamak (CI her şeyi yakalamaz)

> **İlgili**: ai-workflow.md (kalite kapıları), git-rules.md (PR workflow), branch-workflow.md (target branch)
