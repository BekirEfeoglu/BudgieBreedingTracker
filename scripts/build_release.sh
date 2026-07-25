#!/usr/bin/env bash
#
# Canonical local release build. Replaces the Codemagic release workflows
# (removed 2026-07-25) for iOS, and mirrors what `release-ready.yml` does for
# Android so both platforms are produced the same way.
#
#   scripts/build_release.sh ios
#   scripts/build_release.sh android
#
# Why this exists rather than "just Archive from Xcode":
#
#   * Release builds are compiled with --obfuscate --split-debug-info. Without
#     the matching `sentry_dart_plugin` upload, every production crash report
#     is an unreadable stack of obfuscated symbols — and you only discover that
#     when you actually need the report.
#   * SENTRY_DSN is a --dart-define. Xcode's Archive reads whatever stale
#     values sit in the gitignored ios/Flutter/DartDefines.xcconfig, which is
#     only rewritten by a `flutter build`. A raw Archive can therefore ship a
#     release with no crash reporting at all, silently. Running this script
#     first regenerates that file from .env.
#   * SENTRY_RELEASE must match the runtime PackageInfo naming (real bundle /
#     package id + real build number) or the uploaded symbols never match an
#     incoming event.
#
# After this script finishes for iOS, distribute build/ios/ipa/*.ipa via Xcode
# Organizer or `xcrun altool`. For Android, prefer the Release Ready workflow
# (it builds in a clean checkout); use this script only for local verification.
#
# Related: .claude/rules/release-ops.md

set -euo pipefail

PLATFORM="${1:-}"
if [[ "$PLATFORM" != "ios" && "$PLATFORM" != "android" ]]; then
  echo "usage: scripts/build_release.sh <ios|android>" >&2
  exit 2
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ENV_FILE="${ENV_FILE:-.env}"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: $ENV_FILE not found. Release builds must not fall back to defaults." >&2
  exit 1
fi

# --- Fail fast on the values whose absence is silent -------------------------
# A missing DSN does not break the build; it produces a release with no crash
# reporting. A missing auth token does not break the build either; it produces
# unreadable obfuscated stack traces. Both must be loud here.
missing=()
grep -qE '^SENTRY_DSN=.+' "$ENV_FILE" || missing+=("SENTRY_DSN (in $ENV_FILE)")
[[ -n "${SENTRY_AUTH_TOKEN:-}" ]] || missing+=("SENTRY_AUTH_TOKEN (environment)")
if (( ${#missing[@]} > 0 )); then
  echo "ERROR: release build refused, missing:" >&2
  printf '  - %s\n' "${missing[@]}" >&2
  echo >&2
  echo "SENTRY_AUTH_TOKEN is an org:ci token; export it for this shell only." >&2
  exit 1
fi

APP_VERSION="$(sed -n 's/^version: \([^+]*\).*/\1/p' pubspec.yaml | head -1)"
BUILD_NUMBER="$(sed -n 's/^version: [^+]*+\(.*\)/\1/p' pubspec.yaml | head -1)"
if [[ -z "$APP_VERSION" || -z "$BUILD_NUMBER" ]]; then
  echo "ERROR: could not parse 'version: X.Y.Z+build' from pubspec.yaml" >&2
  exit 1
fi
echo ">>> Version $APP_VERSION build $BUILD_NUMBER"

echo ">>> Installing dependencies"
flutter pub get

echo ">>> Generating code"
dart run build_runner build --delete-conflicting-outputs

if [[ "$PLATFORM" == "ios" ]]; then
  # Keeps Env.xcconfig aligned with .env; the flutter build below is what
  # rewrites DartDefines.xcconfig, which is the file Xcode actually reads.
  echo ">>> Regenerating iOS env config"
  bash scripts/generate_ios_env.sh

  echo ">>> Building iOS IPA"
  flutter build ipa --release \
    --dart-define-from-file="$ENV_FILE" \
    --obfuscate \
    --split-debug-info=build/symbols/ios \
    --extra-gen-snapshot-options=--save-obfuscation-map=build/app/obfuscation.map.json

  echo ">>> Uploading iOS debug symbols to Sentry"
  SENTRY_RELEASE="com.budgiebreeding.tracker@${APP_VERSION}+${BUILD_NUMBER}"
  SENTRY_DIST="$BUILD_NUMBER"
  export SENTRY_RELEASE SENTRY_DIST
  dart run sentry_dart_plugin

  echo
  echo ">>> Done. IPA: build/ios/ipa/*.ipa"
  echo "    Distribute via Xcode Organizer or xcrun altool."
else
  echo ">>> Building Android App Bundle"
  flutter build appbundle --release \
    --dart-define-from-file="$ENV_FILE" \
    --obfuscate \
    --split-debug-info=build/symbols/android \
    --extra-gen-snapshot-options=--save-obfuscation-map=build/app/obfuscation.map.json

  echo ">>> Uploading Android debug symbols to Sentry"
  SENTRY_RELEASE="com.budgiebreeding.budgie_breeding_tracker@${APP_VERSION}+${BUILD_NUMBER}"
  SENTRY_DIST="$BUILD_NUMBER"
  export SENTRY_RELEASE SENTRY_DIST
  dart run sentry_dart_plugin

  echo
  echo ">>> Done. AAB: build/app/outputs/bundle/release/app-release.aab"
  echo "    Google Play version codes are package-global: the build number in"
  echo "    pubspec.yaml must exceed the highest code across ALL tracks and the"
  echo "    artifact library, not just the track you publish to."
fi
