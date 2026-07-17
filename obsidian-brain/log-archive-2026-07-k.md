# Change Log Archive — July 2026 K

Archived July 2026 entries rotated out of [[log]] during the 2026-07-17 Git
hook and CI regression maintenance.

---

## [2026-07-12] refactor | All Edge functions use request-level DI handlers

All 12 Edge functions were extracted to the DI `handler.ts` pattern with
request-level Deno tests for 401/400/403/503/200 responses. Added 39 tests
(204→243). Behavior remained byte-identical and `config.toml`/`verify_jwt`
stayed unchanged.

## [2026-07-12] refactor | SupabaseConstants remote-source coverage expanded

Added 26 column/RPC constants and replaced 44 literals across eight remote
sources plus admin providers. No wire-value change.

## [2026-07-12] feat | Genetics explicit linkage phase shipped

Shipped `LinkagePhase` override, engine consultation, isolate/history
persistence (Drift v28), father-column UI, and the single-pair MVP.

## [2026-07-12] feat | Gamification streak system shipped

Shipped `user_streaks`, the `record_daily_checkin` RPC, tiered XP, 7/30/100-day
badges, home chip, celebration, and the 20:00 reminder.

## [2026-07-12] docs | Post-task suggestions contract — exactly 3 items

Clarified the agent communication contract at user request: after completing a
real task, replies end with exactly three specific, task-relevant next-step
suggestions. Updated `.claude/rules/chat.md` § Post-Coding Suggestions and
mirrored the compact rule into `AGENTS.md` § Communication (a59251c, f2641be).
[[sources/rules-index]]
