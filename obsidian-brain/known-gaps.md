# Known Gaps — Latent & Unshipped Surfaces

Central registry of things that **look implemented but are not** (model fields,
constants, or UI stubs without a working backend) and documented design goals
that were never shipped. The #1 agent mistake this page prevents: treating a
design target in a rule file — or a dangling code surface — as shipped behavior.

Each entry's owning rule file is authoritative. When a gap closes, update the
rule file AND remove the row here (same change — see `.claude/rules/documentation-sync.md`).

**Do not "fix" these silently.** Most need a schema migration and/or a product
decision; the owning rule file says what closing them requires.

## Latent Code Surfaces (code exists, doesn't work end-to-end)

- **`genetics_history` remote is dormant and its schema does not match Drift.**
  Drift has `fatherGenotype`/`motherGenotype`/`resultsJson`/`calculationVersion`/
  `fatherPhaseOverrides`; the Supabase table has `father_mutations`/
  `mother_mutations`/`results`/`deleted_at` and no `calculation_version`. Nothing
  syncs it — there is no remote source, repository or sync-registry entry, and
  the `SupabaseConstants.geneticsHistoryTable` constant was deleted on
  2026-07-26 because it was declared and never referenced, which made the table
  look like a live surface. Wiring sync later means reconciling the columns
  FIRST; otherwise it reproduces the 2026-07-08 `bird_id`/`mutation_tags` class,
  where a select against columns prod did not have returned 400.

| Surface | Reality | Owning rule |
|---------|---------|-------------|
| DM `MessageType.birdCard` / `listingCard` | Model getters exist (`message_model.dart`) and `MessageBubble._buildReferenceCard` renders both, but there is NO producer UI — the attachment sheet offers only photo. Deliberately hidden until real producers exist (`lib/core/constants/feature_flags.dart` comment) | `messaging.md` § Attachments |

## Designed But Never Built

- **Structured JSON logging in Edge Functions.** observability.md specified
  `{ts, level, event, user_id, extra}` with a controlled `event` dictionary, and
  claimed Dashboard multi-tenant filtering on `user_id` followed from it.
  Measured 2026-07-26: all 36 `console.*` calls across all 12 functions use
  plain `[fn-name] message` strings, so that filtering never existed. The rule
  now documents the shipped convention. Adopting the schema means one shared
  `logEvent()` helper plus all 12 functions at once — a partial rollout mixes
  two formats and breaks grep as well.

