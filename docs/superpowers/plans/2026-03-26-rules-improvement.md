# Rules Improvement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Kural dosyalarini iyilestirerek anti-pattern otomasyon kapsamini %100'e cikarmak, eksik kurallari tamamlamak ve tekrarlari azaltmak.

**Architecture:** 4 batch'lik katmanli yaklasim. Batch 1: verify_code_quality.py'a 6 yeni checker + whitelist + raporlama. Batch 2: 7 yeni kural bolumu. Batch 3: Single source of truth referans sistemi + ai-workflow.md sadelestirme. Batch 4: Dogrulama ve stats guncelleme.

**Tech Stack:** Python 3 (scripts), Markdown (rules), Dart regex patterns

**Spec:** `docs/superpowers/specs/2026-03-26-rules-improvement-design.md`

---

### Task 1: Whitelist mekanizmasi ve yardimci fonksiyonlar ekle

**Files:**
- Modify: `scripts/verify_code_quality.py:22-87`

- [ ] **Step 1: WHITELIST dict ve is_whitelisted helper ekle**

`EXTRA_CHECKERS` satirindan sonra (satir 86), whitelist dict'i ekle:

```python
# --- Whitelist (checker bazinda dosya/dizin istisna listesi) ---
WHITELIST = {
    'check_context_go_forward_nav': [
        'lib/features/auth/',
        'lib/features/home/',
        'lib/features/admin/',
        'lib/features/more/',
        'lib/features/profile/widgets/profile_menu_dialog.dart',
        'lib/features/profile/widgets/account_deletion_dialog.dart',
        'lib/features/profile/widgets/danger_zone_section.dart',
        'lib/features/community/widgets/community_feed_list.dart',
        'lib/core/widgets/not_found_screen.dart',
    ],
    'check_hardcoded_colors': [
        'lib/features/genetics/utils/',
        'lib/features/genetics/widgets/budgie_painter',
        'lib/features/auth/widgets/budgie_login_colors.dart',
    ],
    # Not: check_direct_client_from checker'i henuz yok, gelecek icin yer tutucu
    # 'check_direct_client_from': ['lib/features/admin/'],
}


def is_whitelisted(checker_name: str, filepath: Path) -> bool:
    """Check if file is whitelisted for a specific checker."""
    patterns = WHITELIST.get(checker_name, [])
    rel = relative_path(filepath)
    return any(rel.startswith(p) or rel == p for p in patterns)
```

- [ ] **Step 2: Finding dataclass'ina severity field ekle**

```python
@dataclass
class Finding:
    file: str
    line_num: int
    line_text: str
    suggestion: str
    severity: str = "error"  # "error" or "warning"
```

- [ ] **Step 3: Category dataclass'ina severity field ekle**

```python
@dataclass
class Category:
    name: str
    tag: str
    description: str
    severity: str = "error"  # "error" or "warning"
    findings: List[Finding] = field(default_factory=list)
```

- [ ] **Step 4: Dosyayi kaydet ve syntax kontrolu yap**

Run: `python -c "import ast; ast.parse(open('scripts/verify_code_quality.py').read()); print('OK')"`
Expected: `OK`

- [ ] **Step 5: Commit**

```bash
git add scripts/verify_code_quality.py
git commit -m "refactor(scripts): add whitelist mechanism and severity support to code quality scanner"
```

---

### Task 2: Bilinen enum tipleri toplama yardimcisi ekle

**Files:**
- Modify: `scripts/verify_code_quality.py`

- [ ] **Step 1: collect_known_enums helper fonksiyonu ekle**

`get_dart_files()` fonksiyonundan sonra ekle:

```python
def collect_known_enums() -> set:
    """lib/core/enums/ altindaki enum tiplerini topla."""
    enums_dir = LIB_DIR / "core" / "enums"
    known = set()
    if not enums_dir.exists():
        return known
    for f in enums_dir.glob("*.dart"):
        if any(f.name.endswith(s) for s in EXCLUDED_SUFFIXES):
            continue
        try:
            content = f.read_text(encoding="utf-8")
            for m in re.finditer(r'enum\s+(\w+)\s*\{', content):
                known.add(m.group(1))
        except Exception:
            pass
    return known
```

- [ ] **Step 2: Syntax kontrolu**

