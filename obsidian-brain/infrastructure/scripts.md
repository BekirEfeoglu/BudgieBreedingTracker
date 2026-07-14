# Quality Scripts

Source: `CLAUDE.md` § Quality Scripts

All scripts in `scripts/` directory.

## Quality Gate Scripts

| Script | Purpose |
|--------|---------|
| `check_l10n_sync.py` | Verify tr/en/de translation keys are in sync |
| `check_platform_targets.py` | Verify unsupported Flutter web target is absent |
| `check_obsidian_brain.py` | Verify wiki index, wikilinks, inline file refs, overview metrics, decision sections, log pressure, and 200-line limit |
| `verify_code_quality.py` | Anti-pattern scan (28 checker categories: 19/24 CLAUDE.md anti-patterns + 10 documented extras; some overlap) |
| `verify_rules.py` | Validate CLAUDE.md stats against codebase |
| `verify_rules.py --fix` | Auto-fix CLAUDE.md stats + inline rule references |
| `check_remote_status.py` | Verify exact commit SHA GitHub status/check-run summary |
| `verify_migration_drift.py` | Migration structure guard: duplicate version prefixes + malformed filenames (offline, in the `code-quality` CI job); `--online` adds prod-ledger version parity via `supabase migration list --linked` |
| `check_rule_symbol_drift.py --target all --classes --strict` | Aspirational-contract guard (blocking in `code-quality`): every `xProvider` token, `.dart` path, and `*Service`/`*Notifier`/`*Repository` class named in `.claude/rules/` AND `obsidian-brain/` (excl. log/archives) must resolve in code. Low-noise by design (only those three high-confidence shapes); other class/method names stay in the manual semantic sweep. Legitimately-removed symbols documented in prose go in the script's allowlists |

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
| `test_verify_migration_drift.py` | Tests for verify_migration_drift.py (27 tests, 100% cov) |
| `test_check_rule_symbol_drift.py` | Tests for check_rule_symbol_drift.py (23 tests, 100% cov) |

## Internal Modules

| Module | Purpose |
|--------|---------|
| `_rules_collectors.py` | Data collectors for verify_rules.py |
| `_rules_fixers.py` | Auto-fix logic for verify_rules.py --fix |
| `_rules_utils.py` | Shared utilities |

## Operational Scripts

| Script | Purpose |
|--------|---------|
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
