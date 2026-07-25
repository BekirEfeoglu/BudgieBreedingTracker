# Quality Scripts

Source: `CLAUDE.md` § Quality Scripts

All scripts in `scripts/` directory.

## Quality Gate Scripts

| Script | Purpose |
|--------|---------|
| `check_l10n_sync.py` | Verify tr/en/de translation keys are in sync |
| `check_platform_targets.py` | Verify unsupported Flutter web target is absent |
| `check_obsidian_brain.py` | Verify wiki index, wikilinks, inline file refs, overview metrics, decision sections, log pressure, and 200-line limit |
| `check_obsidian_brain.py --rotate` | Move the oldest `log.md` entries into the newest archive (chosen by content, not filename), widen its `(MM-DD to MM-DD)` range and the index row, then lint |
| `verify_code_quality.py` | Anti-pattern scan (28 checker categories: 19/24 CLAUDE.md anti-patterns + 10 documented extras; some overlap) |
| `verify_rules.py` | CLAUDE.md stats vs codebase + 7 cross-surface guards (release artifacts, Edge fn names, bucket ids, l10n categories, icons, route targets, table names) |
| `verify_rules.py --fix` | Auto-fix CLAUDE.md stats + inline rule references |
| `check_remote_status.py` | Verify exact commit SHA GitHub status/check-run summary; an Edge deploy skip is accepted only with a successful path detector |
| `verify_migration_drift.py` | Migration structure guard: duplicate/malformed filenames plus immutable applied-chain SHA-256 baseline (offline, in `code-quality`); `--online` parses only remote ledger versions and resolves the nine documented apply-time aliases from the fixture before checking parity |
| `check_rule_symbol_drift.py --target all --classes --strict` | Aspirational-contract guard (blocking in `code-quality`): every `xProvider` token, `.dart` path, and `*Service`/`*Notifier`/`*Repository`/`*Dao`/`*Mapper`/`*Guard` class named in `.claude/rules/` AND `obsidian-brain/` (excl. log/archives) must resolve in code. Class names checked in backticks AND bare in prose (outside fenced code). Low-noise by design; other class/method names stay in the manual semantic sweep. Removed symbols cited in prose go in the allowlists. `--audit-allowlist` (periodic, not gated) reports uncited allowlist cruft |

## Pre-Commit Gate

```bash
flutter analyze --no-fatal-infos && \
python3 scripts/verify_code_quality.py && \
python3 scripts/check_l10n_sync.py
```

Or the combined script:
```bash
scripts/run_local_quality_gate.sh
```

## Other Scripts (not in the quality-gate list above)

`scripts/verify_security.py` (backs the `security-audit` CI job), `scripts/test_app_store_config.py`, `scripts/install_git_hooks.sh`, `scripts/run_breeding_egg_regression.sh` also exist on disk.

`verify_security.py` covers **40 controls**. Two are time- or release-path
dependent and worth knowing about:

- `check_release_obfuscation` — since Codemagic was removed (2026-07-25) the
  obfuscation / DSN-fail-fast / symbol-upload contract is asserted against
  `scripts/build_release.sh` plus `release-ready.yml`, not a hosted config.
- `check_certificate_pin_freshness` — fails the job in the 14 days before the
  earliest pinned TLS leaf expires, so rotation cannot be forgotten. This one
  can go red without any code change, purely because time passed; see
  [[patterns/security]] § Certificate Pinning for the rotation steps.

## Test Scripts (CI: scripts-test job, ≥98% coverage)

| Script | Tests |
|--------|-------|
| `test_l10n_sync.py` | Tests for check_l10n_sync.py |
| `test_l10n_sync_main.py` | Main entry tests for l10n sync |
| `test_code_quality.py` | Tests for verify_code_quality.py |
| `test_code_quality_main.py` | Main entry tests for code quality |
| `test_verify_rules.py` | Tests for verify_rules.py |
| `test_check_platform_targets.py` | Tests for platform target policy |
| `test_check_obsidian_brain.py` | Tests for wiki lint |
| `test_verify_security.py` | Tests for verify_security.py |
| `test_verify_migration_drift.py` | Tests for verify_migration_drift.py (35 tests, including JSON/table remote parsing, baseline hashes, and alias conflicts) |
| `test_check_rule_symbol_drift.py` | Tests for check_rule_symbol_drift.py (31 tests, 100% cov) |
| `test_marketing_site.py` | All-public-HTML asset/ID checks plus JSON-LD, heading, accessibility, responsive navigation, user-guide dialog/focus, legal-page locale, and cross-page security-copy contracts |

## Internal Modules

| Module | Purpose |
|--------|---------|
| `_rules_collectors.py` | Data collectors for verify_rules.py |
| `_rules_fixers.py` | Auto-fix logic for verify_rules.py --fix |
| `_rules_utils.py` | Shared utilities |

## Operational Scripts

| Script | Purpose |
|--------|---------|
| `build_release.sh <ios\|android>` | Canonical release build — fails fast without `SENTRY_DSN`/`SENTRY_AUTH_TOKEN`, obfuscates, uploads Sentry symbols ([[infrastructure/release-ops]]) |
| `generate_ios_env.sh` | Generate iOS environment config from dart-defines |
| `setup_push_env.sh` | Setup FCM push notification environment |
| `monitor_pg_performance.sql` | PostgreSQL performance monitoring queries |
| `verify_rls_staging.sql` | Verify RLS policies on staging |
| `verify_push_setup.sql` | Verify FCM push notification DB setup |

## Anti-Pattern Checkers (`verify_code_quality.py`)

28 checker categories total:
- Covers 19/24 CLAUDE.md anti-patterns list
- 10 documented extras: `Spacing` (hardcoded → `AppSpacing`), `Freezed3`, `Layer`, `Loading` (ad-hoc `CircularProgressIndicator`), `TapTarget` (IconButton 48dp), `Container` (ProviderContainer teardown), `Upsert` (insert vs upsert), `SupaCol` (remote column literal → `SupabaseConstants`, #8), `Boundary` (feature → `client.from()`), `ImageCache` (`CachedNetworkImage` cache size)
- Scans `lib/` and `test/` directories

## See Also

- [[patterns/anti-patterns]] — what the checkers look for
- [[infrastructure/ci-cd]] — how scripts run in CI