Run: `python -c "import ast; ast.parse(open('scripts/verify_code_quality.py').read()); print('OK')"`
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add scripts/verify_code_quality.py
git commit -m "feat(scripts): add enum type collector for JsonKey checker"
```

---

### Task 3: check_context_go_forward_nav checker ekle

**Files:**
- Modify: `scripts/verify_code_quality.py`

- [ ] **Step 1: Checker fonksiyonu ekle**

`check_freezed3_pattern` fonksiyonundan sonra ekle:

```python
def check_context_go_forward_nav(lines: List[str], filepath: Path, cat: Category):
    """12. context.go( forward nav -> context.push() kullan"""
    if is_whitelisted('check_context_go_forward_nav', filepath):
        return

    for i, line in enumerate(lines, 1):
        if is_comment_line(line):
            continue
        match = re.search(r'context\.go\s*\(', line)
        if match and not is_in_string_literal(line, match.start()):
            cat.findings.append(Finding(
                file=relative_path(filepath),
                line_num=i,
                line_text=line.rstrip(),
                suggestion="Forward navigation icin context.push() kullan (context.go() stack'i siler)",
            ))
```

- [ ] **Step 2: ANTI_PATTERN_COVERAGE dict'e ekle**

```python
    10: "check_context_go_forward_nav",  # context.go() -> context.push() (CLAUDE.md #10)
```

- [ ] **Step 3: categories ve checkers listelerine ekle**

categories listesine:
```python
Category("context.go() Forward Nav", "[GoRouter]", "context.go() -> context.push() kullan"),
```

checkers listesine:
```python
check_context_go_forward_nav,
```

- [ ] **Step 4: Test et**

Run: `python scripts/verify_code_quality.py --verbose 2>&1 | grep -c "GoRouter"`
Expected: `1` (kategori baslikinda)

- [ ] **Step 5: Commit**

```bash
git add scripts/verify_code_quality.py
git commit -m "feat(scripts): add context.go() forward nav checker with whitelist"
```

---

### Task 4: check_controller_dispose checker ekle (warning)

**Files:**
- Modify: `scripts/verify_code_quality.py`

- [ ] **Step 1: Checker fonksiyonu ekle**

```python
def check_controller_dispose(lines: List[str], filepath: Path, cat: Category):
    """13. ConsumerStatefulWidget'ta controller dispose eksik"""
    content = "".join(lines)
    if "ConsumerStatefulWidget" not in content:
        return

    # Count controller declarations and dispose calls
    controller_pattern = re.compile(r'(?:final|late final)\s+\w*Controller\s+_?\w+\s*=')
    dispose_pattern = re.compile(r'_?\w+\.dispose\(\)')

    controllers = controller_pattern.findall(content)
    disposes = dispose_pattern.findall(content)

    if len(controllers) > len(disposes):
        # Find first controller line for reporting
        for i, line in enumerate(lines, 1):
            if controller_pattern.search(line):
                cat.findings.append(Finding(
                    file=relative_path(filepath),
                    line_num=i,
                    line_text=line.rstrip(),
                    suggestion=f"Controller dispose() eksik olabilir ({len(controllers)} tanim, {len(disposes)} dispose)",
                    severity="warning",
                ))
                break
```

- [ ] **Step 2: ANTI_PATTERN_COVERAGE dict'e ekle**

```python
    14: "check_controller_dispose",      # Missing controller.dispose() (CLAUDE.md #14)
```

- [ ] **Step 3: categories ve checkers listelerine ekle**

categories listesine (severity="warning"):
```python
Category("Controller Dispose Eksik", "[Dispose]", "Controller.dispose() eksik olabilir", severity="warning"),
```

checkers listesine:
```python
check_controller_dispose,
```

- [ ] **Step 4: Test et**

Run: `python scripts/verify_code_quality.py 2>&1 | grep "Dispose"`
Expected: PASS veya warning

- [ ] **Step 5: Commit**

```bash
git add scripts/verify_code_quality.py
git commit -m "feat(scripts): add controller dispose checker (warning mode)"
```

---

### Task 5: check_json_key_unknown_enum checker ekle

**Files:**
- Modify: `scripts/verify_code_quality.py`

- [ ] **Step 1: Checker fonksiyonu ekle**

```python
def check_json_key_unknown_enum(lines: List[str], filepath: Path, cat: Category):
    """14. Freezed model enum field'larinda @JsonKey(unknownEnumValue:) eksik"""
    if not filepath.name.endswith("_model.dart"):
        return

    content = "".join(lines)
    if "@freezed" not in content:
        return

    known_enums = _KNOWN_ENUMS_CACHE
    if not known_enums:
        return

    for i, line in enumerate(lines, 1):
        if is_comment_line(line):
            continue
        # Check for enum type fields: required EnumType fieldName, or EnumType? fieldName
        for enum_name in known_enums:
            pattern = rf'(?:required\s+)?{re.escape(enum_name)}\??\s+\w+'
            match = re.search(pattern, line)
            if match:
                # Check current line and previous 2 lines for @JsonKey(unknownEnumValue
                context_start = max(0, i - 3)
                context_lines = "".join(lines[context_start:i])
                if "unknownEnumValue" not in context_lines and "unknownEnumValue" not in line:
                    cat.findings.append(Finding(
                        file=relative_path(filepath),
                        line_num=i,
                        line_text=line.rstrip(),
                        suggestion=f"@JsonKey(unknownEnumValue: {enum_name}.unknown) ekle",
                    ))
