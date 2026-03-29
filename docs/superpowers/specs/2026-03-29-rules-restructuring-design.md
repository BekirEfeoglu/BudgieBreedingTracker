# Rules Restructuring — Design Spec

> Comprehensive restructuring of `.claude/rules/` files: eliminate redundancy, fill gaps,
> optimize file structure, establish single sources of truth.

## Problem Statement

Analysis of 13 rule files + root CLAUDE.md identified 28 issues across 7 categories:
- **Redundancy**: anti-pattern list repeated 3x, sync architecture in 3 files, schema version hardcoded in 3 places
- **Gaps**: no testing guide, no error handling strategy, vague Sentry rules, missing file upload limits
- **Inconsistency**: local-only entity list varies, enum converter import rules conflict, part-file pattern described 3 ways
- **Structure**: no clear entry point, one-way cross-references, git-rules.md missing from index

## Design Decisions

1. **File structure**: merge by architectural layer (database+supabase → data-layer, widgets+navigation → ui-patterns)
2. **Language**: all rules in English; only `chat.md` preserves Turkish response language rule
3. **Detail level**: comprehensive reference with full code examples (~300 lines/file target)
4. **Root CLAUDE.md**: minimal index (~80 lines) — build commands, stats table, file map only
5. **Single source of truth**: each topic owned by exactly one file, others cross-reference

## File Structure (Before → After)

### Before (13 files + root CLAUDE.md)
```
CLAUDE.md                          # 206 lines — mixed index + details
.claude/rules/
├── CLAUDE.md                      # 74 lines — partial index
├── architecture.md                # 265 lines — includes sync/storage details
├── coding-standards.md            # 219 lines — missing icon rules from widgets.md
├── database.md                    # 153 lines — overlaps with supabase_rules.md
├── supabase_rules.md              # 180 lines — overlaps with database.md
├── providers.md                   # 297 lines — ok
├── widgets.md                     # 196 lines — icon rules duplicated in coding-standards
├── navigation.md                  # 259 lines — separate from related widgets
├── localization.md                # 225 lines — ok
├── new-feature-checklist.md       # 199 lines — stale cross-references
├── git-rules.md                   # 150 lines — missing from index
├── ai-workflow.md                 # 262 lines — duplicates anti-patterns inline
└── chat.md                        # 56 lines — ok
```

### After (12 files + root CLAUDE.md)
```
CLAUDE.md                          # ~80 lines — minimal index only
.claude/rules/
├── CLAUDE.md                      # ~70 lines — cross-reference map + anti-pattern quick ref
├── architecture.md                # ~180 lines — tech stack, layers, security, encryption, perf
├── data-layer.md                  # ~310 lines — NEW (database.md + supabase_rules.md merge)
├── coding-standards.md            # ~310 lines — all 24 anti-patterns, naming, icons, models
├── providers.md                   # ~270 lines — provider types, ref rules, special patterns
├── ui-patterns.md                 # ~300 lines — NEW (widgets.md + navigation.md merge)
├── localization.md                # ~200 lines — trimmed, added number/date formatting
├── testing.md                     # ~280 lines — NEW (test patterns, mocking, golden tests)
├── error-handling.md              # ~290 lines — NEW (error flow, Sentry, retry, localization)
├── new-feature-checklist.md       # ~200 lines — updated cross-references + expanded testing
├── git-rules.md                   # ~150 lines — translated to English
├── ai-workflow.md                 # ~180 lines — trimmed, references instead of duplicates
└── chat.md                        # ~60 lines — Turkish response language preserved
```

### Changes Summary
| Action | Files |
|--------|-------|
| **Merged** | database.md + supabase_rules.md → `data-layer.md` |
| **Merged** | widgets.md + navigation.md → `ui-patterns.md` |
| **Created** | `testing.md` (new) |
| **Created** | `error-handling.md` (new) |
| **Deleted** | `database.md`, `supabase_rules.md`, `widgets.md`, `navigation.md` |
| **Rewritten** | Root `CLAUDE.md` (minimal index) |
| **Rewritten** | `.claude/rules/CLAUDE.md` (cross-reference map) |
| **Updated** | All remaining files (references, deduplication, English) |

