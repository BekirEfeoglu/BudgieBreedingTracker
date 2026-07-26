# Change Log

Chronological record of wiki updates. Format: `## [date] action | summary`

---

## [2026-07-26] follow-up | A stale xcconfig was overriding the fresh iOS defines

**The documented mitigation could not work.** Verifying that the version bump
reached the iOS config turned up a live release hazard. Current Flutter writes
the dart-defines into `Generated.xcconfig` as base64 `DART_DEFINES`; it does NOT
write `ios/Flutter/DartDefines.xcconfig`, which older versions used — a full
build refreshed the former and left the latter at its March mtime.
`Release.xcconfig` includes the legacy file AFTER the generated one and both
define `DART_DEFINES`, so the four-month-old copy silently **overrode** the
fresh values. Decoded, it carried the legacy Google project (118599620356, not
the current 720334450619) and **no `SENTRY_DSN`** — precisely the
crash-reporting-less release `build_release.sh` documents itself as preventing,
while the script never touches that file. Deleted; the claim was corrected in
seven places that all pointed readers at the wrong file.

**iOS builds mutate TRACKED files.** The same run rewrote
`Runner.entitlements` and emptied `com.apple.security.application-groups` —
the container the home widget shares with the app — and later runs bumped
`LastUpgradeVersion`. All reverted. `build_release.sh ios` runs a flutter build
too, so read `git status` after it.

**Silent failure paths closed.** Google/Apple native sign-in terminal branches
and both fail-closed moderation branches logged with `AppLogger.error`, which
only adds a breadcrumb. A moderation outage blocks every upload and post
app-wide while showing users a generic rejection, with zero production signal.

**Two docs describing things that never existed.** observability.md specified a
structured JSON edge-function log schema and the Dashboard filtering it would
enable — measured: all 36 `console.*` calls across all 12 functions are plain
prefixed strings. And `SupabaseConstants.geneticsHistoryTable` was declared but
never referenced, making a dormant table with a never-matching schema look
like a live surface. Both moved to known-gaps.

## [2026-07-26] release | Version bumped to 1.1.8+60

Two surfaces, because the version name is duplicated: `pubspec.yaml` (the source
iOS and Android both derive from) and `AppConstants.appVersion` (a hand-kept
copy rendered in the About section). `app_constants_test` asserts they match, so
they cannot drift silently — but a bump has to touch both.

Build number jumps 56 → 60 at the user's request. Play version codes are
package-global and Codemagic no longer resolves this, so exceeding the highest
code across ALL tracks is a manual pre-upload check.

Note `ios/Flutter/Generated.xcconfig` still reads the OLD version after a bump:
it is gitignored and only a `flutter build` rewrites it — `flutter pub get` does
not. Archiving from Xcode without running `scripts/build_release.sh ios` first
would package the previous version, the same staleness trap that shipped a
DSN-less release once.

## [2026-07-26] follow-up | The reverse-leg guard, the last unguarded ALTER, and an unreachable fix

**Two new cross-surface families (49 checks).** `check_rule_symbol_drift` proves
every symbol a doc NAMES exists; nothing proved a set the CODE defines is still
fully named. Both of the day's doc-drift findings were exactly that shape, so
guard classes must now be named in security.md § Route Guards and `FeatureFlags`
members in feature-flags.md. One-way — a rule may discuss a removed guard, not
omit a live one. Verified by deleting a mention of each and watching CI fail.

**The last unguarded column add.** `event_reminders` is created in v2→v3, and
`Migrator.createTable` materializes TODAY's definition — already carrying
`user_id`/`is_deleted`/`updated_at`. The v5→v6 step then ALTERed the same three,
so a database entering `onUpgrade` at v1 or v2 died on `duplicate column name`
and never opened. Window is exactly {1,2}; at v29 the live base is ~zero, so
this is hygiene, not an incident. Reproduced first — and the first fixture
failed on `birds.color_mutation` instead, because materializing the current
schema means a v2 fixture must strip every column the UNGUARDED v5/v7/v13/v15/
v17 steps add. Only then did the failure land on the statement under test.

**An "untested fix" that turns out to be unreachable.** `5845415` threaded
`onDepthLimit` into the nested `_inbreedingOf` traversal with no test, and the
existing depth test cannot fail (its shared ancestor is parentless, so the
nested path never runs). Measuring rather than assuming: that traversal restarts
depth at 0 but walks a SUBSET of the chain the top-level pass already walked,
starting deeper in absolute terms — so anything long enough to trip it there has
already tripped it here. Sweeping chain lengths 0..16 with and without the
propagation gave byte-identical results. No isolating test is possible; one
would pass regardless, which is the same vacuous-assertion trap fixed earlier
today. The propagation stays (it stops being redundant if the two bounds ever
stop sharing a chain), the finding is recorded in the source, and the test that
CAN fail — the `depthLimited` cutoff boundary — was added instead.

**Image-scan budget raised 10 → 30/min.** The scan runs once per image and the
largest legitimate burst is a premium post at 10 photos, so one attempt consumed
the whole per-user budget; any retry in the same minute returned 429, which
`ImageSafetyService` fails CLOSED into "image rejected". Same shape as the
client cooldown fixed hours earlier, one layer out. The Deno test pins the
relationship to the photo cap, not the number.

