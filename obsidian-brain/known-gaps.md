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
| Community pinned posts | `is_pinned` column + select exist; no client set/display/premium gate | `community.md` |
| DM attachments | `message_type` supports image, `image_url` column + `message-photos` bucket constant exist, but the input-bar attach button is a stub — no upload flow | `messaging.md`, `assets-images.md` |
| DM delivery status | No client-side sending/sent/failed field on `Message`, no per-bubble indicator. Partial: send failure surfaces a retry SnackBar and preserves text (2026-07-03) | `messaging.md` |
| Genealogy PNG export | `onCaptureImage` callback signature exists but is not wired to a RepaintBoundary capture — only PDF export works | `genealogy.md` |
| Feedback admin response | `adminResponse` model field exists; history card never displays it | `feedback.md` |
| Health record chick selector | Animal dropdown lists chicks, but the model only carries `birdId` — chick selection is NOT persisted (schema + migration + mixin work to fix) | `health-records.md` |

## Designed But Never Built

| Design goal | Status | Owning rule |
|-------------|--------|-------------|
| MFA recovery codes | No generation, UI step, or l10n keys exist (2026-07-02 audit) — a user who loses their authenticator has no self-service recovery | `auth.md`, `security.md` |
| Server-side kill-switch config (`app_config` table, `remoteConfigProvider`) | Does not exist. Don't confuse with `syncRealtimeServerKillSwitchProvider`, which DOES exist and works | `feature-flags.md` |
| Experimental dev menu ("5x tap Settings header", `experimental_*` flags) | Does not exist; only debug-gated route is `geneticsColorAudit` | `feature-flags.md` |
| Gamification streaks (miss tolerance, 7/30/100-day bonuses, anti-fraud) | Only flat `dailyLogin: 5` XP with server-enforced daily limit 1 | `gamification.md` |
| Read-receipt privacy toggle | Every read is recorded unconditionally; no opt-out setting | `messaging.md` |
| Marketplace inline banner ads | Design target only; real banner call sites are home, calendar, bird/breeding/chick lists | `marketplace.md`, `ads.md` |
| Statistics free preview / custom range / AI insight | `/statistics` is all-or-nothing gated (premium OR rewarded ad); no per-chart free tier | `statistics.md` |
| Scheduled auto-backup UI | `BackupScheduler` design exists but backup screen has no scheduling UI | `settings.md`, `data-io.md` |
| Per-session listing in Settings → security | Only an explanation dialog + "sign out all sessions" — don't over-promise | `settings.md` |
| Calendar reminder editing | Reminder-offset dropdown shows only on event CREATE; edit does not manage reminders | `calendar.md` |
| Feedback rate limit | None (client or server) — known spam vector; if added, must be server-side | `feedback.md` |

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
- [[log]] — when gaps were opened/closed
- [[index]]