```

- [ ] **Step 2: ANTI_PATTERN_COVERAGE dict'e ekle**

```python
    8: "check_json_key_unknown_enum",    # Missing @JsonKey(unknownEnumValue) (CLAUDE.md #8)
```

- [ ] **Step 3: categories ve checkers listelerine ekle**

```python
Category("@JsonKey unknownEnumValue Eksik", "[JsonKey]", "@JsonKey(unknownEnumValue:) ekle"),
```

```python
check_json_key_unknown_enum,
```

- [ ] **Step 4: Test et**

Run: `python scripts/verify_code_quality.py 2>&1 | grep "JsonKey"`
Expected: `PASS` veya bulgu raporu

- [ ] **Step 5: Commit**

```bash
git add scripts/verify_code_quality.py
git commit -m "feat(scripts): add @JsonKey unknownEnumValue checker for Freezed models"
```

---

### Task 6: check_dao_import, check_switch_unknown, check_route_ordering checker'lari ekle (warning)

**Files:**
- Modify: `scripts/verify_code_quality.py`

- [ ] **Step 1: 3 warning checker fonksiyonu ekle**

```python
def check_dao_import_app_database(lines: List[str], filepath: Path, cat: Category):
    """15. DAO dosyasinda table dosyasi dogrudan import edilmeli"""
    if "_dao.dart" not in filepath.name:
        return

    content = "".join(lines)
    if "@DriftAccessor" not in content:
        return

    has_direct_table_import = any(
        re.search(r'import\s+.*(?:tables/|_table\.dart)', line)
        for line in lines
    )
    if not has_direct_table_import:
        cat.findings.append(Finding(
            file=relative_path(filepath),
            line_num=1,
            line_text=lines[0].rstrip() if lines else "",
            suggestion="Table dosyasini dogrudan import et (app_database uzerinden degil)",
            severity="warning",
        ))


def check_switch_unknown_case(lines: List[str], filepath: Path, cat: Category):
    """16. Enum switch'lerinde unknown case eksik (warning)"""
    if not filepath.name.endswith("_model.dart") and "enums" not in str(filepath):
        return

    in_switch = False
    switch_line = 0
    switch_text = ""
    brace_depth = 0

    for i, line in enumerate(lines, 1):
        if is_comment_line(line):
            continue
        if re.search(r'\bswitch\s*\(', line):
            in_switch = True
            switch_line = i
            switch_text = line.rstrip()
            brace_depth = 0

        if in_switch:
            brace_depth += line.count('{')
            brace_depth -= line.count('}')
            if 'unknown' in line.lower() or 'Unknown' in line:
                in_switch = False
                continue
            if brace_depth <= 0 and switch_line > 0:
                cat.findings.append(Finding(
                    file=relative_path(filepath),
                    line_num=switch_line,
                    line_text=switch_text,
                    suggestion="switch ifadesinde 'unknown' case ekle",
                    severity="warning",
                ))
                in_switch = False


def check_route_ordering(lines: List[str], filepath: Path, cat: Category):
    """17. GoRouter'da parameterized route specific'ten once (warning)"""
    if "app_router" not in filepath.name:
        return

    prev_is_param = False
    prev_line_num = 0

    for i, line in enumerate(lines, 1):
        if is_comment_line(line):
            continue
        path_match = re.search(r"path:\s*['\"]([^'\"]+)['\"]", line)
        if path_match:
            path_val = path_match.group(1)
            is_param = ':' in path_val
            if prev_is_param and not is_param and path_val != '/':
                cat.findings.append(Finding(
                    file=relative_path(filepath),
                    line_num=prev_line_num,
                    line_text=f"  path: '{path_val}' parametreli route'tan sonra",
                    suggestion="Specific route'lar parametreli route'lardan ONCE gelmeli",
                    severity="warning",
                ))
            prev_is_param = is_param
            prev_line_num = i
```

- [ ] **Step 2: ANTI_PATTERN_COVERAGE dict'e ekle**

```python
    11: "check_dao_import_app_database",  # Import table via app_database (CLAUDE.md #11, warning)
    12: "check_route_ordering",           # Route ordering (CLAUDE.md #12, warning)
    9: "check_switch_unknown_case",       # switch without unknown (CLAUDE.md #9, warning)
