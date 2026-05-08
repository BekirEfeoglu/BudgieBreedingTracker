#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

git diff --check
python3 scripts/verify_rules.py --strict
python3 scripts/verify_code_quality.py

changed_files="$(git diff --name-only --cached; git diff --name-only)"
if printf '%s\n' "$changed_files" | grep -Eq '^(assets/translations/|lib/|test/|scripts/check_l10n_sync.py)'; then
  python3 scripts/check_l10n_sync.py --strict-keys
fi

if printf '%s\n' "$changed_files" | grep -Eq '^(\.github/workflows/|\.claude/rules/|CLAUDE\.md|AGENTS\.md|scripts/)'; then
  python3 -m unittest discover -s scripts -p "test_*.py" --failfast
fi
