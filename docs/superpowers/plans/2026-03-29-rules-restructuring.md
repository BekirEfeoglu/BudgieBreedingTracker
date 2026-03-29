# Rules Restructuring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure `.claude/rules/` to eliminate redundancy, fill gaps, and establish single sources of truth per topic.

**Architecture:** Documentation-only changes. Merge database+supabase into data-layer, widgets+navigation into ui-patterns, create new testing and error-handling guides. Root CLAUDE.md becomes minimal index.

**Tech Stack:** Markdown files only. No code changes.

**Spec:** `docs/superpowers/specs/2026-03-29-rules-restructuring-design.md`

---

## Task Dependency Order

```
Task 1: Create data-layer.md          (no deps)
Task 2: Create ui-patterns.md         (no deps)
Task 3: Create testing.md             (no deps)
Task 4: Create error-handling.md      (no deps)
Task 5: Rewrite coding-standards.md   (no deps)
Task 6: Update providers.md           (no deps)
Task 7: Update localization.md        (no deps)
Task 8: Update git-rules.md           (no deps)
Task 9: Update chat.md               (no deps)
Task 10: Update ai-workflow.md        (depends on Tasks 1-5 for correct references)
Task 11: Update new-feature-checklist (depends on Tasks 1-5 for correct references)
Task 12: Rewrite architecture.md      (depends on Task 1 for content removal)
Task 13: Delete old files             (depends on Tasks 1-2)
Task 14: Rewrite .claude/rules/CLAUDE.md (depends on Tasks 1-13)
Task 15: Rewrite root CLAUDE.md       (depends on Tasks 1-14)
Task 16: Verify cross-references      (depends on all)
```

Tasks 1-9 are independent and can be parallelized.

---

### Task 1: Create `data-layer.md`

**Files:**
- Create: `.claude/rules/data-layer.md`
- Reference: `.claude/rules/database.md` (source content)
- Reference: `.claude/rules/supabase_rules.md` (source content)

- [ ] **Step 1: Read source files**

Read both `database.md` (153 lines) and `supabase_rules.md` (180 lines) fully to understand all content that needs to be merged.

- [ ] **Step 2: Write `data-layer.md`**

Create `.claude/rules/data-layer.md` with the following structure and content. This is the full file:

