# Rules Improvement Design Spec

## Overview
BudgieBreedingTracker projesi kural dosyalarinin (.claude/rules/) kapsamli iyilestirmesi.
Hedef: Otomasyon artirma, eksik kurallari tamamlama, tekrarlari azaltma, CI entegrasyonu guclendirme.

## Current State
- 13 kural dosyasi, 2,343 satir
- Anti-pattern otomasyon kapsami: 11/17 (%65)
- 6 dokumantasyon boslugu
- Cross-file tekrar: 6 bilgi seti birden fazla dosyada

## Approach
Katmanli iyilestirme — 4 batch halinde, her batch bagimsiz test edilebilir.

---

## Batch 1: Otomasyon Iyilestirmeleri

### 1.1 Yeni Checker'lar (verify_code_quality.py)

4 yeni checker eklenir (guvenilir regex tabanlı):

**check_context_go_forward_nav**
- Pattern: `context.go(` kullanimi
- Whitelist: auth dosyalari (login, register, callback, auth_callback, two_factor_verify), main_shell.dart (bottom nav)
- Severity: error

**check_controller_dispose**
- Pattern: ConsumerStatefulWidget State siniflarinda `Controller()` tanimlanip `dispose()` icinde dispose edilmemesi
- Yontem: Dosya bazinda controller tanimlama sayisi vs dispose cagrisi sayisi karsilastirmasi
- Severity: warning (false-positive riski nedeniyle)

**check_json_key_unknown_enum**
- Pattern: Freezed model dosyalarinda (`_model.dart`) enum tipindeki field'larda `@JsonKey(unknownEnumValue:` eksikligi
- Yontem: `required <EnumType>` veya `<EnumType>?` field tespiti, sonra @JsonKey kontrolu
- Severity: error

**check_dao_import_app_database**
- Pattern: `_dao.dart` dosyalarinda `import.*app_database` satiri
- Beklenen: Table dosyasinin dogrudan import edilmesi
- Severity: error

2 checker uyari modunda eklenir (CI'da bloklamaz):

**check_switch_unknown_case** (warning only)
- Pattern: Enum uzerinde switch bloklarinda `unknown` case eksikligi
- Sinir: Regex ile tam guvenilir tespit zor, false-positive olabilir

**check_route_ordering** (warning only)
- Pattern: GoRouter routes listesinde `:param` path'in specific path'ten once gelmesi
- Sinir: Nested route yapisini regex ile parse etmek zor

### 1.2 Whitelist Mekanizmasi

verify_code_quality.py'a dosya/dizin bazli whitelist destegi:
```python
WHITELIST = {
    'check_context_go_forward_nav': [
        'lib/features/auth/',
        'lib/features/home/widgets/main_shell.dart',
        'lib/core/widgets/not_found_screen.dart',
    ],
    'check_hardcoded_colors': [
        'lib/features/genetics/utils/',
        'lib/features/genetics/widgets/budgie_painter',
        'lib/features/auth/widgets/budgie_login_colors.dart',
    ],
    'check_direct_client_from': [
        'lib/features/admin/',
    ],
}
```

### 1.3 Raporlama Iyilestirmesi

Script ciktisina ozet ekle:
```
=== Code Quality Report ===
Checkers: 17/17 (15 error + 2 warning)
Violations: 3 errors, 1 warning
Coverage: 100% of CLAUDE.md anti-patterns
```

`--verbose` flag ile violation detaylari (dosya:satir:mesaj).

---

## Batch 2: Eksik Kural Alanlari

### 2.1 Golden Test Rehberi → coding-standards.md

Eklenecek bolum (~25 satir):
- Golden test dosya konumu: `test/golden/`
- Tag: `@Tags(['golden'])` — CI'da exclude edilir
- Guncelleme: `flutter test --update-goldens --tags golden`
- Platform bagimlilik notu (font rendering farkliliklari)
- Failures klasoru: test sonrasi otomatik temizlik gerekliligi

### 2.2 Admin Katmani Istisnalari → supabase_rules.md

Eklenecek bolum (~20 satir):
- Admin-only tablolar listesi (admin_logs, system_settings, admin_sessions, vb.)
- Bu tablolar icin RemoteSource/Repository gereksiz — dogrudan client.from() kabul edilir
- Neden: Admin paneli tek kullanici (admin), sync gereksiz, RLS admin role ile korunur
- verify_code_quality.py whitelist'te tanimli

### 2.3 Batch Sync Hata Yonetimi → supabase_rules.md

Eklenecek bolum (~15 satir):
- Kismi basari senaryosu: Her entity bagimsiz try-catch, basarisiz olanlar SyncMetadata'da error olarak isaretlenir
- Buyuk batch (100+ kayit): Chunk'lara bolunur (50'ser), her chunk bagimsiz
- Timeout: Tek entity push 30s, tam sync 5 dakika limiti
- Recovery: Sonraki sync cycle'da sadece error/pending kayitlar retry edilir

