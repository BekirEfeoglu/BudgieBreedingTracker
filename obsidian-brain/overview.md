# Project Overview

## What the App Does

**BudgieBreedingTracker** is a comprehensive breeding management app for budgerigar breeders. It lets breeders:

- Track individual birds (name, gender, species, genetics, ring number, health)
- Manage breeding pairs, incubations, clutches, eggs, and chick hatch events
- Calculate genetics (Punnett square, epistasis, MUTAVI mutation rates)
- Record health events and veterinary notes
- View statistics and breeding performance charts
- Connect with a community marketplace and messaging
- Receive push notifications for hatching reminders and calendar events
- Export data and sync across devices via Supabase cloud

**Platform**: iOS + Android. **Languages**: Turkish (master), English, German.

## Architecture at a Glance

```
┌─────────────────────────────────────────────────────┐
│  UI (25 Feature Modules — screens, widgets)         │
└───────────────────┬─────────────────────────────────┘
                    │ ref.watch / ref.read
┌───────────────────▼─────────────────────────────────┐
│  Providers (Riverpod 3 — AsyncNotifier, Stream)     │
└───────────────────┬─────────────────────────────────┘
                    │ repository calls
┌───────────────────▼─────────────────────────────────┐
│  Repositories (23 entity + base + sync_metadata)    │
└──────────┬────────────────────────┬─────────────────┘
           │ DAO queries             │ remote upserts
┌──────────▼──────────┐  ┌──────────▼──────────────┐
│  Drift (local SQLite)│  │  Supabase (remote Postgres)│
│  20 tables, v24     │  │  27 remote sources        │
└─────────────────────┘  └────────────────────────────┘
```

## Key Design Decisions

### 1. Offline-First
- Drift local SQLite is the **source of truth for all UI reads**
- Network is never required to display data — all reads go through local DAOs
- Background sync pushes dirty records to Supabase when online
- See [[architecture/offline-first]]

### 2. Idempotent Writes
- All remote writes use `.upsert()` (never `.insert()`)
- Primary keys are client-generated UUIDs (`Uuid().v4()`)
- Safe to replay on retry or sync conflict
- See [[data-layer/sync-strategy]]

### 3. Server-Side Authority
- RLS policies enforced in Supabase — never modified from client
- Free tier limits validated by `validate-free-tier-limit` Edge Function
- Premium entitlement validated by `sync-premium-status` Edge Function
- User ID always from JWT claims, never from request body
- See [[patterns/security]]

### 4. 24 Anti-Patterns
Enforced by `scripts/verify_code_quality.py` (18 static checks + 6 extras). Key ones:
- `withOpacity()` → `withValues(alpha: x)`
- `context.go()` forward nav → `context.push()`
- `ref.watch()` in callbacks → `ref.read()`
- `print()` → `AppLogger`
- Hardcoded text → `.tr()`
- Full list: [[patterns/anti-patterns]]

### 5. 3-Language Parity
- Turkish is master language — all keys added to `tr.json` first
- CI blocks PRs with missing keys in `en.json` or `de.json`
- ~2,968 keys per language, 42 categories
- See [[patterns/l10n]]

## Codebase Stats (as of 2026-05-21)

| Metric | Value |
|--------|-------|
| Source files (lib/) | 989 Dart files |
| Test files | 901 files, 11,017+ tests |
| Feature modules | 25 |
| Drift tables / DAOs / Mappers | 20 each |
| Repositories | 23 entity + base + sync_metadata |
| Remote sources | 27 entity + base + 2 caches + providers |
| Freezed models | 30 model files |
| Domain services | 23 directories |
| Routes | 73 |
| Custom SVG icons | 84 constants, 84 files |
| Shared widgets | 28 |
| Enum files | 15 |
| Supabase constants | 146 |
| L10n keys | ~2,968 per language |
| DB schema version | 24 |
| Supabase migrations | 158 SQL files |
| Edge Functions | 8 |