```markdown
# Data Layer

> Drift (SQLite), Supabase, Repository, Sync, Storage, Cache, Edge Functions.
> Single source of truth for: schema version, migration pattern, DAO pattern, enum converter,
> repository pattern, sync architecture, conflict resolution, storage rules, cache management,
> RLS enforcement, admin layer exceptions.

## Local Database (Drift)

### Table Definition
\`\`\`dart
@DataClassName('BirdRow')
class BirdsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get gender => text().map(birdGenderConverter)();
  TextColumn get userId => text()();
  TextColumn get status => text().map(birdStatusConverter)();
  TextColumn get ringNumber => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'birds';
}
\`\`\`

### Enum Converter
\`\`\`dart
final birdGenderConverter = TypeConverter.extensionType<BirdGender, String>(
  mapToDart: (dbValue) => BirdGender.fromJson(dbValue),
  mapToSql: (dartValue) => dartValue.toJson(),
);
\`\`\`
Location: `lib/data/local/database/converters/enum_converters.dart`
Import enum types directly from source file, converters from converters file.

### DAO Pattern
\`\`\`dart
@DriftAccessor(tables: [BirdsTable])  // Import table DIRECTLY, not via app_database
class BirdsDao extends DatabaseAccessor<AppDatabase> with _$BirdsDaoMixin {
  BirdsDao(super.db);

  Stream<List<Bird>> watchAll(String userId) {
    return (select(birdsTable)
      ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false)))
      .watch()
      .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  Future<void> insertItem(Bird model) {
    return into(birdsTable).insertOnConflictUpdate(model.toCompanion());
  }

  Future<void> insertAll(List<Bird> models) async {
    await batch((b) {
      for (final model in models) {
        b.insert(birdsTable, model.toCompanion(), mode: InsertMode.insertOrReplace);
      }
    });
  }

  Future<void> softDelete(String id) {
    return (update(birdsTable)..where((t) => t.id.equals(id))).write(
      BirdsTableCompanion(isDeleted: const Value(true), updatedAt: Value(DateTime.now())),
    );
  }

  // Enum filtering — use equalsValue(), NOT equals()
  Future<List<Bird>> getByGender(String userId, BirdGender gender) async {
    final rows = await (select(birdsTable)
      ..where((t) => t.userId.equals(userId) &
              t.gender.equalsValue(gender) & t.isDeleted.equals(false)))
      .get();
    return rows.map((r) => r.toModel()).toList();
  }
}
\`\`\`

### Mapper Pattern
\`\`\`dart
extension BirdRowMapper on BirdRow {
  Bird toModel() => Bird(id: id, name: name, gender: gender, ...);
}
extension BirdModelMapper on Bird {
  BirdsTableCompanion toCompanion() => BirdsTableCompanion(
    id: Value(id), name: Value(name), gender: Value(gender),
    updatedAt: Value(DateTime.now()), isDeleted: Value(isDeleted),
  );
}
\`\`\`

### Key Drift Rules
1. DAO imports: import table DIRECTLY, NOT via app_database.dart
2. Enum filtering: `.equalsValue(enumValue)` NOT `.equals()`
3. Companion fields: `Value()` for all fields
4. Upsert: `insertOnConflictUpdate()`
5. Soft delete: `isDeleted: true` + `updatedAt: now()`, NOT actual delete
6. Reactive: `.watch()` for streams, `.get()` for futures
7. User-scoped: ALL queries filter by userId and `isDeleted.equals(false)`
8. build.yaml: `store_date_time_values_as_text: true`
9. Batch operations: use `batch()` for bulk inserts
10. Null safety: `.nullable()` for optional columns

## Migration

### Current Schema
- **Schema version**: 17
- **Pattern**: `for-loop + switch` (NOT if-else), each version has `_migrateVxToVy()` helper
- **beforeOpen**: `PRAGMA foreign_keys = ON` on every DB open
- **Performance indexes**: 30+ composite indexes added in v9

\`\`\`dart
@override
int get schemaVersion => 17;

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) => m.createAll(),
  onUpgrade: (m, from, to) async {
    for (var i = from + 1; i <= to; i++) {
      switch (i) {
        case 2: await _migrateV1ToV2(m);
        case 3: await _migrateV2ToV3(m);
        // ... each version calls _migrateVxToVy(m)
        case 9: await _migrateV8ToV9(m);  // 30+ performance indexes
      }
    }
  },
  beforeOpen: (details) async {
    await customStatement('PRAGMA foreign_keys = ON');
  },
);
\`\`\`

### Migration Rules
- ALWAYS increment schemaVersion + add switch case
- Extract each migration into `_migrateVxToVy(m)` helper
- NEVER delete columns (only add)
- `m.createTable()` for new tables, `m.addColumn()` for new columns
- Performance indexes: `IF NOT EXISTS` for idempotency

### Migration Validation Checklist
After adding a migration:
1. Verify schemaVersion incremented by exactly 1
2. New switch case matches new schemaVersion
3. Test fresh install (onCreate) still works
4. Test upgrade from previous version
5. Verify PRAGMA foreign_keys = ON still runs in beforeOpen
6. If adding indexes: use IF NOT EXISTS
7. Update CLAUDE.md stats table (DB schema version)

### Local-Only Entities
These entities have Drift table + DAO + mapper but NO remote source or repository.
Providers access DAO directly, not registered in SyncOrchestrator.

| Entity | Table | DAO | Why Local-Only |
|--------|-------|-----|----------------|
| GeneticsHistory | genetics_history | GeneticsHistoryDao | Calculation cache, no sync value |
| UserPreferences | user_preferences | UserPreferencesDao | Device-specific settings |
| NotificationSettings | notification_settings | NotificationSettingsDao | Device-specific config |

## Supabase Client

### Initialization
- Credential priority: `--dart-define` > `.env` > empty (Supabase unavailable)
- Provider: `supabaseClientProvider` → `Supabase.instance.client`
- Required: `SUPABASE_URL`, `SUPABASE_ANON_KEY`
- Optional: `SENTRY_DSN`, `SENTRY_ENVIRONMENT`

### Table & Bucket Constants
File: `lib/core/constants/supabase_constants.dart` — 94 constants.
- ALL table/bucket names from SupabaseConstants — NEVER hardcode strings
- Table/column names: snake_case (json_serializable handles camelCase)
- Bucket names: kebab-case (bird-photos, egg-photos, chick-photos, avatars, backups)

### Authentication
1. Map AuthException to localized .tr() keys — never show raw error messages
2. Check `mounted` before setState() after async auth operations
3. Use `context.go(AppRoutes.home)` after login (replaces stack)
4. Session auto-refresh handled by supabase_flutter
5. `currentUserIdProvider` returns `'anonymous'` when not authenticated
6. Password change requires re-authentication first

Auth providers (in `auth_providers.dart`):
- `authStateProvider` — StreamProvider (auth state changes)
- `isAuthenticatedProvider` — Provider<bool> (derived)
- `currentUserIdProvider` — Provider<String> (safe fallback)
- `authActionsProvider` — Provider<AuthActions>

### App Initialization Flow
1. Profile sync (pull) → determines user role
2. Sync auth metadata → profiles table
3. Notification initialization
4. Deferred full data sync via `Future.microtask()` → avoid splash jank

### Data Serialization
- `toSupabase()` extension strips created_at/updated_at (server-managed)
- json_serializable with `field_rename: snake` handles camelCase → snake_case
- `explicit_to_json: true` for nested serialization
- `@JsonKey(unknownEnumValue: X.unknown)` for safe enum deserialization

## Remote Source Pattern

- `BaseRemoteSource<T>`: standard with is_deleted soft delete
- `BaseRemoteSourceNoSoftDelete<T>`: Incubation, GrowthMeasurement, Profile
- Subclass: override tableName, fromJson, toSupabaseJson + domain queries
- 20 entity sources + base + 2 caches (providers in `remote_source_providers.dart`)

## Repository

### Variants
| Pattern | Use Case | Example |
|---------|----------|---------|
| BaseRepository + SyncableRepository | Standard entities | Bird, Nest, Event, Notification |
| + ValidatedSyncMixin | FK-dependent entities | Egg, Chick, EventReminder |
| ProfileRepository (custom) | Single-record, push-before-pull | Profile |
| SyncMetadataRepository | Local-only (no remote) | SyncMetadata |
| DAO directly | No remote, no repo | GeneticsHistory |

### Key Rules
- ALL writes: local-first (DAO → SyncMetadata → background push)
- ALL reads: from local DB (Drift streams for reactive UI)
- Pull: server-wins overwrites local
- Push: sends pending with error tracking
- Never call RemoteSource directly from UI → always through Repository

## Sync Architecture

### Flow
\`\`\`
User Action → Repository.save()
  → DAO.insertItem()                    # 1. Local SQLite write
  → SyncMetadataDao.markPending()       # 2. Record pending
  → SyncOrchestrator (periodic/manual)  # 3. Background push
    → RemoteSource.upsert()             # 4. Supabase upsert
    → SyncMetadataDao.delete()          # 5. Clear on success
    → SyncMetadataDao.markError()       # 5b. Track error on failure

Pull (server → local):
  → RemoteSource.fetchUpdatedSince(lastSyncedAt)
  → DAO.insertAll() via insertOnConflictUpdate  # Server-wins
  → Update lastSyncedAt timestamp
\`\`\`

### FK Push/Pull Order (SyncOrchestrator)
Layer 0→7: Profile → Birds+Nests → BreedingPairs → Clutches+Incubations → Eggs → Chicks → HealthRecords+Events+... → EventReminders

### Timing
- Periodic: 15 min incremental, full reconciliation every 6h
- Initial jitter: random 0–60s delay (prevents thundering herd, added to first cycle only)
- Network reconnect / manual: force full sync
- App init: deferred via Future.microtask()
- WiFi-only mode: skips sync on cellular when wifiOnlySyncProvider is true

### Sync Scheduling Providers (`sync_scheduling_providers.dart`)
- `periodicSyncProvider`: Timer.periodic every 15 min, auto-disposed
- `networkAwareSyncProvider`: triggers forceFullSync on offline→online transition
- `triggerManualSync(Ref)`: standalone function for UI-triggered sync

### Conflict Resolution: Server-Wins
- Strategy: last-write-wins via `insertOnConflictUpdate()`
- Push-then-Pull: push all pending, then pull remote
- Full reconciliation (24h): delete local orphans without pending metadata
- ProfileRepository: push-before-pull (single-record exception)

### Conflict History (`sync_conflict_providers.dart`)
- ConflictHistoryNotifier: DB-backed log, max 50 entries (FIFO)
- `persistedConflictCountProvider`: StreamProvider counting conflicts in last 24h

### Retry & Backoff
- Max 5 retries, exponential backoff: 30s → 10min cap, random jitter
- ValidatedSyncMixin: max 10 retries for FK-dependent entities
- Only SyncStatus.error records retried during periodic cycle

### Batch Sync Error Handling
- Partial success: each entity independent try-catch
- Chunk strategy: 100+ records → 50-record chunks, each independent
- Timeout: single entity push 30s, full sync 5 min
- Recovery: next cycle retries only error/pending records
- Logging: `AppLogger.info('sync', 'Chunk N: X success, Y failed')`

## Storage

File: `lib/data/remote/storage/storage_service.dart`

### Rules
1. ALL uploads via StorageService — never call client.storage directly
2. Bucket names from SupabaseConstants
3. File path: `{userId}/{entityId}/{timestamp}.{ext}`
4. Avatar: `{userId}/avatar.{ext}` (upsert overwrites)
5. Delete files when entity is deleted (cascade cleanup)

### File Validation (`storage_utils.dart`)
- `validateMagicBytes()`: checks file signature before upload
- Supported: JPEG (FF D8 FF), PNG (89 50 4E 47), GIF, WebP (RIFF+WEBP), HEIC (ftyp)
- `getMimeType()`: extension-based MIME type resolution
- `safeExtension()`: fallback to 'jpg' when missing
- All validation is client-side, pre-upload

### File Size Limits
| Bucket | Max Size | Compression |
|--------|----------|-------------|
| bird-photos | 5 MB | JPEG quality 85%, max 1920px width |
| egg-photos | 5 MB | JPEG quality 85%, max 1920px width |
| chick-photos | 5 MB | JPEG quality 85%, max 1920px width |
| avatars | 2 MB | JPEG quality 80%, max 512px width |
| backups | 50 MB | No compression (encrypted payload) |

## Cache Management

Two cache providers in `remote_source_providers.dart`:
- Caches serve as in-memory buffers for frequently accessed remote data
- Invalidation: caches cleared on successful sync pull
- No TTL — caches live until provider is disposed or manually invalidated
- Use `ref.invalidate()` to force cache refresh from UI (pull-to-refresh)

## Edge Functions

File: `lib/data/remote/supabase/edge_function_client.dart`
- `invoke(functionName, {body, headers})` → EdgeFunctionResult
- Function names: kebab-case, body keys: snake_case
- Always check `result.success` before accessing `result.data`

## RLS Enforcement
1. ALL queries include `.eq('user_id', userId)`
2. Soft delete queries include `.eq('is_deleted', false)`
3. Server RLS already configured — DO NOT modify
4. NEVER expose service_role key in client code
5. Column names always snake_case in queries

## Admin Layer Exceptions

Admin panel follows different rules than standard data flow:

**Admin-only tables**: admin_logs, admin_sessions, admin_rate_limits, security_events,
system_alerts, system_settings, system_metrics, system_status

**Exception rules**:
- These tables do NOT need RemoteSource/Repository — direct `client.from()` is acceptable
- Reason: admin panel is single-user (admin), no sync needed, RLS protects via admin role
- Location: `lib/features/admin/providers/` files only
- `verify_code_quality.py` whitelist: `check_direct_client_from` → `lib/features/admin/`
- This exception applies ONLY to files in `lib/features/admin/` — nowhere else

## Anti-Patterns (Data Layer Specific)

> Full anti-pattern list: `coding-standards.md` → "Anti-Patterns"

1. NO direct `client.from()` in UI/Feature layer → use Repository (except admin)
2. NO direct `client.storage` calls → use StorageService
3. NO hardcoded table/bucket names → use SupabaseConstants
4. NO camelCase column names in queries (userId wrong, user_id correct)
5. NO sending created_at/updated_at → use .toSupabase()
6. NO exposing service_role key in client code
7. NO missing user_id filter (RLS enforcement)
8. NO Realtime subscriptions → use polling-based sync
9. NO blocking sync in splash → use Future.microtask()
10. NO skipping FK validation on Egg, Chick, EventReminder
11. NO concurrent syncs → use _isSyncing flag
12. NO pull without push first for ProfileRepository
13. NO missing mounted check after async Supabase calls

## Part-File Pattern

> Canonical rules: `coding-standards.md` → "File Organization"

Used in data layer: `sync_time_helpers.dart` (part of sync_orchestrator),
`app_database_indexes.dart` (part of app_database).
```

