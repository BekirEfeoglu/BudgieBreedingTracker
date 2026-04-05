#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICE_ACCOUNT_PATH="${1:-}"
ANDROID_GOOGLE_SERVICES_PATH="${ROOT_DIR}/android/app/google-services.json"

if ! command -v supabase >/dev/null 2>&1; then
  echo "supabase CLI bulunamadi." >&2
  exit 1
fi

if [[ -z "${SERVICE_ACCOUNT_PATH}" ]]; then
  echo "Kullanim: scripts/setup_push_env.sh /tam/yol/service-account.json" >&2
  exit 1
fi

if [[ ! -f "${SERVICE_ACCOUNT_PATH}" ]]; then
  echo "Service account dosyasi bulunamadi: ${SERVICE_ACCOUNT_PATH}" >&2
  exit 1
fi

if [[ -f "${ROOT_DIR}/.env" ]]; then
  # shellcheck disable=SC1091
  source "${ROOT_DIR}/.env"
fi

if [[ -z "${FIREBASE_PROJECT_ID:-}" && -f "${ANDROID_GOOGLE_SERVICES_PATH}" ]]; then
  FIREBASE_PROJECT_ID="$(
    ruby -rjson -e 'json = JSON.parse(File.read(ARGV[0])); puts json.dig("project_info", "project_id")' \
      "${ANDROID_GOOGLE_SERVICES_PATH}"
  )"
fi

: "${SUPABASE_URL:?SUPABASE_URL gerekli}"
: "${SUPABASE_ANON_KEY:?SUPABASE_ANON_KEY gerekli}"
: "${FIREBASE_PROJECT_ID:?FIREBASE_PROJECT_ID gerekli}"
: "${SUPABASE_SERVICE_ROLE_KEY:?SUPABASE_SERVICE_ROLE_KEY gerekli}"

echo "Supabase push secret'lari ayarlaniyor..."
supabase secrets set \
  SUPABASE_URL="${SUPABASE_URL}" \
  SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}" \
  SUPABASE_SERVICE_ROLE_KEY="${SUPABASE_SERVICE_ROLE_KEY}" \
  FIREBASE_PROJECT_ID="${FIREBASE_PROJECT_ID}" \
  GOOGLE_SERVICE_ACCOUNT_JSON="$(cat "${SERVICE_ACCOUNT_PATH}")"

echo "send-push function deploy ediliyor..."
supabase functions deploy send-push

echo "Tamamlandi."