```

- [ ] **Step 3: categories ve checkers listelerine ekle**

3 yeni category (hepsi severity="warning"):
```python
Category("DAO Table Import", "[DriftDAO]", "Table dosyasini dogrudan import et", severity="warning"),
Category("Switch Unknown Case", "[Switch]", "switch'te unknown case ekle", severity="warning"),
Category("Route Ordering", "[Router]", "Specific route parametreliden once gelmeli", severity="warning"),
```

3 yeni checker:
```python
check_dao_import_app_database,
check_switch_unknown_case,
check_route_ordering,
```

- [ ] **Step 4: Test et**

Run: `python scripts/verify_code_quality.py 2>&1 | grep -E "(DriftDAO|Switch|Router)"`
Expected: Her checker icin PASS veya warning ciktisi

- [ ] **Step 5: Commit**

```bash
git add scripts/verify_code_quality.py
git commit -m "feat(scripts): add 3 warning-mode checkers (DAO import, switch unknown, route ordering)"
```

---

### Task 7: Raporlama iyilestirmesi ve exit code semantigi

**Files:**
- Modify: `scripts/verify_code_quality.py` (main fonksiyonu)

- [ ] **Step 1: main() fonksiyonunda enum cache'i ve report bolumunu guncelle**

main() fonksiyonunun basinda (dart_files = get_dart_files() satirindan sonra) ekle:
```python
    # Cache enum types once (check_json_key_unknown_enum icin)
    _KNOWN_ENUMS_CACHE = collect_known_enums()
```

Ve check_json_key_unknown_enum fonksiyonunda `collect_known_enums()` yerine `_KNOWN_ENUMS_CACHE` kullan (module-level `_KNOWN_ENUMS_CACHE = set()` tanimla).

Sonra mevcut report bolumunu (satirlar ~501-550) tamamen degistir:

```python
    # Report results
    total_errors = 0
    total_warnings = 0
    categories_with_issues = 0

    for cat in categories:
        count = len(cat.findings)
        if count == 0:
            print(f"  {GREEN}PASS{RESET}  {cat.tag} {cat.name}: 0 sorun")
        else:
            categories_with_issues += 1
            if cat.severity == "warning":
                total_warnings += count
                print(f"  {YELLOW}WARN{RESET}  {cat.tag} {cat.name}: {count} uyari")
            else:
                total_errors += count
                print(f"  {RED}FAIL{RESET}  {cat.tag} {cat.name}: {count} sorun")

            if VERBOSE:
                for finding in cat.findings:
                    print(f"        {YELLOW}{finding.file}:{finding.line_num}{RESET}")
                    print(f"        {finding.line_text.strip()[:100]}")
                    print(f"        -> {finding.suggestion}")
                    print()
            else:
                for finding in cat.findings[:3]:
                    print(f"        {YELLOW}{finding.file}:{finding.line_num}{RESET} -> {finding.suggestion}")
                if count > 3:
                    print(f"        ... ve {count - 3} sorun daha (--verbose ile tumu)")

    # Summary
    total_checkers = len(categories)
    covered = len(ANTI_PATTERN_COVERAGE)
    error_checkers = sum(1 for c in categories if c.severity == "error")
    warning_checkers = sum(1 for c in categories if c.severity == "warning")

    print(f"\n{BOLD}=== Code Quality Report ==={RESET}")
    print(f"  Checkers:   {total_checkers} ({error_checkers} error + {warning_checkers} warning)")
    print(f"  Coverage:   {covered}/{total_patterns if total_patterns > 0 else '?'} CLAUDE.md anti-patterns")
    print(f"  Errors:     {total_errors}")
    print(f"  Warnings:   {total_warnings}")

    if total_errors == 0 and total_warnings == 0:
        print(f"  Status:     {GREEN}{BOLD}PASSED{RESET}")
    elif total_errors == 0:
        print(f"  Status:     {YELLOW}{BOLD}PASSED (with warnings){RESET}")
    else:
        print(f"  Status:     {RED}{BOLD}FAILED{RESET}")

    if total_errors > 0 or total_warnings > 0:
        print(f"\n  {YELLOW}Detay icin: python scripts/verify_code_quality.py --verbose{RESET}")

    # Coverage report (verbose only)
    if total_patterns > 0 and VERBOSE:
        uncovered = [i for i in range(1, total_patterns + 1) if i not in ANTI_PATTERN_COVERAGE]
        if uncovered:
            print(f"\n{BOLD}--- Otomatik Kapsam Disi Anti-Pattern'ler ---{RESET}")
            for idx in uncovered:
                if idx <= len(claude_patterns):
                    print(f"  {YELLOW}#{idx}{RESET} {claude_patterns[idx - 1]}")

    # Exit code: 0 for pass/warnings-only, 1 for errors
    return 1 if total_errors > 0 else 0