- [ ] **Step 3: Verify file was created correctly**

Run: `wc -l .claude/rules/data-layer.md`
Expected: ~310 lines

- [ ] **Step 4: Commit**

```bash
git add .claude/rules/data-layer.md
git commit -m "docs(rules): create data-layer.md merging database and supabase rules"
```

---

### Task 2: Create `ui-patterns.md`

**Files:**
- Create: `.claude/rules/ui-patterns.md`
- Reference: `.claude/rules/widgets.md` (source content)
- Reference: `.claude/rules/navigation.md` (source content)

- [ ] **Step 1: Read source files**

Read both `widgets.md` (196 lines) and `navigation.md` (259 lines) fully.

- [ ] **Step 2: Write `ui-patterns.md`**

Create `.claude/rules/ui-patterns.md` with the full content from the design spec Bölüm 8. The file must include:
- Widget Types table
- AsyncValue.when() pattern with two empty states
- Screen Structures (list, detail, form with full code example)
- Card Widget Pattern
- Chart Patterns (states, skeletons, utilities)
- Shared Widgets catalog (19 widgets in table format)
- Navigation section: all 60 route constants, route groups table
- Navigation Methods table
- Route Ordering critical rule with code
- Edit Mode pattern
- Guards table
- Passing Data table

The full content was approved in design Bölüm 8.

