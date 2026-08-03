#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

COMMON_ARGS=(
  --dart-define=SUPABASE_URL=https://placeholder.supabase.co
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_placeholder
)

REGRESSION_TESTS=(
  test/data/repositories/breeding_creation_persistence_test.dart
  test/features/breeding/providers/breeding_form_providers_test.dart
  test/features/breeding/providers/breeding_form_actions_test.dart
  test/features/eggs/providers/egg_actions_notifier_test.dart
  test/domain/services/notifications/notification_ids_test.dart
  test/domain/services/notifications/notification_scheduler_test.dart
  test/domain/services/notifications/notification_scheduler_cancel_test.dart
  test/domain/services/notifications/notification_scheduler_reminders_test.dart
  test/domain/services/notifications/notification_rescheduler_test.dart
  test/domain/services/notifications/notification_toggle_settings_test.dart
  test/domain/services/calendar/calendar_event_generator_test.dart
  test/domain/services/calendar/calendar_event_providers_test.dart
)

# A skip in this high-risk suite would silently weaken the local lifecycle
# gate. Fix it or document replacement coverage outside this manifest before
# changing the suite; do not let Flutter report a green skipped regression.
if rg -n 'skip[[:space:]]*:|@Skip|@Tags\(\[[^]]*(e2e|community)' \
  "${REGRESSION_TESTS[@]}"; then
  echo "Breeding/egg regression refused: skipped or excluded test detected." >&2
  exit 1
fi

for test_file in "${REGRESSION_TESTS[@]}"; do
  flutter test --no-pub "$test_file" "${COMMON_ARGS[@]}"
done
