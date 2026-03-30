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
  SUPABASE_ANON_KEY
  SENTRY_DSN
  SENTRY_ENVIRONMENT
  REVENUECAT_API_KEY_IOS
  REVENUECAT_API_KEY_ANDROID
)

echo "// Auto-generated from .env — do NOT commit this file" > "$OUTPUT_FILE"

for KEY in "${KEYS[@]}"; do
  VALUE=$(grep "^${KEY}=" "$ENV_FILE" 2>/dev/null | head -1 | cut -d'=' -f2- | sed 's/^["'"'"']//;s/["'"'"']$//' || true)
  if [ -n "$VALUE" ]; then
    echo "${KEY}=${VALUE}" >> "$OUTPUT_FILE"
  fi
done

echo "✓ Generated $OUTPUT_FILE"
