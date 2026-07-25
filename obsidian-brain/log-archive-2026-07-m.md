# Change Log Archive — July 2026 M

Archived July 2026 entries (07-17 to 07-22) rotated out of [[log]] during the
2026-07-25 Codemagic-removal documentation sync.

---

## [2026-07-22] docs | Synchronize release and dependency snapshots

Updated the current build snapshot to `1.1.7+56` and aligned the Firebase Core
and RevenueCat package references with `pubspec.yaml` across rules and wiki pages.

## [2026-07-19] release | Bump the app version to 1.1.7+54

Updated the Flutter release version and runtime app metadata together. Android,
iOS Runner, and the dashboard widget continue to inherit the shared Flutter
build name and number.

## [2026-07-19] deploy | Enforce the scanned-image upload cap in production

Applied `20260717120000_align_scanned_image_upload_limits.sql` through an alias-mapped temporary CLI fixture so the remote ledger keeps the exact local version and SQL without rewriting historical migrations. Production now enforces 2 MiB on all seven safety-scanned image buckets, keeps `backups` at 50 MiB, and passes the online migration parity check.

## [2026-07-19] auth | Preserve post-login destinations and complete password recovery

Protected deep links survive OAuth, MFA, and startup through validated one-shot `returnTo` state. Recovery sessions stay on the new-password form until Supabase updates the password;
login UX adds bounded feedback, reduced motion, accessible controls, localized Apple labels, and four golden baselines.

## [2026-07-19] guard | Freeze the applied migration chain in a separate baseline fixture

Added an immutable filename/SHA-256 baseline through canonical `20260714200511` and recorded nine apply-time aliases without rewriting historical SQL.
The online guard parses only the remote ledger column and exposes `20260717120000` as the remaining explicit local-only migration.

## [2026-07-18] security-fix | Supabase RSA TLS fallback added to pin allowlist

Sentry release-54 telemetry from an Android 11 device exposed a false pinning
rejection while newer clients remained healthy. Live TLS reproduction showed
that the Supabase/Cloudflare endpoint serves the pinned ECDSA leaf to default
clients but a distinct Google Trust Services RSA leaf to RSA/TLS 1.2 clients.
The verified RSA fingerprint is now allowlisted alongside the ECDSA and
rotation-overlap pins; unknown certificates and production proxy connections
remain rejected. The rotation rule now requires checking both certificate
variants, with a focused regression for the RSA fallback.

## [2026-07-18] ci-fix | Android release build numbers are package-global

A signed Codemagic alpha release proved that Google Play reserves version codes
across tracks and uploaded artifacts: the alpha-scoped latest-build query chose
an already-used code. Android release versioning now queries the package-wide
Play maximum before incrementing, while the publishing destination remains the
alpha track. A static workflow contract prevents track-scoped regression.

## [2026-07-18] db-fix | Historical health-record migration no longer indexes a future column

Release-emulator Sentry verification exposed a v25 upgrade failure: the shared
performance-index helper attempted to index `health_records.chick_id` before
v27 added that column. The two chick indexes now use a schema-presence guard;
v27 invokes the helper again after adding the column. A file-backed sequential
v25→v29 regression preserves a legacy row and verifies the column plus indexes.

## [2026-07-18] auth-fix | Disabled guest CTA now matches server policy

Release-emulator verification found that the login screen advertised guest
access even though Supabase anonymous sign-ins are deliberately disabled.
Production now hides the guest CTA and limitation copy behind the matching
static client flag; card-level opt-in support remains for a future coordinated
server/RLS rollout, with client/server contract and widget regressions.

## [2026-07-18] ci-fix | Codemagic release SDK drift pinned to verified Flutter

The first store-free Android verification build reached signed AAB compilation
but Codemagic's moving `stable` channel had advanced to Flutter 3.44.6, where
locked `lucide_icons 0.257.0` no longer compiles because `IconData` is final.
All three Codemagic release workflows now pin Flutter 3.41.4, matching GitHub
Actions and Xcode Cloud; a static contract prevents silent channel drift.

## [2026-07-18] ci | Exact-SHA verifier recognizes only proven path-gated deploy skips

The remote status verifier now accepts a skipped `Deploy Edge Functions` job
only when `Edge Function Changes` completed successfully on the same commit.
This closes the false-negative for CI/docs-only pushes while preserving the
fail-closed behavior when the deployment detector fails or is missing.

## [2026-07-18] ci | Codemagic Android verification separated from store publishing

Added a manual `android-verify-only` workflow that produces a signed,
obfuscated AAB, uploads Dart symbols to Sentry, and retains both artifacts
without referencing Google Play credentials or declaring a publishing block.
Its version/build comes from the committed `pubspec.yaml`, so verification does
not query or mutate external store state; a static CI contract locks this down.

## [2026-07-17] ops | Production release Sentry monitoring enforced

Created the `budgie-breeding-tracker` Flutter project in the production Sentry
organization, stored its DSN in GitHub/Codemagic, verified ingestion with one
synthetic production event, and added an `org:ci`-only token plus
`sentry_dart_plugin` so obfuscated release symbols upload before publishing.

## [2026-07-17] chore | Supabase local SMTP config deprecation removed

Renamed the local email-capture section from deprecated `[inbucket]` to
`[local_smtp]`, matching Supabase CLI's current template without changing ports
or behavior. A static config regression prevents the warning from returning.

## [2026-07-17] ci-fix | Hook Flutter environment and Edge deploy regression repaired

The pre-commit hook now removes repository-local Git variables only for Flutter
subprocesses, preventing the SDK version from degrading to `0.0.0-unknown` in a
hook. Hook installation is worktree-relative and executable-safe. The Edge
deploy dependency regression now asserts the path guard alongside analyze,
Flutter, and Edge tests; a real hook-environment test covers the failure mode.
