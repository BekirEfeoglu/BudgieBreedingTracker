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

| Surface | Reality | Owning rule |
|---------|---------|-------------|
| DM `MessageType.birdCard` / `listingCard` | Model getters exist (`message_model.dart`) and `MessageBubble._buildReferenceCard` renders both, but there is NO producer UI — the attachment sheet offers only photo. Deliberately hidden until real producers exist (`lib/core/constants/feature_flags.dart` comment) | `messaging.md` § Attachments |

## Designed But Never Built

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
| Ring-number async unique check | No `ringNumberExists` repository method, no `validation.ring_taken` key — duplicate rings are not validated | `birds.md` § Liste & Detay, `forms-validation.md` |

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

## See Also

- [[cheat-sheet]] — task-oriented navigation
- [[sources/rules-index]] — rules → wiki map
- [[sources/agents-index]] — project-local agent routing
- [[log]] — when gaps were opened/closed
- [[index]]