- [ ] **Step 3: Verify file was created correctly**

Run: `wc -l .claude/rules/ui-patterns.md`
Expected: ~300 lines

- [ ] **Step 4: Commit**

```bash
git add .claude/rules/ui-patterns.md
git commit -m "docs(rules): create ui-patterns.md merging widgets and navigation rules"
```

---

### Task 3: Create `testing.md`

**Files:**
- Create: `.claude/rules/testing.md`

- [ ] **Step 1: Write `testing.md`**

Create `.claude/rules/testing.md` with the full content from design spec Bölüm 9. The file must include:
- Test Organization (file structure tree, naming)
- Test Types table (unit, widget, integration, e2e, golden)
- Test Structure (arrange → act → assert)
- Mocking with Mocktail (creating mocks, stubbing, fallback values)
- Provider Overrides (overriding providers, NotifierProviders, Riverpod 3 caveats)
- Widget Test Patterns (AsyncValue states, form submission, navigation)
- Database Tests (`AppDatabase.forTesting()`)
- Model Serialization Tests (round-trip, unknown enum)
- Localization in Tests
- Golden Tests (tag, update, platform, failures)
- E2E Test Harness
- Test Checklist for New Features (11 items)

The full content was approved in design Bölüm 9.

- [ ] **Step 2: Verify file was created correctly**

