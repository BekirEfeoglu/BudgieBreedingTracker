# Quality Scripts

Source: `CLAUDE.md` § Quality Scripts

All scripts in `scripts/` directory.

## Quality Gate Scripts

| Script | Purpose |
|--------|---------|
| `check_l10n_sync.py` | Verify tr/en/de translation keys are in sync |
| `check_platform_targets.py` | Verify unsupported Flutter web target is absent |
| `check_obsidian_brain.py` | Verify wiki index entries, wikilinks, log entry, and 200-line limit |
| `verify_code_quality.py` | Anti-pattern scan (27 checker categories: 19/24 CLAUDE.md anti-patterns + 9 documented extras; some overlap) |
| `verify_rules.py` | Validate CLAUDE.md stats against codebase |
| `verify_rules.py --fix` | Auto-fix CLAUDE.md stats + inline rule references |
| `check_remote_status.py` | Verify exact commit SHA GitHub status/check-run summary |

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

27 checker categories total:
- Covers 19/24 CLAUDE.md anti-patterns list
- 9 documented extras: `Spacing` (hardcoded → `AppSpacing`), `Freezed3`, `Layer`, `Loading` (ad-hoc `CircularProgressIndicator`), `TapTarget` (IconButton 48dp), `Container` (ProviderContainer teardown), `Upsert` (insert vs upsert), `Boundary` (feature → `client.from()`), `ImageCache` (`CachedNetworkImage` cache size)
- Scans `lib/` and `test/` directories

## See Also

- [[patterns/anti-patterns]] — what the checkers look for
- [[infrastructure/ci-cd]] — how scripts run in CI