## File Ownership Map

| Topic | Single Source File |
|-------|-------------------|
| Tech stack, layer hierarchy, folder structure | `architecture.md` |
| Security (cert pinning, inactivity guard) | `architecture.md` |
| Encryption (AES-256, format versioning) | `architecture.md` |
| Performance guidelines & measurement | `architecture.md` |
| Drift tables, DAO, mapper, converter | `data-layer.md` |
| Migration pattern, schema version (17) | `data-layer.md` |
| Supabase auth, remote source pattern | `data-layer.md` |
| Sync architecture, conflict resolution | `data-layer.md` |
| Repository pattern & variants | `data-layer.md` |
| Storage service, file validation & limits | `data-layer.md` |
| Cache management | `data-layer.md` |
| RLS enforcement | `data-layer.md` |
| Admin layer exceptions | `data-layer.md` |
| All 24 anti-patterns (numbered, with why) | `coding-standards.md` |
| Naming conventions (files, identifiers, providers) | `coding-standards.md` |
| Freezed 3 model pattern | `coding-standards.md` |
| Enum rules (unknown, converter, import) | `coding-standards.md` |
| SVG icon API (AppIcons, AppIcon, LucideIcons) | `coding-standards.md` |
| File size strategy, part-file pattern | `coding-standards.md` |
| Hardcoded color exceptions | `coding-standards.md` |
| Provider types & dependency chain | `providers.md` |
| ref usage (watch/read/listen/invalidate) | `providers.md` |
| Filter/search chaining pattern | `providers.md` |
| Provider disposal & special patterns | `providers.md` |
| Riverpod 3 specifics | `providers.md` |
| Widget types (Consumer, Stateful, Stateless) | `ui-patterns.md` |
| AsyncValue.when pattern (two empty states) | `ui-patterns.md` |
| Form screen pattern | `ui-patterns.md` |
| Card, list, detail screen structures | `ui-patterns.md` |
| Chart patterns (states, skeletons, utilities) | `ui-patterns.md` |
| Shared widget catalog (19 widgets) | `ui-patterns.md` |
| GoRouter routes (60), constants | `ui-patterns.md` |
| Route ordering, guards, edit mode | `ui-patterns.md` |
| Navigation methods (push/pop/go) | `ui-patterns.md` |
| L10n key structure & categories (35) | `localization.md` |
| .tr() usage, adding keys, sync workflow | `localization.md` |
| Number & date formatting | `localization.md` |
| Test patterns (unit, widget, integration, e2e) | `testing.md` |
| Mocking with mocktail, provider overrides | `testing.md` |
| Golden test workflow | `testing.md` |
| Test checklist for new features | `testing.md` |
| Error hierarchy (AppException types) | `error-handling.md` |
| Error flow through layers | `error-handling.md` |
| Sentry integration (what/when/how to report) | `error-handling.md` |
| Retry & backoff strategy, HTTP status rules | `error-handling.md` |
| Error localization mapping | `error-handling.md` |
| Rate limiting (notifications, sync) | `error-handling.md` |
| Commit format, branch naming | `git-rules.md` |
| PR workflow, branch protection | `git-rules.md` |
| .gitignore rules | `git-rules.md` |
| Task approach, batch pattern | `ai-workflow.md` |
| Prohibited actions | `ai-workflow.md` |
| Multi-agent strategy | `ai-workflow.md` |
| Response language (Turkish), suggestion format | `chat.md` |

## Redundancy Elimination

### Anti-Pattern List (most critical)
- **Before**: same 17 patterns in `coding-standards.md`, `CLAUDE.md`, `ai-workflow.md`
- **After**: full list (expanded to 24) only in `coding-standards.md`; others reference it
- `.claude/rules/CLAUDE.md`: one-line summary per pattern (no details)
- `ai-workflow.md`: "check coding-standards.md → Anti-Patterns (24 rules)"

