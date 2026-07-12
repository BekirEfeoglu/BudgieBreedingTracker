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

No open latent code surfaces are currently tracked.

## Designed But Never Built

| Design goal | Status | Owning rule |
|-------------|--------|-------------|
| Server-side kill-switch config (`app_config` table, `remoteConfigProvider`) | Does not exist. Don't confuse with `syncRealtimeServerKillSwitchProvider`, which DOES exist and works | `feature-flags.md` |
| Experimental dev menu ("5x tap Settings header", `experimental_*` flags) | Does not exist; only debug-gated route is `geneticsColorAudit` | `feature-flags.md` |
| Marketplace inline banner ads | Design target only; real banner call sites are home, calendar, bird/breeding/chick lists | `marketplace.md`, `ads.md` |
| Statistics free preview / custom range / AI insight | `/statistics` is all-or-nothing gated (premium OR rewarded ad); no per-chart free tier | `statistics.md` |
| Per-session listing in Settings → security | Only an explanation dialog + "sign out all sessions" — don't over-promise | `settings.md` |
| Local AI retry-once + cross-backend fallback | Transport is fail-fast, single backend (`config.isOpenRouter ? OpenRouter : Ollama`); first failure throws a typed `NetworkException`/`ValidationException` — no retry, no 2s backoff, no cross-backend fallback, no `AnalysisResult.unavailable()` type. The helper-not-gate contract still holds | `local-ai.md` § Fallback Chain |
| Local AI client-side rate limit (5/min, premium 2×) | Not client-enforced. Only bound is the `LocalAiCache` (8 entries / 10 min, a cache); OpenRouter 429 is upstream, not app-enforced. Rate limiting is future server-side work (rule's own Anti-Pattern #6) | `local-ai.md` § Cost & Size Guards |

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

## See Also

- [[cheat-sheet]] — task-oriented navigation
- [[sources/rules-index]] — rules → wiki map
- [[sources/agents-index]] — project-local agent routing
- [[log]] — when gaps were opened/closed
- [[index]]
