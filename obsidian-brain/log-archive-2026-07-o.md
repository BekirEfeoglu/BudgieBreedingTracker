# Change Log Archive — July 2026 O

Archived July 2026 entries (07-26 to 07-26) rotated out of [[log]] during the
2026-07-26 six-lane audit. Covers the agent read-only measurement, the skill
`allowed-tools` correction, and the registry-collector split.

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

## [2026-07-26] infrastructure | Correction: skill `allowed-tools` does not restrict the session

**Measured, and it disproves what two earlier entries today asserted.** With
`ui-ux-pro-max` active — declaring `allowed-tools: Read, Glob, Grep, Bash` — a
`Write` call succeeded. So in this harness a skill's `allowed-tools` does not
restrict the main session's tool set; the earlier claims that it "restricts a
session while the skill is active" and that "a restricted skill cannot edit
during its activation" are wrong, and the warning built on them was unnecessary.
Caveat on the caveat: this was observed under this project's permission mode, so
the safe reading is not "it never restricts" but "it cannot be relied on as a
boundary".

What survives: the field and the catalog column document what a skill's own
ritual does, and the CI check keeps them from contradicting each other. What
does not: any notion that an advisory skill is sandboxed. The declarations added
earlier today stay — they are honest intent, now correctly labelled — but
`skills-index` no longer implies enforcement. The agent read-only check is
different and remains a real boundary, because a subagent's `tools:` list IS its
complete tool set.

The lesson is the session's own theme aimed back at itself: I documented a
mechanism's behaviour from plausible reasoning instead of running it, and the
one-command probe took less time than the paragraph describing the risk.

## [2026-07-26] infrastructure | Registry collectors split out; archive merge direction matters

**`_rules_collectors.py` 1,101 → 748 lines.** The nine meta-layer registry and
inventory collectors moved to `_rules_registry.py` (369 lines) — they all answer
one question, "does this hand-maintained list still match the directory it
claims to enumerate", and they had grown to a third of a module about something
else. Imports go one way only, from `_rules_registry` into `_rules_collectors`,
never back. The split was caught being incomplete by the guard added hours
earlier: the new module was not named in CLAUDE.md and § Script inventory went
red immediately.

**Archive merge direction is load-bearing.** `-07-c` folded into `-07-b`, not
the reverse, because a dated entry in `-07-n` uses `log-archive-2026-07-b.md` as
its worked example of why `--rotate` picks a target by content rather than
filename. Merging the other way would have left that explanation pointing at a
file that no longer exists — the linter would not have caught it either, since
the reference is in backticks rather than a wikilink. 14 → 13 pages, 187 entries
preserved. Rule recorded in the catalog: grep the dated entries for an archive's
name before merging it.

## [2026-07-26] infrastructure | Skill posture settled, wiki inventories guarded, stub archives folded in

**`ui-ux-pro-max`'s posture was decided by its body, not its description.** The
catalog said `No` while the skill advertised "build, create, implement,
refactor" — a contradiction left open earlier. The body settles it: four steps
of analyze → run `search.py` → read guidelines, both scripts opening files
read-only, output documented as a terminal ASCII box or Markdown. Those verbs
are the skill's **trigger** ("When user requests UI/UX work (design, build,
create…), follow this workflow"), not its actions; it supplies a design system
the surrounding session implements, exactly like `mobile-design`. Both it and
`supabase-postgres-best-practices` gained `allowed-tools: Read, Glob, Grep,
Bash`, so all six skills now declare one. The posture check was then tightened:
an advisory row with no declaration is now itself a violation, because
`allowed-tools` restricts rather than grants — a `No` means nothing without it,
and these two are vendored, so a re-vendor would otherwise drop the line
silently. Consequence recorded rather than hidden: a restricted skill cannot
edit during its activation; deleting one line reverts it.

**Four wiki inventories guarded, none of which was actually drifting.** The
features index (24/24), services index (23/23) and tables catalog (20/20) were
complete — my first three probes said otherwise and were all my own regex's
fault, since those pages use `[[wikilinks]]` and full filenames rather than bare
backticked names. They are guarded anyway because `scripts.md` was 11 of 15
yesterday: same shape, same rot. Each page is matched by the exact token IT
uses, never a bare directory name — "more" and "home" are real feature modules
and a substring check would pass on any prose containing them.

**17 archive pages → 14, and deliberately not to 9.** The three hand-made stubs
(`06-early` 2 entries, `07-i` 1, `07-k` 5) folded into their chronological
neighbours; all 186 entries preserved, verified by comparing the date multiset
before and after. Merging the ~190-line pages would have gone further but was
rejected on evidence: dated entries still name those files (one in `07-f`
records rotating work "to [[log-archive-2026-07-f]]"), and fixing the link means
rewriting a dated entry, which this contract forbids. With the catalog no longer
riding in every session's context, the remaining benefit was tidiness. Two stale
navigation footers were corrected — both already wrong, one listing itself.