```

- [ ] **Step 2: Eski summary kodunu kaldir**

Satirlar 501-550 arasindaki eski report/summary kodunu yukardakiyle degistir.

- [ ] **Step 3: Test et**

Run: `python scripts/verify_code_quality.py`
Expected: `=== Code Quality Report ===` ciktisi, status PASSED veya PASSED (with warnings)

- [ ] **Step 4: Commit**

```bash
git add scripts/verify_code_quality.py
git commit -m "feat(scripts): improve reporting with error/warning separation and coverage summary"
```

---

### Task 8: coding-standards.md'ye yeni bolumler ekle

**Files:**
- Modify: `.claude/rules/coding-standards.md:155-180`

- [ ] **Step 1: Testing bolumunun sonuna Golden Test rehberi ekle (satir 165 sonrasi)**

```markdown
## Golden Tests
- Golden test dosyalari: `test/golden/` dizini
- Tag: `@Tags(['golden'])` — CI'da `--exclude-tags golden` ile atlanir
- Guncelleme: `flutter test --update-goldens --tags golden`
- Platform bagimliligi: Font rendering isletim sistemine gore degisir, golden dosyalar Linux CI ortaminda uretilir
- Failures klasoru: `test/golden/widgets/failures/` — test sonrasi temizlik gerektirir
- Golden test ekleme: Yeni widget icin `goldenTest()` helper, `autoHeight: true` tercih et
```

- [ ] **Step 2: File Organization bolumunun sonuna (satir 180 sonrasi) dosya boyutu stratejisi ekle**

```markdown
## File Size Strategy
- Maksimum **300 satir** per file (generated dosyalar haric: `.g.dart`, `.freezed.dart`)
- 300 satir asildiginda bolme stratejisi:
  1. **Widget extraction**: Private `_SubWidget` → ayri dosyaya tasi (ornek: `_Header` → `bird_detail_header.dart`)
  2. **Part directive**: Ayni sinifin helper metodlari icin `part 'file_helpers.dart'`
  3. **Screen decomposition**: `_StatsSection`, `_InfoSection` → widget dosyalarina ayir
