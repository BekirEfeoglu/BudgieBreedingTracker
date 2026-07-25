# Change Log Archive — July 2026 N

Archived July 2026 entries (07-25 to 07-25) rotated out of [[log]] during the
2026-07-25 cross-surface-guard series. Covers the Codemagic removal and the
TLS pin freshness gate.

---

## [2026-07-25] release-ops | First real release build corrected the iOS artifact path

Ran `scripts/build_release.sh ios` end to end with a real Sentry token. Symbol
upload works: 127 debug files + the Dart obfuscation map uploaded, release
`com.budgiebreeding.tracker@1.1.7+56` created and finalized. But the build stops
at `build/ios/archive/Runner.xcarchive` — `flutter build ipa` cannot export an
IPA without an export-options plist, which Codemagic used to generate via
`xcode-project use-profiles` and nothing replaces locally. The script (and
release-ops.md, ci-cd.md, the store-release skill, CLAUDE.md § Release Builds)
claimed `build/ios/ipa/*.ipa`, a path that does not exist in this setup; the
script now reports whichever artifact was actually produced and fails if neither
is there. Found only by running it — every static check passed while the guidance
was wrong. CLAUDE.md was missed in the first pass and corrected in a follow-up:
release/deploy changes must land the owning rule AND CLAUDE.md together
(documentation-sync.md).
## [2026-07-25] security | TLS pin rotation lead time is now a CI gate

`security.md` required replacement fingerprints ≥14 days before expiry, but
nothing enforced it — a lapsed pin set leaves the app unable to reach the
backend at all, fixable only by a store release. `check_certificate_pin_freshness`
reads the earliest `valid <start> through <end>` comment above the pins and
fails `security-audit` inside that window (harsher message once expired);
39 → 40 controls. Writing the tests exposed a bug in the check itself: those
comments wrap, so the RSA leaf's date sits behind a `//` on the next line and
the first regex skipped it — both pins share an expiry, so the output looked
right while only one was read. Comment markers are now stripped before
whitespace is collapsed. Also audited GitHub secrets after the Codemagic
removal: all 12 are still referenced by workflows, nothing orphaned (the Play
credential lived in Codemagic's own env group, never on GitHub).

## [2026-07-25] release-ops | Codemagic removed; docs moved to script + artifact-only releases

Docs-only. `codemagic.yaml` was deleted (user decision), so all three workflows
it described (`android-release` → Play alpha, `android-verify-only`,
`ios-release` → TestFlight) are gone and **no hosted release pipeline remains** —
nothing publishes to a store automatically. Rewrote the release surface across
13 files: iOS is now `scripts/build_release.sh ios` + manual Organizer/`altool`
distribution; Android is `release-ready.yml` (artifact-only) with
`scripts/build_release.sh android` as the local equivalent. Documented the new
script's contract (fail-fast on `SENTRY_DSN` in `.env` / exported
`SENTRY_AUTH_TOKEN`, obfuscation + `sentry_dart_plugin` symbol upload with a
per-platform `SENTRY_RELEASE` matching `PackageInfo`) and the hazard it exists
for: `ios/Flutter/DartDefines.xcconfig` is gitignored and only a `flutter build`
rewrites it, so a raw Xcode Archive can ship a stale config — a found copy had
the legacy Google web client ID and **no** `SENTRY_DSN`. Called out that Play
version codes are package-global and are no longer resolved automatically
(now a manual pre-release check). Preserved the Flutter `3.41.4` pin rationale
(2026-07-18 `stable` drift to 3.44.6 broke locked `lucide_icons`) where it still
applies, on `release-ready.yml` + Xcode Cloud. Security controls 37→39.
known-gaps: artifact-only publishing recorded as a deliberate absence. Rotated
ten 07-17/07-18 entries into [[log-archive-2026-07-m]].