Run: `wc -l .claude/rules/testing.md`
Expected: ~280 lines

- [ ] **Step 3: Commit**

```bash
git add .claude/rules/testing.md
git commit -m "docs(rules): create testing.md with test patterns and mocking guide"
```

---

### Task 4: Create `error-handling.md`

**Files:**
- Create: `.claude/rules/error-handling.md`

- [ ] **Step 1: Write `error-handling.md`**

Create `.claude/rules/error-handling.md` with the full content from design spec Bölüm 10. The file must include:
- Error Flow Through Layers (12-step diagram)
- Error Types (AppException hierarchy, when-to-use table)
- Sentry Integration (setup, severity table, code examples, breadcrumb rules, anti-patterns)
- Error Handling by Layer (RemoteSource, Repository, Notifier, Widget with code)
- Error Localization (mapping strategy, l10n keys table, rules)
- Retry & Backoff (sync retry params table, HTTP status table, network retry)
- Rate Limiting (notification debounce, sync guard)
- Error Boundaries (per screen type)

The full content was approved in design Bölüm 10.

- [ ] **Step 2: Verify file was created correctly**

Run: `wc -l .claude/rules/error-handling.md`
Expected: ~290 lines

- [ ] **Step 3: Commit**

```bash
git add .claude/rules/error-handling.md
git commit -m "docs(rules): create error-handling.md with Sentry and retry strategy"
```

---

### Task 5: Rewrite `coding-standards.md`

**Files:**
- Modify: `.claude/rules/coding-standards.md`

- [ ] **Step 1: Read current file**

Read `.claude/rules/coding-standards.md` (219 lines) fully.

- [ ] **Step 2: Rewrite with expanded content**

Replace the entire file content with the approved design from Bölüm 6. Key changes:
- Header updated to English with "Single source of truth" declaration
- Anti-patterns expanded from 17 to 24, grouped by category, each with what/why/code
- Provider naming convention clarified (Notifier class name matches provider)
- Icon Rules section added (moved from widgets.md)
- Part-file pattern consolidated (canonical rules with when/when-not)
- Hardcoded color exceptions section added
- Static service pattern section added
- All Turkish headers translated to English

The full content was approved in design Bölüm 6.

- [ ] **Step 3: Verify file**

Run: `wc -l .claude/rules/coding-standards.md`
Expected: ~310 lines

- [ ] **Step 4: Commit**

```bash
git add .claude/rules/coding-standards.md
git commit -m "docs(rules): rewrite coding-standards with 24 anti-patterns and icon rules"
```

---

### Task 6: Update `providers.md`

**Files:**
- Modify: `.claude/rules/providers.md`

- [ ] **Step 1: Read current file**

Read `.claude/rules/providers.md` (297 lines) fully.

- [ ] **Step 2: Update content**

Replace the entire file with the approved design from Bölüm 7. Key changes:
- Header updated to English with "Single source of truth" declaration
- Provider naming clarified: Notifier class name matches provider name
- Local-only entity list references `data-layer.md` instead of inline
- Anti-pattern references point to `coding-standards.md`
- Riverpod 3 specifics formatted as table
- All Turkish text translated to English

The full content was approved in design Bölüm 7.

- [ ] **Step 3: Verify file**

Run: `wc -l .claude/rules/providers.md`
Expected: ~270 lines

- [ ] **Step 4: Commit**

```bash
git add .claude/rules/providers.md
git commit -m "docs(rules): update providers.md with English text and naming clarification"
```

---

### Task 7: Update `localization.md`

**Files:**
- Modify: `.claude/rules/localization.md`

- [ ] **Step 1: Read current file**

Read `.claude/rules/localization.md` (225 lines) fully.

- [ ] **Step 2: Update content**

Apply these changes:
- Translate header and section titles to English
- Add "Number & Date Formatting" section at the end (before any closing):
```markdown
## Number & Date Formatting
- Dates: use `DateFormat` from `intl` package with current locale
- Numbers: use `NumberFormat` for locale-aware decimal separators
- Currency: not used in app (no monetary data)
- Charts: axis labels must respect locale decimal format
\`\`\`dart
// Date formatting
DateFormat.yMd(context.locale.languageCode).format(date)

// Number formatting (chart axes, statistics)
NumberFormat.decimalPattern(context.locale.languageCode).format(value)
\`\`\`

> Error message localization: `error-handling.md` → "Error Localization"
```
- Add sync check command: `python scripts/check_l10n_sync.py` in Sync Check subsection
- Update "Single source of truth" header line to English

- [ ] **Step 3: Verify file**

Run: `wc -l .claude/rules/localization.md`
Expected: ~200 lines

- [ ] **Step 4: Commit**

