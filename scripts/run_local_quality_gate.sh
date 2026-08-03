#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

git diff --check
python3 scripts/check_platform_targets.py
python3 scripts/generate_release_notes_site.py --check
python3 scripts/check_obsidian_brain.py
python3 scripts/verify_rules.py --strict
python3 scripts/verify_code_quality.py
python3 scripts/verify_migration_drift.py
python3 scripts/check_rule_symbol_drift.py --target all --classes --strict

changed_files="$(
  git diff --name-only --cached
  git diff --name-only
  git ls-files --others --exclude-standard
)"
if printf '%s\n' "$changed_files" | grep -Eq '^(assets/translations/|lib/|test/|scripts/check_l10n_sync.py)'; then
  python3 scripts/check_l10n_sync.py --strict-keys
fi

if printf '%s\n' "$changed_files" | grep -Eq '^(\.github/workflows/|\.claude/rules/|CLAUDE\.md|AGENTS\.md|scripts/)'; then
  python3 -m unittest discover -s scripts -p "test_*.py" --failfast
fi

breeding_egg_paths='^(\.claude/rules/breeding-eggs\.md|scripts/run_breeding_egg_regression\.sh|lib/features/(breeding|eggs|chicks)/|lib/domain/services/(breeding|eggs|incubation)/|lib/domain/services/notifications/(notification_scheduler(_cancel|_reminders)?|notification_ids)\.dart|lib/domain/services/calendar/calendar_event_(generator|providers)\.dart|lib/core/enums/egg_enums\.dart|lib/data/.*(breeding_pair|incubation|clutch|egg|chick).*\.dart|test/features/(breeding|eggs|chicks)/|test/domain/services/(breeding|eggs|incubation)/|test/domain/services/notifications/(notification_scheduler(_cancel|_reminders)?|notification_ids)_test\.dart|test/domain/services/calendar/calendar_event_(generator|providers)_test\.dart|test/data/.*(breeding_pair|incubation|clutch|egg|chick).*_test\.dart)'
if printf '%s\n' "$changed_files" | grep -Eq "$breeding_egg_paths"; then
  scripts/run_breeding_egg_regression.sh
fi