| Design goal | Status | Owning rule |
|-------------|--------|-------------|
| Server-side kill-switch config (`app_config` table, `remoteConfigProvider`) | Does not exist. Don't confuse with `syncRealtimeServerKillSwitchProvider`, which DOES exist and works | `feature-flags.md` |
| Experimental dev menu ("5x tap Settings header", `experimental_*` flags) | Does not exist; only debug-gated route is `geneticsColorAudit` | `feature-flags.md` |
| Marketplace inline banner ads | Design target only; real banner call sites are home, calendar, bird/breeding/chick lists | `marketplace.md`, `ads.md` |
| Statistics free preview / custom range / AI insight | `/statistics` is all-or-nothing gated (premium OR rewarded ad); no per-chart free tier | `statistics.md` |
| Per-session listing in Settings → security | Only an explanation dialog + "sign out all sessions" — don't over-promise | `settings.md` |
| Admin realtime moderation queue (`admin_reports` channel, live toast/badge) | No realtime code in `lib/features/admin/`; queue is `FutureProvider.autoDispose` + pull-to-refresh + post-action `ref.invalidate` | `admin.md` § Queue Refresh |
| Local AI retry-once + cross-backend fallback | Transport is fail-fast, single backend (`config.isOpenRouter ? OpenRouter : Ollama`); first failure throws a typed `NetworkException`/`ValidationException` — no retry, no 2s backoff, no cross-backend fallback, no `AnalysisResult.unavailable()` type. The helper-not-gate contract still holds | `local-ai.md` § Fallback Chain |
| Local AI client-side rate limit (5/min, premium 2×) | Not client-enforced. Only bound is the `LocalAiCache` (8 entries / 10 min, a cache); OpenRouter 429 is upstream, not app-enforced. Rate limiting is future server-side work (rule's own Anti-Pattern #6) | `local-ai.md` § Cost & Size Guards |
| DM general file/audio attachments (`chat-attachments` bucket) | Not shipped; no such bucket exists. Only photo attachments via `message-photos` | `messaging.md` § Attachments |
| Presence visibility modes + user-facing online UI | No `presence_visibility` setting, no `invisible`/`away` states, no conversation-list dot / profile last-seen. Presence is a boolean active/inactive session tracker whose ONLY consumer is the admin panel | `presence.md` § Unshipped Tasarım Hedefleri |
| User-password portable backup (PBKDF2) | Backup encrypts with the runtime device key (`EncryptionService`) — encrypted backups are NOT portable to another device; no PBKDF2/user-password flow exists | `data-io.md` § Encryption |
| Restore preview / wipe-and-restore | Restore is merge-upsert only — no record-count preview, no wipe option, no skip/overwrite/rename conflict UI | `data-io.md` § Restore Flow |
| `ValidationException.fieldErrors` field map | Exception carries only `(message, code?, originalError?)`; field-level errors come from sync validators, not the server | `forms-validation.md` § ValidationException Mapping |
| Cross-version Drift data-migration tests | Only a HEAD schema-consistency harness exists (`test/data/local/database/migration_test.dart`: version, 20 tables, sync_metadata unique index, FK). No per-version data-preservation test — historical snapshots were never captured, and `drift_dev schema`'s generated verifier fails to compile (`table_name` column → `tableName` field collides with `Table.tableName`) | `migrations.md` § Test Migration |
| DM scroll-up (load older messages) | `MessagingRepository.getMessages` has a `before` cursor but **no caller passes it** (`messaging_providers.dart` calls `getMessages(conversationId)` only), and `MessageDetailScreen._scrollController` has no `addListener`. A thread shows its newest 50 messages and nothing older is reachable | `messaging.md` § Pagination |
| DM 200-message in-memory cap | No such cap exists; the only practical bound is the single 50-message page fetch | `messaging.md` § Performance |
| New-message push for DMs | `send-push` has only two app callers, both admin-panel; no DB trigger/cron fires it for `messages`, nothing emits a `type: 'message'` payload, and `payloadToRoute` has no `message` branch. Recipients only learn of a DM with the app open (realtime) | `messaging.md` § Notification Integration |
| Marketplace monetization tier (boost/"öne çıkar", renew, listing expiry, edit window, premium photo quota, phone opt-in) | None exist: no `is_featured`/`expires_at`/`archived_at`/phone column on `marketplace_listings`, zero occurrences of `renew`, `marketplace_listings_update` has no time predicate, and `MarketplaceImagePicker.maxImages = 3` for everyone. The only premium difference is the 3-active-listing free cap (premium exempt) | `marketplace.md` § Premium Integration, § Listing Lifecycle |
| Monthly leaderboard + self-rank + leaderboard cache | `get_leaderboard` returns only the all-time top 100 (`total_xp DESC`, clamped `LIMIT ≤ 100`); `leaderboardProvider` is a bare `FutureProvider` with no TTL/`keepAlive`. No monthly board, no out-of-top-100 self position, no 5-minute cache — and no `MATERIALIZED VIEW` anywhere in the repo | `gamification.md` § Leaderboard |
| Calendar month-scoped query + TTL cache + 30-day lazy load | `eventsStreamProvider` streams **all** of the user's events via `watchAll` and filters by month in memory. `watchByDateRange` exists on the repo/DAO but has no calendar caller (DAO tests only). No per-month TTL cache, no age-based lazy loading | `calendar.md` § Performance |
| Community like-count cache | No like-count cache (TTL or otherwise). `likeCount` arrives on the post row and is adjusted optimistically ±1 with rollback; the row itself is subject to `CommunityPostCache`'s 5-minute TTL | `community.md` § Like / Reaction |

## Genetics Roadmap — Still Open

`dev-docs/genetics-improvement-roadmap.md` is a dated plan, not a shipped-state
source. D1/D2/D3, D4 (single-pair MVP, 2026-07-12), Q1/Q3, and I1 are
implemented; the items below are not.

| ID / design goal | Current reality | Owning contract |
|------------------|-----------------|-----------------|
| D4 residual: multi-pair simultaneous linkage phase | `LinkagePhaseControl` shipped (`Otomatik \| Coupling \| Repulsion`, persisted in `GeneticsHistory.fatherPhaseOverrides`, Drift schema v28) but exposes only the father's tightest active linked pair; if two independent pairs are heterozygous at once, the second stays `auto` with no control | `genetics.md` § Sex-Linked Linkage |
| Q2 mutation evidence metadata | `BudgieMutationRecord` has no typed `evidenceLevel`/`sourceIds`; disputes remain prose | `genetics.md` |
| I2 breeding genetics advisory | Breeding form shows inbreeding only; no combined offspring + viability card | `genetics.md`, `breeding-eggs.md` |
| M1 stale batch recompute | History shows stale rows but has no user-approved bulk recompute | `genetics.md` |
| I3 prediction vs actual | Genetics history is not linked to a breeding pair/chick outcome comparison | `genetics.md`, `statistics.md` |
| I4 AI → canonical genotype | AI prediction is review-only and does not seed calculator mutation IDs | `genetics.md`, `local-ai.md` |
| I5 multi-generation planner | Discovery/RFC target only; no simulator, beam/pruning path model, or premium decision | `genetics.md` |

## Deliberate Absences (decisions, not gaps — do not "add")

- **E2E encryption in DMs** — server must see content for moderation (`messaging.md`)
- **Genealogy rewarded-ad bypass** — product decision; statistics/genetics have it, genealogy doesn't (`genealogy.md`)
- **XP purchase / premium XP accelerator / loot boxes** — anti-gambling, store policy (`gamification.md`)
- **iCalendar RRULE recurrence engine** — over-engineering (`calendar.md`)
- **Manual timezone profile field** — device timezone only (`datetime-format.md`)
- **IP geolocation in marketplace** — privacy; user enters city manually (`marketplace.md`)
- **GDPR export behind premium** — data ownership: always free (`settings.md`)
- **DM orphan-photo GC job** — abandoned failed-photo uploads may leave small orphan objects in the private `message-photos` bucket; accepted, GC scheduled job is out of scope (`messaging.md` § Attachments retry/orphan contract)
- **Hosted release pipeline / automatic store publishing** — Codemagic was removed 2026-07-25 (`codemagic.yaml` deleted). `release-ready.yml` and `scripts/build_release.sh` deliberately produce **artifacts only**; every store upload is a manual user action. Do not re-add a publishing block or Play credential. Consequence to remember: Play version codes are package-global and are no longer resolved automatically — the `pubspec.yaml` build number must be checked against the package-wide Play maximum by hand (`release-ops.md` § Release Channels)

## See Also

- [[cheat-sheet]] — task-oriented navigation
- [[sources/rules-index]] — rules → wiki map
- [[sources/agents-index]] — project-local agent routing
- [[log]] — when gaps were opened/closed
- [[index]]