### Sync Architecture
- **Before**: described in `architecture.md`, `supabase_rules.md`, `CLAUDE.md`
- **After**: only in `data-layer.md` → Sync Architecture section
- `architecture.md`: one-line data flow + "Full details: data-layer.md"

### Schema Version
- **Before**: "17" stated in `CLAUDE.md`, `database.md`, `architecture.md`
- **After**: only in `data-layer.md` → Migration section
- Root `CLAUDE.md` stats table: still shows 17 (auto-verified by `verify_rules.py`)

### Repository Pattern
- **Before**: described in `database.md`, `architecture.md`, `supabase_rules.md`
- **After**: only in `data-layer.md` → Repository section

### Icon API
- **Before**: described in `widgets.md`, `coding-standards.md`
- **After**: only in `coding-standards.md` → Icon Rules section

### Freezed Model Pattern
- **Before**: in `coding-standards.md`, `new-feature-checklist.md`
- **After**: full pattern in `coding-standards.md`; checklist references it

### Local-Only Entities
- **Before**: different lists in `architecture.md`, `database.md`, `providers.md`
- **After**: definitive table in `data-layer.md` with entity, table, DAO, and reason columns

## Gaps Filled

### testing.md (NEW — ~280 lines)
- Test file organization & naming conventions
- Test types table (unit, widget, integration, e2e, golden)
- Mocking with mocktail: creating mocks, stubbing, fallback values
- Provider overrides in widget tests (Riverpod 3 caveats)
- Widget test patterns: AsyncValue states, form submission, navigation
- Database tests with `AppDatabase.forTesting()`
- Model serialization tests (including unknown enum)
- Localization in tests
- Golden test workflow
- E2E test harness
- Test checklist for new features

### error-handling.md (NEW — ~290 lines)
- Error flow diagram through all layers (RemoteSource → Repository → Notifier → Widget)
- AppException hierarchy with "when to use each" table
- Sentry integration: what to report (severity table), how to report (code examples), breadcrumb rules
- Error handling patterns per layer with code examples
- Error localization mapping (exception type → l10n key)
- Retry & backoff strategy: parameters table, HTTP status rules
- Rate limiting: notification debounce, sync guard
- Error boundaries per screen type

### Migration Validation Checklist (in data-layer.md)
- 7-step checklist for validating new migrations

### File Upload Limits (in data-layer.md)
- Size limits per bucket with compression settings table

### Cache Management (in data-layer.md)
- Cache invalidation strategy, no TTL, ref.invalidate() pattern

### Number & Date Formatting (in localization.md)
- DateFormat and NumberFormat with locale-aware patterns

### Admin Exception Clarification (in data-layer.md)
- Explicit: exception applies ONLY to `lib/features/admin/` files

### Jitter Clarification (in data-layer.md)
- Explicit: jitter added to first cycle only, not every cycle

## Detailed File Designs

### Root CLAUDE.md (~80 lines)
- Build & development commands (flutter, dart, quality scripts)
- Codebase stats table (auto-verified by verify_rules.py)
- Rules index table (file → scope)
- Key file locations (compact path list)

### .claude/rules/CLAUDE.md (~70 lines)
- File ownership map table (topic → authoritative file → section)
- Anti-pattern quick reference (numbered 1–24, one line each, no details)

### architecture.md (~180 lines)
- Project overview
- Tech stack (full dependency list)
- Folder structure (feature-first tree)
- Data flow (one-line diagram + references)
- Layer hierarchy with import rules
- Entity data path (full chain)
- Build & code generation (build.yaml config)
- Important constants (incubation, app limits, spacing)
- Security layer (certificate pinning, inactivity guard)
- Encryption architecture (AES-256, format versioning)
- Performance guidelines & measurement
- Responsive design

**Removed from architecture.md** (moved to data-layer.md):
- Sync flow detail, conflict resolution, sync timing
- Repository pattern & variants
- Database tables list
- Storage rules
- Supabase rules summary