## [2026-07-26] audit | Six-lane sweep: a client cooldown was failing closed on every multi-photo post

**Headline, and it was reachable by ordinary users.** `EdgeFunctionClient`
applies a 10s per-function cooldown, and `scan-image-safety` / `moderate-content`
were not in `_rateLimitExempt`. Both callers fail CLOSED, so a cooldown reply is
indistinguishable from "moderation unavailable". Consequences, all verified in
source: a community post or marketplace listing with **2+ photos could never
succeed** (the scan runs in a `for` loop over images); a second bird/egg/chick/
avatar photo added within 10s was rejected as unsafe; and because the DM send
cooldown is 2s — shorter than 10s — the **second message of any normal
conversation** was rejected as `moderation_unavailable`. Both providers are
plain (non-autoDispose) `Provider`s, so the timestamp map lives for the session.
Fixed by exempting both; abuse control was already server-side and per-user
(scan 10/min, moderate 30/min, Supabase-backed). The rate-limit branch had zero
test coverage — that is why it was invisible; added tests.

**Fresh installs were missing three indexes.** `idx_events_egg_id`,
`idx_events_incubation_id` and `idx_conflict_history_user_created` existed only
inside their version steps (`_migrateV23ToV24` / `_migrateV15ToV16`), never in
the shared helper that `onCreate` runs. Upgraded installs had them; new users
silently full-scanned. This is the **inverse leg** of the 2026-07-25 bricking
incident — same helper, opposite direction. Mirrored into the helper behind
`_tableHasColumn` / `_tableExists` guards (the helper still runs from the v8→v9
step), and the indexes test's expected set now pins all three.

**A test that could never fail.** `multi_locus_masking_test` intersected
`visualMutations` (IDs, `'grey'`) with `maskedMutations` (display names,
`'Grey'`) — always empty, so its "never both" assertion passed regardless.
De-vacuuming it revealed the claimed invariant is **false by design**: masking
adds to `masked` without removing from `visual`, so `masked ⊆ visual` always.
Replaced with the subset check, which is precisely the v9 leaked-list signature,
plus a non-vacuity guard asserting something is actually masked.

**Doc drift, all rules-side.** `FounderGuard` gates `/community/*`,
`/marketplace/*` and `/ai-predictions` to founder-only, yet appeared in **none**
of the three rule files that enumerate guards, while community.md/marketplace.md
described those features as generally available — they are unreachable for every
non-founder, and messaging is transitively founder-only because its only entry
points live there. `FeatureFlags` carries six static flags; feature-flags.md
documented one. genetics.md promised an inbreeding "blocking warning + premium
override" — the gate is a confirm dialog at `>= 0.25` and **no premium override
exists anywhere in that path**. All corrected.

Also: capped `AppLogger._recentLogs` (unbounded, appended on every one of 900+
call sites, retaining raw error objects); stopped three Excel-import parsers
interpolating raw spreadsheet cells into release Sentry breadcrumbs; made the
OAuth-revoke failure reportable (its inner catch swallowed, leaving the caller's
`Sentry.captureException` dead code while the sibling FCM step reported); moved
7 hardcoded Supabase columns onto constants; and 3 domain icons onto `AppIcon`.
The `#8` checker was blind to the named `column:` form **and** skipped
`lib/features/admin/` entirely — both closed, verified by reintroducing the
violation and watching it fail.

## [2026-07-26] infrastructure | Agent read-only measured: a real gate, but not a sandbox

**Probed rather than assumed, and it corrects a claim from hours earlier.** A
`code-reviewer` run reported its actual tools. `Write` was emitted and refused
by the harness — *"No such tool available: Write. Write exists but is not
enabled in this context."* — with no file created. So the agent-side exclusion
is a genuine gate, unlike a skill's `allowed-tools`, which the same day's probe
showed restricts nothing.

Two findings that change how the guard should be read:

- **`Bash` is available, so read-only is behavioural, not technical.** `sed -i`,
  `echo >`, `git commit` and `rm` all stay reachable. The tool gate raises the
  cost of mutating; it does not prevent it. A read-only profile is not a
  containment measure.
- **The declared list is not the realized list.** `code-reviewer` declares
  `Read, Bash, Glob, Grep`; the running agent had only `Read` and `Bash`. The
  frontmatter diverges in *both* directions — it over-declares `Glob`/`Grep`
  while the harness independently withholds `Write`/`Edit`. My earlier phrasing,
  "a subagent's `tools:` list IS its complete tool set", is therefore wrong;
  read it as intent, not inventory. Single-context sample.

The registry check still earns its place: it keeps the **declaration** honest
and reviewable, which is what a human or agent reads before dispatching. It was
never able to prove a profile cannot write, and the docs now say so.

Also: the skills catalog column is renamed `Writes?` → **`Ritual writes?`**, so
it names what it actually asserts — what the skill's own steps do — rather than
implying a capability. The check parses the row's last cell, not the header, so
the rename is behaviour-neutral; proven against three different headers.

**Push batching recorded** in branch-workflow.md. Four successive pushes this
session left two intermediate commits superseded, one showing commit status
`failure` although every job was `cancelled`, not failed. Verification correctly
targets the tip, but an intermediate commit that never completes a round leaves
no evidence for `git bisect` or later review.

