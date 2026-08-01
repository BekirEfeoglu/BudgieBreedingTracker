#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

COMMON_ARGS=(
  --dart-define=SUPABASE_URL=https://placeholder.supabase.co
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_placeholder
)

flutter test test/features/breeding/providers/breeding_form_providers_test.dart "${COMMON_ARGS[@]}"
flutter test test/features/breeding/providers/breeding_form_actions_test.dart "${COMMON_ARGS[@]}"
flutter test test/features/eggs/providers/egg_actions_notifier_test.dart "${COMMON_ARGS[@]}"
