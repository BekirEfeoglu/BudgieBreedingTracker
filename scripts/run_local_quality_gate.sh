#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ "${LOCAL_QUALITY_GATE_SCOPE_ONLY:-0}" == "1" ]]; then
  # Contract tests exercise the real path router without paying the cost of
  # every quality check. This override is deliberately unavailable during a
  # normal gate run, where Git remains the only changed-file authority.
  changed_files="${LOCAL_QUALITY_GATE_CHANGED_FILES:-}"
else
  changed_files="$(
    git diff --name-only --cached
    git diff --name-only
    git ls-files --others --exclude-standard
  )"
fi

l10n_paths='^(assets/translations/|lib/|test/|scripts/check_l10n_sync.py)'
script_test_paths='^(\.github/workflows/|\.claude/rules/|CLAUDE\.md|AGENTS\.md|scripts/)'
breeding_egg_paths='^(\.claude/rules/breeding-eggs\.md|scripts/run_breeding_egg_regression\.sh|lib/features/(breeding|eggs|chicks)/|lib/domain/services/(breeding|eggs|incubation)/|lib/domain/services/notifications/(notification_(scheduler(_cancel|_reminders)?|ids|rescheduler|settings_providers|toggle_settings))\.dart|lib/domain/services/calendar/calendar_event_(generator|providers)\.dart|lib/core/enums/egg_enums\.dart|lib/data/.*(breeding_pair|incubation|clutch|egg|chick).*\.dart|test/features/(breeding|eggs|chicks)/|test/domain/services/(breeding|eggs|incubation)/|test/domain/services/notifications/(notification_(scheduler(_cancel|_reminders)?|ids|rescheduler|toggle_settings))_test\.dart|test/domain/services/calendar/calendar_event_(generator|providers)_test\.dart|test/data/.*(breeding_pair|incubation|clutch|egg|chick).*_test\.dart)'

matches_changed_path() {
  printf '%s\n' "$changed_files" | grep -Eq "$1"
}

run_l10n=0
run_script_tests=0
run_breeding_regression=0
if matches_changed_path "$l10n_paths"; then run_l10n=1; fi
if matches_changed_path "$script_test_paths"; then run_script_tests=1; fi
if matches_changed_path "$breeding_egg_paths"; then
  run_breeding_regression=1
fi

if [[ "${LOCAL_QUALITY_GATE_SCOPE_ONLY:-0}" == "1" ]]; then
  printf 'l10n=%s\n' "$run_l10n"
  printf 'script-tests=%s\n' "$run_script_tests"
  printf 'breeding-regression=%s\n' "$run_breeding_regression"
  exit 0
fi

git diff --check
python3 scripts/check_platform_targets.py
python3 scripts/generate_release_notes_site.py --check
python3 scripts/check_obsidian_brain.py
python3 scripts/verify_rules.py --strict
python3 scripts/verify_code_quality.py
python3 scripts/verify_migration_drift.py
python3 scripts/check_rule_symbol_drift.py --target all --classes --strict

if [[ "$run_l10n" == "1" ]]; then
  python3 scripts/check_l10n_sync.py --strict-keys
fi

if [[ "$run_script_tests" == "1" ]]; then
  python3 -m unittest discover -s scripts -p "test_*.py" --failfast
fi

if [[ "$run_breeding_regression" == "1" ]]; then
  scripts/run_breeding_egg_regression.sh
fi