### data-layer.md (~310 lines)
Merge of database.md + supabase_rules.md.

Sections:
1. Local Database (Drift): table definition, enum converter, DAO pattern, mapper, key rules
2. Migration: current schema (v17), pattern, rules, validation checklist, local-only entities table
3. Supabase Client: initialization, constants, authentication, app init flow, serialization
4. Remote Source Pattern
5. Repository: variants table, key rules
6. Sync Architecture: flow diagram, FK order, timing (with jitter clarification), scheduling providers, conflict resolution, conflict history, retry & backoff, batch error handling
7. Storage: rules, file validation, file size limits table
8. Cache Management
9. Edge Functions
10. RLS Enforcement
11. Admin Layer Exceptions (explicit scope)
12. Anti-Patterns (data-layer specific, 13 rules)
13. Part-File Pattern (reference to coding-standards.md)

### coding-standards.md (~310 lines)
Single source for all anti-patterns + naming + style.

Sections:
1. Naming Conventions: files (suffix table), identifiers, provider names (with Notifier naming rule)
2. Anti-Patterns (24 rules): grouped by category (Flutter API, Drift, Riverpod, Logging, Icons, Enum Safety, Navigation, Style, Freezed, Error, Data Layer), each with what/why/code example
3. Code Style Rules: must-do list, spacing & touch targets with code
4. Model Rules (Freezed 3): full pattern + checklist
5. Enum Rules: core enums, filter enums, converter, import clarification
6. Icon Rules: AppIcons/AppIcon usage, LucideIcons, 6 shared widgets with Widget param, AppIcon widget
7. File Organization: size strategy, part-file pattern (canonical rules with when/when-not), class organization
8. Hardcoded Color Exceptions: genetics/budgie painter whitelist
9. Static Service Pattern: ActionFeedbackService exception

### providers.md (~270 lines)
Minimal changes from current.

Sections:
1. Provider Types & When to Use: Provider, StreamProvider.family, FutureProvider.family, NotifierProvider (simple + complex), Provider.family (computed async) — each with code example
2. Provider Dependency Chain: data layer → feature layer (synced) → feature layer (local-only)
3. Provider Chaining (Filter → Search → Display): 5-step pattern with code
4. ref Usage Rules: table + listen/invalidate patterns with code
5. Shared Providers: currentUserIdProvider, birdByIdProvider — don't duplicate
6. Provider Disposal: auto-dispose rules, ref.onDispose() pattern
7. Provider Organization: file conventions
8. Special Provider Patterns: static broadcast, DB-backed notifier, timer-based
9. Riverpod 3 Specifics: migration rules table (8 items)

### ui-patterns.md (~300 lines)
Merge of widgets.md + navigation.md.

Sections:
1. Widget Types: selection table (Consumer, ConsumerStateful, Stateless, private)
2. AsyncValue.when() Pattern: full code with two empty states rule
3. Screen Structures: list, detail, form (with full form screen code example)
4. Card Widget Pattern: code example
5. Chart Patterns: chart states, skeletons, utilities
6. Shared Widgets catalog: buttons, cards, dialogs, root-level (19 total)
7. Navigation (GoRouter): route constants (60), route groups table
8. Navigation Methods: push/pop/go/pushReplacement table
9. Route Ordering: critical rule with code example
10. Edit Mode: query parameter pattern
11. Guards: auth/admin/premium table
12. Passing Data: path params vs query params vs extra (with deep link survival)

### localization.md (~200 lines)
Trimmed, added number/date formatting.

Changes:
- Added: Number & Date Formatting section
- Added: `python scripts/check_l10n_sync.py` command in sync check
- Added: error-handling.md reference for error localization
- Kept: setup, usage patterns, key structure, rules, categories, naming conventions, language switching

### testing.md (~280 lines) — NEW
Full testing guide built from codebase patterns.