```bash
git add .claude/rules/localization.md
git commit -m "docs(rules): update localization.md with English text and number formatting"
```

---

### Task 8: Update `git-rules.md`

**Files:**
- Modify: `.claude/rules/git-rules.md`

- [ ] **Step 1: Read current file**

Read `.claude/rules/git-rules.md` (150 lines) fully.

- [ ] **Step 2: Translate to English**

Replace all Turkish section headers and descriptions with English equivalents:
- "Commit conventions, branch naming, PR workflow, branch koruma, gitignore kurallari" → "Commit conventions, branch naming, PR workflow, branch protection, gitignore rules"
- Header: add "Single source of truth for: commit format, branch naming, PR workflow, .gitignore rules, branch protection."
- "Type'lar" → "Types"
- "Ornekler" → "Examples"
- "Kurallar" → "Rules"
- "Branch Isimlendirme" → "Branch Naming"
- "Commit Edilmemesi Gerekenler" → "Files That Must NOT Be Committed"
- "Guvenlik (ASLA commit etme)" → "Security (NEVER commit)"
- "Uretilen Dosyalar" → "Generated Files"
- "AI Arac Konfigurasyon" → "AI Tool Configuration"
- "Cikti ve Gecici Dosyalar" → "Output and Temporary Files"
- "Commit Edilmesi Gerekenler" → "Files That Should Be Committed"
- "Mevcut Repo'da Secret Varsa Yapilacaklar" → "If Secrets Found in Repo"
- "Branch Koruma" → "Branch Protection"
- "GitHub'da Ayarlama Adimlari" → "GitHub Setup Steps"
- All inline Turkish comments → English

Keep all code blocks, commands, and file paths unchanged.

- [ ] **Step 3: Verify file**

Run: `wc -l .claude/rules/git-rules.md`
Expected: ~150 lines (similar length)

- [ ] **Step 4: Commit**

```bash
git add .claude/rules/git-rules.md
git commit -m "docs(rules): translate git-rules.md to English"
```

---

### Task 9: Update `chat.md`

**Files:**
- Modify: `.claude/rules/chat.md`

- [ ] **Step 1: Read current file**

Read `.claude/rules/chat.md` (56 lines) fully.

- [ ] **Step 2: Update content**