- Screen bolme pattern: Detail screen → header + info + related sections ayri dosya
```

- [ ] **Step 3: Code Style Rules Must NOT Do sonuna (satir 96 civari) renk istisnalari ekle**

```markdown
### Hardcoded Color Exceptions
Domain-specific renk paletleri `Theme.of(context)` kuralinin **istisnasi**dir:
- **Genetics phenotype renkleri**: Gercek kus renklerini temsil eder, tema bagimli olamaz
- **Budgie painter renkleri**: Anatomik detay cizimi icin sabit renkler
- Pattern: `abstract final class XPalette { static const Color x = Color(0x...); }`
- Bu dosyalar `verify_code_quality.py` whitelist'inde tanimlidir
- Dosyalar: `lib/features/genetics/utils/`, `lib/features/auth/widgets/budgie_login_colors.dart`
```

- [ ] **Step 4: Commit**

```bash
git add .claude/rules/coding-standards.md
git commit -m "docs(rules): add golden test guide, file size strategy, and color exceptions"
```

---

### Task 9: supabase_rules.md'ye admin istisnalari ve batch sync ekle

**Files:**
- Modify: `.claude/rules/supabase_rules.md:131-133`

- [ ] **Step 1: "Adding New Supabase Entity" bolumundan once admin istisnalari ekle**

```markdown
## Admin Layer Exceptions
Admin paneli ozel kurallari (standart data flow'dan istisna):
- **Admin-only tablolar**: admin_logs, admin_sessions, admin_rate_limits, security_events, system_alerts, system_settings, system_metrics, system_status
- Bu tablolar icin RemoteSource/Repository **gereksiz** — dogrudan `client.from()` kabul edilir
- **Neden**: Admin paneli tek kullanici (admin), sync gereksiz, RLS admin role ile korunur
- **Konum**: `lib/features/admin/providers/` dosyalari
- `verify_code_quality.py` whitelist'inde `check_direct_client_from` → `lib/features/admin/` olarak tanimli

## Batch Sync Error Handling
Buyuk veri setlerinde sync hata yonetimi:
- **Kismi basari**: Her entity bagimsiz try-catch, basarisiz olanlar `SyncMetadata`'da `SyncStatus.error` olarak isaretlenir
- **Chunk stratejisi**: 100+ kayit → 50'lik chunk'lara bol, her chunk bagimsiz push
- **Timeout**: Tek entity push 30s, tam sync 5 dakika limiti
- **Recovery**: Sonraki sync cycle'da sadece `error`/`pending` kayitlar retry edilir
- **Logging**: Her chunk sonucu `AppLogger.info('sync', 'Chunk N: X basarili, Y basarisiz')`
```

- [ ] **Step 2: Commit**

```bash
git add .claude/rules/supabase_rules.md
git commit -m "docs(rules): add admin layer exceptions and batch sync error handling"
```

---

### Task 10: architecture.md'ye performans olcum rehberi ekle

**Files:**
- Modify: `.claude/rules/architecture.md:217-227`

- [ ] **Step 1: Performance Guidelines bolumunun sonuna olcum rehberi ekle**

Mevcut Performance Guidelines maddeleri korunur, sonuna eklenir:

```markdown
### Performance Measurement
- **Flutter DevTools**: Widget rebuild sayaci (Track Widget Rebuilds), memory profiler, CPU profiler
- **Drift sorgu performansi**: `final sw = Stopwatch()..start(); /* query */ AppLogger.debug('perf', 'query: ${sw.elapsed}');`
- **Sync sure takibi**: `SyncOrchestrator` mevcut logging'i kullanir (`AppLogger.info('sync', ...)`)
- **Hedef metrikler**: Dashboard yukleme < 500ms, liste scroll 60fps, sync < 5 dakika
- **Profiling**: Release mode'da test et (debug mode misleading), `--profile` flag ile calistir
```

- [ ] **Step 2: Commit**

```bash
git add .claude/rules/architecture.md
git commit -m "docs(rules): add performance measurement guide to architecture"
```

---

### Task 11: CLAUDE.md Quick Reference'a Phase tanimlari ekle

**Files:**
- Modify: `.claude/rules/CLAUDE.md`

- [ ] **Step 1: Quick Reference bolumune (Critical Anti-Patterns'den once) Phase tablosu ekle**

```markdown
### Development Phases
| Phase | Kapsam | Durum |
|-------|--------|-------|
| Phase 21 | Localization & Language Switching | Tamamlandi |
| Phase 22 | Custom SVG Icon System (82 icon) | Tamamlandi |
| Phase 23 | Enum Safety (unknownEnumValue, switch unknown) | Tamamlandi |
```

- [ ] **Step 2: Commit**

```bash
git add .claude/rules/CLAUDE.md
git commit -m "docs(rules): add development phase definitions to quick reference"
```

---

### Task 12: Kural dosyalarina baslangic ozetleri ekle

**Files:**
- Modify: 11 kural dosyasi (CLAUDE.md haric, zaten index dosyasi)

- [ ] **Step 1: Her dosyanin basliginin altina 2 satirlik ozet ekle**

Dosya ve ozet listesi:

**architecture.md** (baslik altina):
```markdown
> Mimari, katmanlar, folder structure, tech stack, data flow, offline-first sync, storage, performance.
> Tek yetkili kaynak: tech stack, folder structure, data flow, sync detayi, performance guidelines.
```

**coding-standards.md**:
```markdown
> Naming conventions, code style, anti-patterns, model/enum rules, error handling, testing.
> Tek yetkili kaynak: naming rules, Freezed model pattern, enum rules, golden test, file size strategy.
```

**providers.md**:
```markdown
> Riverpod provider tipleri, dependency chain, ref kullanimi, filter/search pattern, disposal.
> Tek yetkili kaynak: provider dependency chain, ref usage rules, filter/search chaining pattern.
```

**database.md**:
```markdown
> Drift tablo/DAO/mapper/converter tanimlari, migration pattern, repository kurallari.
> Tek yetkili kaynak: schema version, migration pattern, DAO pattern, enum converter, repository pattern.
```

**widgets.md**:
```markdown
> Widget tipleri, AsyncValue handling, form pattern, card/list/detail desenleri, icon API.
> Tek yetkili kaynak: widget tipleri, AsyncValue.when pattern, icon API (Phase 22), shared widget listesi.
```

**navigation.md**:
```markdown
> GoRouter route constants, shell routes, guards, edit mode, route ordering, deep link.
> Tek yetkili kaynak: route listesi (60), navigation methods, guard tanimlari, route ordering kurallari.
```

**localization.md**:
```markdown
> easy_localization setup, key structure, .tr() usage, adding new keys, sync workflow.
> Tek yetkili kaynak: localization key yapisi, dil ekleme workflow, key kategorileri.
```

**new-feature-checklist.md**:
```markdown
> Adim adim yeni feature olusturma rehberi (data → feature → nav → l10n → test).
> Diger kural dosyalarina referans verir, kendi basina tek yetkili kaynak degildir.
```

**supabase_rules.md**:
```markdown
> Supabase entegrasyonu: auth, remote source, sync, RLS, storage, edge functions, admin istisnalari.
> Tek yetkili kaynak: Supabase auth flow, remote source pattern, sync architecture, admin layer rules.
```

**chat.md**:
```markdown
> Yanit dili (Turkce), kodlama sonrasi oneri formati ve kategorileri.
> Tek yetkili kaynak: dil kurallari, oneri formati.
```

**git-rules.md**:
```markdown
> Commit conventions, branch naming, PR workflow, branch koruma, gitignore kurallari.
> Tek yetkili kaynak: commit message formati, branch naming, PR workflow.
```

**ai-workflow.md**:
```markdown
> AI etkilesim kurallari: gorev yaklasimi, batch pattern, iletisim, yasakli eylemler, kalite kapilari.
> Tek yetkili kaynak: gorev tipi stratejisi, yasakli eylemler, iletisim kurallari, multi-agent strateji.
```

- [ ] **Step 2: Commit**

```bash
git add .claude/rules/
git commit -m "docs(rules): add purpose summaries and source-of-truth annotations to all rule files"
```

---

### Task 13: ai-workflow.md sadelestirme

**Files:**
- Modify: `.claude/rules/ai-workflow.md`

- [ ] **Step 1: "Quality Gates" bolumunu (satirlar 96-119) sadelestir**

Mevcut detayli checklist'i 3 satirlik ozet + referans ile degistir:

```markdown
## 4. Kalite Kapilari (Quality Gates)

Her duzenleme sonrasi, dosya tamamlandiginda ve gorev tamamlandiginda zihinsel kontrol yap:
- Anti-pattern kontrolu (17 madde): `CLAUDE.md` → "Critical Anti-Patterns" referans
- Dart/Flutter konvansiyonlari: `coding-standards.md` referans
- Proje-ozel kontroller: localization sync, SyncOrchestrator kaydi, schemaVersion

> Detayli kontrol listeleri: `coding-standards.md` → tum anti-pattern aciklamalari
```

- [ ] **Step 2: "Self-Review Kontrol Listesi" bolumunu (satirlar 178-196) sadelestir**

```markdown
## 7. Self-Review Kontrol Listesi

Kod degisikligi teslim oncesi 3 alan kontrol et:
1. **Mimari uyum**: Katman kurallari, feature-first yapi, offline-first pattern → `architecture.md`
2. **Dart/Flutter konvansiyonlari**: Naming, style, const, super.key → `coding-standards.md`
3. **Proje-ozel**: AppSpacing, Theme, AppIcon, .tr(), AppLogger, equalsValue → `coding-standards.md` → "Must NOT Do"
```

- [ ] **Step 3: "Versiyon & Migration Guvenligi" bolumunu (satirlar 223-248) referansa donustur**

```markdown
## 11. Versiyon & Migration Guvenligi

> Detayli migration kurallari: `database.md` → "Migration Pattern" ve "Migration Rules"
> Detayli model degisiklik sureci: `new-feature-checklist.md` → "1.1-1.12"

Ozet: schemaVersion artir, switch case ekle, _migrateVxToVy helper olustur, sutun silme YASAK.
```

- [ ] **Step 4: "Performans Farkindaligi" bolumunu (satirlar 250-262) sadelestir**

```markdown
## 12. Performans Farkindaligi

> Detayli performans kurallari: `architecture.md` → "Performance Guidelines" ve "Performance Measurement"

Ozet: const agresif kullan, gereksiz rebuild'den kacin, ListView.builder, COUNT sorgu, batch insert.
Gereksiz is yapma: Kullanicinin istemedigini optimizasyonu yapma, "belki lazim olur" kodu ekleme.
```

- [ ] **Step 5: Dosyanin toplam satir sayisini kontrol et**

Run: `wc -l .claude/rules/ai-workflow.md`
Expected: ~240 satir (322'den azalma)

- [ ] **Step 6: Commit**

```bash
git add .claude/rules/ai-workflow.md
git commit -m "refactor(rules): simplify ai-workflow.md with cross-references (~80 lines reduced)"
```

---

### Task 14: Tekrar eden icerikleri referansa donustur

**Files:**
- Modify: `.claude/rules/architecture.md`, `.claude/rules/new-feature-checklist.md`, `.claude/rules/database.md`

- [ ] **Step 1: architecture.md'deki sync flow detayini referansa donustur**

Mevcut "Sync Flow Detail" bolumundeki (satirlar ~80-115) detayli kod ornegini koruyup, basina not ekle:

```markdown
> Tam sync kurallari ve anti-pattern'ler: `supabase_rules.md`
```

- [ ] **Step 2: architecture.md'deki provider chain referansini ekle**

"Data Flow" bolumune ekle:

```markdown
> Detayli provider tipleri ve chaining pattern: `providers.md`
```

- [ ] **Step 3: new-feature-checklist.md'deki model pattern referansini ekle**

Step 1.1 "Freezed Model" basligina ekle:

```markdown
> Detayli Freezed 3 kurallari: `coding-standards.md` → "Model Rules (Freezed 3)"
```

- [ ] **Step 4: database.md'deki migration bolumune referans ekle**

Migration Pattern bolumune ekle:

```markdown
> Tam migration checklist: `new-feature-checklist.md` → "1.7 Register in Database"
```

- [ ] **Step 5: Commit**

```bash
git add .claude/rules/
git commit -m "docs(rules): add cross-references for single source of truth"
```

---

### Task 15: verify_rules.py'a cross-reference dogrulamasi ekle

**Files:**
- Modify: `scripts/verify_rules.py`

- [ ] **Step 1: Cross-reference checker fonksiyonu ekle**

main() fonksiyonunun sonunda, ozet ciktisindan once:

```python
    print(f"\n{Colors.BOLD}10. Cross-References{Colors.RESET}")
    rules_dir = ROOT / ".claude" / "rules"
    ref_pattern = re.compile(r'`(\w[\w-]*\.md)`\s*→\s*"([^"]+)"')
    broken_refs = 0
    for rule_file in sorted(rules_dir.glob("*.md")):
        content = rule_file.read_text(encoding="utf-8")
        for match in ref_pattern.finditer(content):
            target_file = rules_dir / match.group(1)
            target_section = match.group(2)
            if not target_file.exists():
                print(f"  {Colors.YELLOW}WARN{Colors.RESET} {rule_file.name}: kirik referans → {match.group(1)}")
                broken_refs += 1
            else:
                target_content = target_file.read_text(encoding="utf-8")
                if target_section.lower() not in target_content.lower():
                    print(f"  {Colors.YELLOW}WARN{Colors.RESET} {rule_file.name}: bolum bulunamadi → {match.group(1)} → \"{target_section}\"")
                    broken_refs += 1
    if broken_refs == 0:
        print(f"  {Colors.GREEN}PASS{Colors.RESET} Tum cross-reference'lar gecerli")
    else:
        print(f"  {Colors.YELLOW}WARN{Colors.RESET} {broken_refs} kirik referans bulundu")
```

- [ ] **Step 2: Test et**

Run: `python scripts/verify_rules.py 2>&1 | grep "Cross-Reference"`
Expected: `10. Cross-References` baslik ciktisi

- [ ] **Step 3: Commit**

```bash
git add scripts/verify_rules.py
git commit -m "feat(scripts): add cross-reference validation to verify_rules.py"
```

---

### Task 16: CLAUDE.md stats guncellemesi ve nihai dogrulama

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: CLAUDE.md'deki checker stats satirini guncelle**

Mevcut: `python scripts/verify_code_quality.py    # Anti-pattern scan (11 checkers, 10/17 CLAUDE.md patterns)`
Yeni: `python scripts/verify_code_quality.py    # Anti-pattern scan (17 checkers, 16/17 CLAUDE.md patterns)`

Not: #16 (Hardcoded SVG paths) dusurulebilir otomasyon kapsami disinda — AppIcons convention'i yeterli koruma saglar.

- [ ] **Step 2: verify_rules.py --fix calistir**

Run: `python scripts/verify_rules.py --fix`
Expected: Stats tablosu guncellenir

- [ ] **Step 3: Tum CI kontrollerini calistir**

Run: `python scripts/verify_code_quality.py && python scripts/verify_rules.py && python scripts/check_l10n_sync.py`
Expected: Tumu basarili (exit code 0)

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md .claude/rules/ scripts/
git commit -m "chore: update CLAUDE.md stats and verify all CI checks pass"
```

---

## Task Summary

| Task | Batch | Icerik | Dosyalar |
|------|-------|--------|----------|
| 1 | B1 | Whitelist + severity altyapi | verify_code_quality.py |
| 2 | B1 | Enum toplama helper | verify_code_quality.py |
| 3 | B1 | context.go checker | verify_code_quality.py |
| 4 | B1 | controller.dispose checker | verify_code_quality.py |
| 5 | B1 | @JsonKey checker | verify_code_quality.py |
| 6 | B1 | 3 warning checker | verify_code_quality.py |
| 7 | B1 | Raporlama + exit code | verify_code_quality.py |
| 8 | B2 | Golden test + dosya boyutu + renk istisnasi | coding-standards.md |
| 9 | B2 | Admin + batch sync | supabase_rules.md |
| 10 | B2 | Performans olcum | architecture.md |
| 11 | B2 | Phase tanimlari | CLAUDE.md (rules) |
| 12 | B3 | Baslangic ozetleri | 11 kural dosyasi |
| 13 | B3 | ai-workflow sadelestirme | ai-workflow.md |
| 14 | B3 | Cross-reference'lar | 3 kural dosyasi |
| 15 | B4 | Cross-ref dogrulama | verify_rules.py |
| 16 | B4 | Stats guncelleme + nihai test | CLAUDE.md |