Sections:
1. Test Organization: file structure tree, naming
2. Test Types: table (unit, widget, integration, e2e, golden)
3. Test Structure: arrange → act → assert
4. Mocking with Mocktail: creating mocks, stubbing, fallback values
5. Provider Overrides: overriding providers, NotifierProviders, Riverpod 3 caveats
6. Widget Test Patterns: AsyncValue states, form submission, navigation
7. Database Tests: AppDatabase.forTesting()
8. Model Serialization Tests: round-trip, unknown enum
9. Localization in Tests: setup helper
10. Golden Tests: tag, update, platform, failures
11. E2E Test Harness: description
12. Test Checklist for New Features: 11-item checklist

### error-handling.md (~290 lines) — NEW
Consolidated from 4 files + new content.

Sections:
1. Error Flow Through Layers: 12-step diagram
2. Error Types: AppException hierarchy, when-to-use table
3. Sentry Integration: setup, what-to-report severity table, how-to-report code, breadcrumb rules, anti-patterns
4. Error Handling by Layer: RemoteSource, Repository, Notifier, Widget — each with code
5. Error Localization: mapping strategy, l10n keys table, rules
6. Retry & Backoff: sync retry params table, HTTP status table, network retry rules
7. Rate Limiting: notification debounce, sync guard
8. Error Boundaries: per screen type (list, detail, form, background, critical)

### new-feature-checklist.md (~200 lines)
Updated cross-references + expanded testing.

Changes:
- All "database.md" refs → "data-layer.md"
- All "supabase_rules.md" refs → "data-layer.md"
- Section 6.1: "coding-standards.md → Anti-Patterns (24 rules)"
- Section 6.1: Sentry → "error-handling.md → Sentry Integration"
- Section 6.3: expanded from 3 to 11 test items, references testing.md

### git-rules.md (~150 lines)
Minimal changes.

Changes:
- All Turkish section headers → English
- Added single-source-of-truth header line

### ai-workflow.md (~180 lines)
Trimmed from 262 lines.

Removed (replaced with references):
- Inline anti-pattern list → reference coding-standards.md
- Self-review checklist → references to authoritative files
- Version & migration safety → reference data-layer.md
- Performance awareness → reference architecture.md
- Security awareness → reference architecture.md + data-layer.md

Kept:
- Task approach strategy table
- Pre-work analysis (with updated references)
- Code writing workflow (batch pattern)
- Quality gates (reference-based)
- Communication rules
- Prohibited actions (full list — critical)
- Multi-agent strategy
- Error recovery procedures
- Context management

### chat.md (~60 lines)
Minimal changes.

Changes:
- Added suggestion categories: [Error], [Cache]
- Updated references to new file names
- Turkish response language rule preserved
- All non-Turkish-rule content stays English

## Implementation Notes

### Files to Delete
- `database.md` (content merged into data-layer.md)
- `supabase_rules.md` (content merged into data-layer.md)
- `widgets.md` (content merged into ui-patterns.md)
- `navigation.md` (content merged into ui-patterns.md)

### Files to Create
- `data-layer.md` (new)
- `ui-patterns.md` (new)
- `testing.md` (new)
- `error-handling.md` (new)

### Files to Rewrite
- Root `CLAUDE.md` (minimal index)
- `.claude/rules/CLAUDE.md` (cross-reference map)

### Files to Update
- `architecture.md` (remove moved content, update refs)
- `coding-standards.md` (expand anti-patterns, add icon rules)
- `providers.md` (update refs, minor improvements)
- `localization.md` (trim, add formatting section)
- `new-feature-checklist.md` (update all cross-refs, expand testing)
- `git-rules.md` (translate to English)
- `ai-workflow.md` (trim, replace inline content with refs)
- `chat.md` (add categories, update refs)

### Quality Script Impact
- `verify_code_quality.py`: no changes needed (checks source code, not rules)
- `verify_rules.py`: may need updates if it references specific rule file names
- `check_l10n_sync.py`: no changes needed

### Risk Assessment
- **Low risk**: all changes are documentation-only, no code changes
- **Migration**: old file names referenced in verify_rules.py may need updating
- **Ordering**: create new files before deleting old ones to avoid broken state
