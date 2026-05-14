# Migrations

İki migration sistemi paralel çalışır: **Drift schema migration** (local SQLite) ve **Supabase SQL migration** (remote Postgres). İkisi de versiyonlanır, sıralı, idempotent olmaz değildir.

## Drift Migration (Local)

### Schema Version
- `app_database.dart` içinde `schemaVersion = 22`
- Yeni table/column/index → version bump zorunlu
- Version atlama YOK (22 → 23, asla 22 → 25)

### Migration Strategy
```dart
@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) => m.createAll(),
  onUpgrade: (m, from, to) async {
    if (from < 22) {
      await m.addColumn(birds, birds.ringNumber);
      await m.createIndex(Index('idx_birds_ring', 'CREATE INDEX ...'));
    }
    // Sıralı, atlama yok
  },
  beforeOpen: (details) async {
    if (details.wasCreated) {
      // Seed data
    }
  },
);
```

### Column Add / Drop
- **Add column**: trivial, default value zorunlu (existing row için)
- **Drop column**: SQLite eski versiyonlarda zor — `ALTER TABLE DROP COLUMN` Drift 2.31+ destekler
- **Rename**: yeni column ekle, eski'yi UPDATE ile kopyala, eski'yi drop
- **Type değişikliği**: yeni column ekle, convert + copy, eski'yi drop (atomic değil, multi-step)

### Test Migration
```dart
test('migrates from v21 to v22 preserving data', () async {
  final db = await TestDatabase.atVersion(21);
  await db.into(db.birds).insert(legacyBird);
  await db.migrateTo(22);
  final migrated = await db.select(db.birds).getSingle();
  expect(migrated.ringNumber, isNotNull);
});
```

Drift test helper `setSchemaVersion(int)` ile geçmiş versiyondan upgrade simüle edilir.

### Drift Migration Checklist
- [ ] `schemaVersion` arttı (sıralı)
- [ ] `onUpgrade` handler eklendi
- [ ] Default value verildi (NOT NULL eklenirse)
- [ ] Index gerekli mi (filtre column'ları)
- [ ] Test: fresh DB + upgrade-from-previous
- [ ] Companion `.g.dart` regenerated

## Supabase SQL Migration (Remote)

### Dosya Naming
- Format: `YYYYMMDDHHmmss_short_description.sql`
- Örnek: `20260514120000_add_ring_number_to_birds.sql`
- Timestamp UTC, lexicographic sort = chronological run order
- 155 migration mevcut, sıralı uygulanır

### Migration File Structure
```sql
-- 20260514120000_add_ring_number_to_birds.sql

-- 1. Schema change
ALTER TABLE public.birds
  ADD COLUMN ring_number text;

-- 2. Index (filtre ediliyor mu?)
CREATE INDEX IF NOT EXISTS idx_birds_ring_number
  ON public.birds (ring_number)
  WHERE ring_number IS NOT NULL;

-- 3. RLS policy update (gerekiyorsa)
-- RLS already inherited from birds table

-- 4. Comments
COMMENT ON COLUMN public.birds.ring_number IS 'Optional banded ring identifier';
```

### Idempotency
Migration **tekrar uygulanırsa hata vermemeli** (CI replay, hotfix re-run):
```sql
-- CORRECT - idempotent
CREATE INDEX IF NOT EXISTS idx_birds_ring ON birds (ring_number);
ALTER TABLE birds ADD COLUMN IF NOT EXISTS ring_number text;
DROP POLICY IF EXISTS old_policy ON birds;

-- WRONG - second run fails
CREATE INDEX idx_birds_ring ON birds (ring_number);
ALTER TABLE birds ADD COLUMN ring_number text;
```

### RLS Policy in Migration
- Yeni tabloda RLS aç: `ALTER TABLE x ENABLE ROW LEVEL SECURITY;`
- Policy oluştur, `auth.uid()` bazlı user-scoping
- Policy değişikliği migration ile commit (asla console-only edit)
- Migration sonrası `scripts/verify_rls_staging.sql` çalıştır

```sql
ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users select own notes"
  ON public.notes FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "users insert own notes"
  ON public.notes FOR INSERT
  WITH CHECK (auth.uid() = user_id);
```

### Backfill Strategy
Yeni NOT NULL column eski row'lara default gerekir:
```sql
-- Step 1: add nullable
ALTER TABLE birds ADD COLUMN ring_number text;

-- Step 2: backfill (büyük tablo için batch'le)
UPDATE birds SET ring_number = 'UNKNOWN' WHERE ring_number IS NULL;

-- Step 3: enforce NOT NULL (ayrı migration, prod doğrulamasından sonra)
ALTER TABLE birds ALTER COLUMN ring_number SET NOT NULL;
```

Tek migration'da hepsi yapılırsa **table lock + downtime**. Production'da multi-step gerekir.

### Concurrent Index
Büyük tabloda index ekleme `LOCK` alır — `CONCURRENTLY` kullan:
```sql
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_birds_user
  ON public.birds (user_id);
```
Not: `CONCURRENTLY` transaction içinde çalışmaz, migration runner'ı buna göre ayarla.

### Function / Trigger / Edge Function
- Postgres function: `CREATE OR REPLACE FUNCTION` (idempotent)
- Trigger: `DROP TRIGGER IF EXISTS x; CREATE TRIGGER x ...`
- Edge function değil — Edge function'lar ayrı `supabase functions deploy` ile

### Rollback Strategy
- Migration **geri alınamaz** kabul et — forward-only
- Yanlışlık varsa: yeni migration ile geri çevir, eskisini silme
- DROP/DELETE migration'ları çok dikkatli — production data lost
- Backup kontrolü: Supabase otomatik daily backup, point-in-time recovery (7 gün)

### CI / Deploy
- Migration `main` branch'e merge edilince otomatik apply YAPILMAZ
- Manual apply: `supabase db push` (production env)
- Staging önce, prod sonra (24h test window)
- `supabase migration list` ile state kontrol

## Senkronizasyon (Drift ↔ Supabase)
- Drift schema değişti → Supabase migration de gerekli (genelde)
- Column ekleme: önce Supabase (forward compat), sonra Drift (app deploy)
- Column drop: önce Drift (app deploy), sonra Supabase (eski versiyon olmadığından emin ol)
- 30 günlük overlap window kullan — eski app versiyonu prod'da çalışabilir

## Migration Anti-Patterns
1. Version atlama (22 → 25)
2. `IF NOT EXISTS` / `IF EXISTS` kullanmamak (idempotent değil)
3. Tek migration'da NOT NULL backfill + drop (table lock)
4. `CONCURRENTLY` olmadan büyük tabloya index
5. RLS unutmak (yeni tablo herkese açık kalır — güvenlik açığı)
6. Migration'ı console-only edit ile yapmak (versiyonsuz, audit yok)
7. Migration dosyasını silmek/yeniden adlandırmak (history bozulur)
8. Rollback migration yazmak (forward-only philosophy)
9. Drift schema değişikliği için Supabase migration unutmak
10. Sensitive default value (`'temp@test.com'` gibi) — production'a sızar

> **İlgili**: data-layer.md (Drift + Supabase), security.md (RLS), release-ops.md (deploy), edge-functions.md (deploy ayrı pipeline)