### 2.4 Performans Olcum Rehberi → architecture.md

Eklenecek bolum (~20 satir):
- Flutter DevTools: Widget rebuild sayaci, memory profiler
- Drift sorgu performansi: `AppLogger.debug('query', stopwatch.elapsed)`
- Sync sure takibi: SyncOrchestrator'da mevcut logging pattern
- Benchmark: Dashboard yukleme < 500ms, liste scroll 60fps hedefi

### 2.5 Phase Tanimlari → CLAUDE.md Quick Reference

Eklenecek bolum (~10 satir):
```markdown
### Development Phases
| Phase | Kapsam | Tarih |
|-------|--------|-------|
| Phase 21 | Localization & Language Switching | Tamamlandi |
| Phase 22 | Custom SVG Icon System (82 icon) | Tamamlandi |
| Phase 23 | Enum Safety (unknownEnumValue) | Tamamlandi |
```

### 2.6 Dosya Boyutu Stratejisi → coding-standards.md

Eklenecek bolum (~15 satir):
- 300 satir limiti asildinda: widget extraction (private → ayri dosya)
- `part` directive kullanimi: ayni sinifin yardimci metodlari icin
- Istisna: Generated dosyalar (.g.dart, .freezed.dart) sayilmaz
- Screen bolme pattern: `_Header`, `_Body`, `_Footer` → ayri widget dosyalari

### 2.7 Hardcoded Renk Istisnalari → coding-standards.md

Eklenecek bolum (~10 satir):
- Domain-specific renk paletleri (genetics phenotype, budgie painter) istisna
- Pattern: `abstract final class XPalette { static const Color x = Color(0x...); }`
- Bu paletler Theme'e baglanamaz cunku gercek kus renklerini temsil eder
- verify_code_quality.py whitelist'te tanimli

---

## Batch 3: Sadelestirme

### 3.1 Single Source of Truth Referans Sistemi

6 tekrar eden bilgi seti icin tek yetkili kaynak belirlenir:

| Bilgi | Tek Kaynak | Referans Veren Dosyalar |
|-------|-----------|------------------------|
| 17 anti-pattern listesi | CLAUDE.md Quick Reference | coding-standards.md, ai-workflow.md |
| Provider dependency chain | providers.md | architecture.md, new-feature-checklist.md |
| Sync flow detayi | supabase_rules.md | architecture.md, database.md |
| Widget icon API (Phase 22) | widgets.md | coding-standards.md, architecture.md |
| Freezed model pattern | coding-standards.md | new-feature-checklist.md, database.md |
| Migration pattern | database.md | architecture.md, new-feature-checklist.md |

Referans formati:
```markdown
> Detayli bilgi: `providers.md` → "Provider Dependency Chain" bolumu
```

### 3.2 Dosya Baslangic Ozetleri

Her kural dosyasinin basina 2-3 satirlik amac ozeti + "tek yetkili kaynak" listesi eklenir.

Ornek:
```markdown
# Database Rules (Drift + Supabase)
> Drift tablo/DAO/mapper/converter tanimlari, migration pattern, repository kurallari.
> Tek yetkili kaynak: sema versiyonu, migration, DAO pattern, enum converter.
```

### 3.3 ai-workflow.md Sadelestirme

