#!/bin/bash
# Reads ../.env and generates ios/Flutter/Env.xcconfig with build settings.
# Run from project root: bash scripts/generate_ios_env.sh

set -euo pipefail

ENV_FILE=".env"
OUTPUT_FILE="ios/Flutter/Env.xcconfig"

if [ ! -f "$ENV_FILE" ]; then
  echo "// No .env file found — values will fall back to --dart-define" > "$OUTPUT_FILE"
  exit 0
fi

# Keys to extract from .env
KEYS=(
  GOOGLE_WEB_CLIENT_ID
  GOOGLE_IOS_CLIENT_ID
  SUPABASE_URL
  SUPABASE_PUBLISHABLE_KEY
  SUPABASE_ANON_KEY
  SENTRY_DSN
  SENTRY_ENVIRONMENT
  REVENUECAT_API_KEY_IOS
  REVENUECAT_API_KEY_ANDROID
)

echo "// Auto-generated from .env — do NOT commit this file" > "$OUTPUT_FILE"

# xcconfig treats // as the start of a comment, even inside an unquoted URL.
# Route the second slash through an explicitly empty build setting so values
# such as https://project.supabase.co survive Info.plist expansion intact.
echo "BBT_EMPTY=" >> "$OUTPUT_FILE"

escape_xcconfig_value() {
  local value="$1"
  local double_slash_marker='/$(BBT_EMPTY)/'
  printf '%s' "${value//\/\//$double_slash_marker}"
}

read_env_value() {
  local key="$1"
  grep "^${key}=" "$ENV_FILE" 2>/dev/null \
    | head -1 \
    | cut -d'=' -f2- \
    | sed 's/^["'"'"']//;s/["'"'"']$//' \
    || true
}

PUBLISHABLE_KEY=$(read_env_value SUPABASE_PUBLISHABLE_KEY)
LEGACY_ANON_KEY=$(read_env_value SUPABASE_ANON_KEY)

# Keep legacy local environments working while emitting the canonical native
# key expected by new builds. Both values are client-safe Supabase keys.
if [ -z "$PUBLISHABLE_KEY" ] && [ -n "$LEGACY_ANON_KEY" ]; then
  PUBLISHABLE_KEY="$LEGACY_ANON_KEY"
fi

for KEY in "${KEYS[@]}"; do
  if [ "$KEY" = "SUPABASE_PUBLISHABLE_KEY" ]; then
    VALUE="$PUBLISHABLE_KEY"
  else
    VALUE=$(read_env_value "$KEY")
  fi
  if [ -n "$VALUE" ]; then
    printf '%s=%s\n' "$KEY" "$(escape_xcconfig_value "$VALUE")" \
      >> "$OUTPUT_FILE"
  fi
done

echo "✓ Generated $OUTPUT_FILE"