Apply these changes:
- Translate header to English: "Response language (Turkish), post-coding suggestion format and categories."
- Add "Single source of truth for: response language rules, suggestion format."
- Keep "Yanit Dili: Turkce" section in Turkish (this IS the rule about Turkish responses)
- Translate "Kodlama Sonrasi Oneriler" header to English: "Post-Coding Suggestions (REQUIRED)"
- Keep suggestion format example in Turkish (it's a Turkish output example)
- Add two new categories to the table:

```markdown
| `[Error]` | Error handling, Sentry integration, retry strategy |
| `[Cache]` | Cache invalidation, ref.invalidate patterns |
```

- Update any references to old file names:
  - If any reference to `database.md` → `data-layer.md`
  - If any reference to `supabase_rules.md` → `data-layer.md`
  - If any reference to `widgets.md` → `ui-patterns.md`
  - If any reference to `navigation.md` → `ui-patterns.md`

- [ ] **Step 3: Verify file**

Run: `wc -l .claude/rules/chat.md`
Expected: ~60 lines

- [ ] **Step 4: Commit**

```bash
git add .claude/rules/chat.md
git commit -m "docs(rules): update chat.md with new categories and English headers"
```

---

### Task 10: Update `ai-workflow.md`

**Files:**
- Modify: `.claude/rules/ai-workflow.md`

- [ ] **Step 1: Read current file**

Read `.claude/rules/ai-workflow.md` (262 lines) fully.

- [ ] **Step 2: Rewrite with trimmed content**

Replace the entire file. Key changes:
- Translate all Turkish to English
- Header: "Single source of truth for: task type strategy, prohibited actions, communication rules, multi-agent strategy, context management."
- Keep sections: Task Approach Strategy table, Pre-Work Analysis, Code Writing Workflow (batch pattern), Communication Rules, Prohibited Actions, Multi-Agent Strategy, Error Recovery, Context Management
- Quality Gates section: replace inline anti-pattern list with references:
  ```markdown
  ## Quality Gates
  After each edit, mental check against:
  - Anti-patterns: `coding-standards.md` → "Anti-Patterns" (24 rules)
  - Error handling: `error-handling.md` → "Error Flow"
  - Testing: `testing.md` → "Test Checklist for New Features"
  - Data layer: `data-layer.md` → "Key Drift Rules" and "Anti-Patterns"
  ```
- Remove sections (replaced with references):
  - Section 7 "Self-Review Kontrol Listesi" → replaced by Quality Gates references
  - Section 11 "Versiyon & Migration Güvenliği" → add one line: `> Migration rules: \`data-layer.md\` → "Migration"`
  - Section 12 "Performans Farkındalığı" → add one line: `> Performance: \`architecture.md\` → "Performance Guidelines"`
  - Section 13 "Güvenlik Farkındalığı" → add one line: `> Security: \`architecture.md\` → "Security Layer" and \`data-layer.md\` → "RLS Enforcement"`
- Update all file references:
  - `database.md` → `data-layer.md`
  - `supabase_rules.md` → `data-layer.md`
  - `coding-standards.md` → stays same
  - `CLAUDE.md` → `coding-standards.md` (for anti-patterns)
  - `new-feature-checklist.md` → stays same

- [ ] **Step 3: Verify file**

Run: `wc -l .claude/rules/ai-workflow.md`
Expected: ~180 lines (down from 262)

- [ ] **Step 4: Commit**

```bash
git add .claude/rules/ai-workflow.md
git commit -m "docs(rules): trim ai-workflow.md, replace inline content with references"
```

---

### Task 11: Update `new-feature-checklist.md`

**Files:**
- Modify: `.claude/rules/new-feature-checklist.md`

- [ ] **Step 1: Read current file**

Read `.claude/rules/new-feature-checklist.md` (199 lines) fully.

- [ ] **Step 2: Update cross-references and expand testing**

Apply these changes throughout the file:

**Cross-reference updates:**
- All instances of `database.md` → `data-layer.md`
- All instances of `supabase_rules.md` → `data-layer.md`
- Section 1.1: `coding-standards.md` → "Model Rules" (stays same)
- Section 1.7: add reference "See `data-layer.md` → "Migration Validation Checklist""
- Section 6.1: "Critical errors reported to Sentry" → add "See `error-handling.md` → "Sentry Integration""
- Section 6.1: anti-pattern reference → "`coding-standards.md` → "Anti-Patterns" (24 rules)"

**Translate to English:**
- Header: "Step-by-step guide for creating new features (data → feature → nav → l10n → test)."
- "Single source of truth for: new feature creation workflow."
- All section headers and descriptions to English
- Keep checkbox format

**Expand Section 6.3 Testing:**
Replace current 3-item list with:
```markdown
### 6.3 Testing
> Full test patterns: `testing.md`

- [ ] Unit tests for domain services/calculators
- [ ] Model serialization round-trip test (toJson/fromJson)
- [ ] Unknown enum deserialization test
- [ ] Widget test: loading state renders
- [ ] Widget test: error state renders with retry
- [ ] Widget test: empty state (no data) renders with action
- [ ] Widget test: empty state (no results) renders without action
- [ ] Widget test: data state renders correctly
- [ ] Widget test: form validation (required fields)
- [ ] Widget test: form submission triggers notifier
- [ ] Mapper round-trip test (Row → Model → Companion)
```

- [ ] **Step 3: Verify file**

Run: `wc -l .claude/rules/new-feature-checklist.md`
Expected: ~210 lines

- [ ] **Step 4: Commit**

```bash
git add .claude/rules/new-feature-checklist.md
git commit -m "docs(rules): update checklist with new references and expanded testing"
```

---

### Task 12: Rewrite `architecture.md`

**Files:**
- Modify: `.claude/rules/architecture.md`

- [ ] **Step 1: Read current file**

Read `.claude/rules/architecture.md` (265 lines) fully.

- [ ] **Step 2: Rewrite with trimmed content**

Replace the entire file with the approved design from Bölüm 4. Key changes:
- Translate all Turkish to English
- Header: "Single source of truth for: tech stack, folder structure, layer import rules, security layer, encryption format, performance guidelines."
- Remove sections moved to `data-layer.md`:
  - "Offline-First Architecture" (full section) → replaced with one-line reference
  - "Sync Flow Detail" → removed (in data-layer.md)
  - "Repository Pattern" → replaced with one-line reference
  - "Database Tables" list → removed (in data-layer.md)
  - "Storage Rules" → removed (in data-layer.md)
  - "Supabase Rules" section → removed (in data-layer.md)
  - "Database Schema" → keep only schema version mention with reference
- Add references where content was removed:
  ```
  > Full data layer details: `data-layer.md`
  > Provider dependency chain: `providers.md`
  ```
- Keep sections: Project Overview, Tech Stack, Folder Structure, Data Flow (one-line + ref), Layer Hierarchy, Entity Data Path, Build & Code Generation, Important Constants, Security Layer, Encryption Architecture, Performance Guidelines, Responsive Design
- Remove "Custom SVG Icons (Phase 22)" section → now in `coding-standards.md` → "Icon Rules"

The full content was approved in design Bölüm 4.

- [ ] **Step 3: Verify file**

Run: `wc -l .claude/rules/architecture.md`
Expected: ~180 lines (down from 265)

- [ ] **Step 4: Commit**

```bash
git add .claude/rules/architecture.md
git commit -m "docs(rules): trim architecture.md, move data layer content to data-layer.md"
```

---

### Task 13: Delete old files

**Files:**
- Delete: `.claude/rules/database.md`
- Delete: `.claude/rules/supabase_rules.md`
- Delete: `.claude/rules/widgets.md`
- Delete: `.claude/rules/navigation.md`

- [ ] **Step 1: Verify new files exist and have correct content**

Run:
```bash
ls -la .claude/rules/data-layer.md .claude/rules/ui-patterns.md
```
Expected: both files exist with non-zero size.

- [ ] **Step 2: Verify no remaining references to old file names in new files**

Run:
```bash
grep -r "database\.md\|supabase_rules\.md\|widgets\.md\|navigation\.md" .claude/rules/ --include="*.md" | grep -v "data-layer.md" | grep -v "ui-patterns.md"
```
Expected: no output (or only references inside data-layer.md/ui-patterns.md pointing to themselves). If any other file still references old names, fix them before proceeding.

- [ ] **Step 3: Delete old files**

```bash
git rm .claude/rules/database.md .claude/rules/supabase_rules.md .claude/rules/widgets.md .claude/rules/navigation.md
```

- [ ] **Step 4: Commit**

```bash
git commit -m "docs(rules): remove merged files (database, supabase_rules, widgets, navigation)"
```

---

### Task 14: Rewrite `.claude/rules/CLAUDE.md`

**Files:**
- Modify: `.claude/rules/CLAUDE.md`

- [ ] **Step 1: Read current file**

Read `.claude/rules/CLAUDE.md` (74 lines) fully.

- [ ] **Step 2: Rewrite as cross-reference map**

Replace the entire file with the approved design from Bölüm 3. The file must include:
- File Ownership Map table (topic → authoritative file → section) covering all topics
- Anti-Pattern Quick Reference (numbered 1–24, one line each, no code examples)

No rule details — only navigation pointers.

The full content was approved in design Bölüm 3.

- [ ] **Step 3: Verify file**

Run: `wc -l .claude/rules/CLAUDE.md`
Expected: ~70 lines

- [ ] **Step 4: Commit**

```bash
git add .claude/rules/CLAUDE.md
git commit -m "docs(rules): rewrite rules index as cross-reference map"
```

---

### Task 15: Rewrite root `CLAUDE.md`

**Files:**
- Modify: `CLAUDE.md` (project root)

- [ ] **Step 1: Read current file**

Read `CLAUDE.md` (206 lines) fully.

- [ ] **Step 2: Rewrite as minimal index**

Replace the entire file with the approved design from Bölüm 2. The file must include:
- One-line project description
- Build & Development Commands (flutter + quality scripts)
- Codebase Stats table (same values, auto-verified by verify_rules.py)
- Rules index table (12 files with scope descriptions)
- Key File Locations (compact path list)

No anti-pattern lists, no architecture overview, no sync details. ~80 lines total.

The full content was approved in design Bölüm 2.

- [ ] **Step 3: Verify file**

Run: `wc -l CLAUDE.md`
Expected: ~80 lines

- [ ] **Step 4: Run verify_rules.py to check stats are still correct**

Run: `python scripts/verify_rules.py`
Expected: all checks pass (stats table values unchanged)

- [ ] **Step 5: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: rewrite root CLAUDE.md as minimal index"
```

---

### Task 16: Verify cross-references and run quality checks

**Files:**
- All `.claude/rules/*.md` files
- `CLAUDE.md`

- [ ] **Step 1: Run cross-reference check**

Run: `python scripts/verify_rules.py`
Expected: all checks pass, no broken cross-references.

If broken references found: fix the referencing file (update the target file name or section name), then re-run.

- [ ] **Step 2: Verify no references to deleted files remain**

Run:
```bash
grep -r "database\.md\|supabase_rules\.md\|widgets\.md\|navigation\.md" .claude/rules/ CLAUDE.md --include="*.md"
```
Expected: no output. If any matches: update the reference to the new file name (`data-layer.md` or `ui-patterns.md`).

- [ ] **Step 3: Verify all new files are correctly referenced in index**

Run:
```bash
grep -c "data-layer.md\|ui-patterns.md\|testing.md\|error-handling.md" CLAUDE.md .claude/rules/CLAUDE.md
```
Expected: each file appears in both index files.

- [ ] **Step 4: Count final file inventory**

Run:
```bash
ls .claude/rules/*.md | wc -l
```
Expected: 12 files (CLAUDE.md, architecture.md, data-layer.md, coding-standards.md, providers.md, ui-patterns.md, localization.md, testing.md, error-handling.md, new-feature-checklist.md, git-rules.md, ai-workflow.md, chat.md — actually 13 counting CLAUDE.md)

Run:
```bash
wc -l .claude/rules/*.md
```
Expected: total ~2400-2600 lines (similar to before but better organized)

- [ ] **Step 5: Run full quality suite**

Run:
```bash
python scripts/verify_rules.py
python scripts/verify_code_quality.py
python scripts/check_l10n_sync.py
```
Expected: all pass.

- [ ] **Step 6: Final commit if any fixes were needed**

```bash
git add -A .claude/rules/ CLAUDE.md
git commit -m "docs(rules): fix cross-references after restructuring"
```

Only commit if changes were made in steps 1-3.