Kaldirilacak/referansa donusturulecek bolumler:
- "Quality Gates" anti-pattern listesi → `> CLAUDE.md Quick Reference → "Critical Anti-Patterns"` referansi
- "Self-Review Kontrol Listesi" Dart/Flutter konvansiyonlari → `> coding-standards.md` referansi
- "Migration Guvenligi" → `> database.md → "Migration Pattern"` referansi
- "Performans Farkindaligi" liste → `> architecture.md → "Performance Guidelines"` referansi

Korunacaklar (ai-workflow'a ozgu):
- Gorev yaklasim stratejisi tablosu
- Batch islem pattern'i
- Iletisim kurallari
- Yasakli eylemler
- Hata kurtarma prosedurleri
- Multi-agent kullanim stratejisi
- Context yonetimi

Tahmini azalma: ~80-100 satir (322 → ~230 satir).

---

## Batch 4: Dogrulama ve CI Entegrasyonu

### 4.1 verify_code_quality.py Cikti Guncellemesi

Script son satirinda ozet:
```
=== Code Quality Report ===
Checkers: 17/17 (15 error + 2 warning)
Violations: 0 errors, 0 warnings
Status: PASSED
```

### 4.2 CLAUDE.md Stats Guncellemesi

`verify_rules.py --fix` calistirilir. Manuel guncelleme:
- "11 checkers, 10/17 CLAUDE.md patterns" → "17 checkers, 17/17 CLAUDE.md patterns (15 error + 2 warning)"

### 4.3 Cross-Reference Dogrulamasi

verify_rules.py'a yeni kontrol:
- Kural dosyalarindaki `> Detayli bilgi: X.md → "Y"` referanslarinin hedef dosyada var olup olmadigini grep ile kontrol
- Kirik referans → warning

### 4.4 Nihai CI Simulasyonu

Tum degisiklikler sonrasi:
```bash
flutter analyze --no-fatal-infos
python scripts/verify_code_quality.py
python scripts/verify_rules.py
python scripts/check_l10n_sync.py
```

---

## Success Criteria

1. verify_code_quality.py: 17/17 anti-pattern kapsami
2. Tum kural dosyalarinda tek yetkili kaynak referans sistemi
3. ai-workflow.md: 322 → ~230 satir
4. Yeni kural alanlari (7 bolum) dokumante edilmis
5. CI pipeline tum kontrolleri gecmis
6. Cross-reference dogrulamasi hatasiz

## Risk & Mitigation

| Risk | Etki | Onlem |
|------|------|-------|
| Yeni checker false-positive | CI bloklama | Warning mode + whitelist |
| Referans sadelestirmesi bilgi kaybi | Kural eksikligi | Her referans hedefi dogrulanir |
| ai-workflow.md asiri sadelestirme | AI rehberlik kaybi | Ozgu icerikleri koruma |

## Files Affected

### Modified
- `scripts/verify_code_quality.py` — 6 yeni checker + whitelist + raporlama
- `scripts/verify_rules.py` — cross-reference dogrulama
- `.claude/rules/coding-standards.md` — golden test, dosya boyutu, renk istisnalari
- `.claude/rules/supabase_rules.md` — admin istisnalari, batch sync
- `.claude/rules/architecture.md` — performans olcum, referans sadelestirme
- `.claude/rules/providers.md` — baslangic ozeti
- `.claude/rules/widgets.md` — baslangic ozeti
- `.claude/rules/database.md` — baslangic ozeti, referans sadelestirme
- `.claude/rules/navigation.md` — baslangic ozeti
- `.claude/rules/localization.md` — baslangic ozeti
- `.claude/rules/new-feature-checklist.md` — referans sadelestirme
- `.claude/rules/ai-workflow.md` — sadelestirme (~80-100 satir azalma)
- `.claude/rules/chat.md` — baslangic ozeti
- `.claude/rules/git-rules.md` — baslangic ozeti
- `.claude/rules/CLAUDE.md` — Phase tanimlari, stats guncelleme
- `CLAUDE.md` — checker stats guncelleme

### Not Modified
- `.github/workflows/ci.yml` — mevcut pipeline yeterli
- `analysis_options.yaml` — degisiklik gereksiz
- Herhangi bir lib/ veya test/ dosyasi — bu spec sadece kurallar ve scriptler
