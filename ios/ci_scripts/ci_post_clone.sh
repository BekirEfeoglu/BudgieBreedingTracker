#!/bin/sh

# Xcode Cloud clones a clean repository before archiving. Flutter iOS archives
# need build_runner outputs, Generated.xcconfig, and CocoaPods file lists
# generated in that clean clone.
set -eu

echo "Preparing Flutter iOS dependencies for Xcode Cloud..."

run_with_retries() {
  max_attempts="$1"
  delay_seconds="$2"
  shift 2
  attempt=1

  while [ "$attempt" -le "$max_attempts" ]; do
    echo "Running attempt $attempt/$max_attempts: $*"
    set +e
    "$@"
    status="$?"
    set -e

    if [ "$status" -eq 0 ]; then
      return 0
    fi

    if [ "$attempt" -eq "$max_attempts" ]; then
      echo "Command failed after $attempt attempts with exit code $status: $*" >&2
      return "$status"
    fi

    echo "Command failed with exit code $status. Retrying in ${delay_seconds}s: $*" >&2
    sleep "$delay_seconds"
    attempt=$((attempt + 1))
    delay_seconds=$((delay_seconds * 2))
  done
}

require_generated_file() {
  if [ ! -f "$1" ]; then
    echo "Required generated file is missing after dependency setup: $1" >&2
    exit 1
  fi
}

if [ -n "${CI_PRIMARY_REPOSITORY_PATH:-}" ]; then
  REPO_ROOT="$CI_PRIMARY_REPOSITORY_PATH"
else
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi

cd "$REPO_ROOT"

# Self-diagnosing step markers: on any failure, the LAST ">>> STEP" line printed
# tells exactly which step was running (the generic Xcode Cloud message "Running
# ci_post_clone.sh script failed (exited with code 1)" does not). Share the tail
# of the Xcode Cloud log to pinpoint the failing step.

echo ">>> STEP 1: flutter toolchain"
if ! command -v flutter >/dev/null 2>&1; then
  FLUTTER_HOME="$HOME/flutter"
  if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
    # Pin to 3.41.4 to keep parity with GitHub Actions and local dev.
    # Cloning plain 'stable' picks the newest Flutter, which ships Dart
    # 3.12 and makes IconData a final class -- that breaks lucide_icons
    # 0.257.0 (LucideIconData extends IconData).
    echo ">>> STEP 1a: git clone flutter 3.41.4"
    run_with_retries 3 10 git clone https://github.com/flutter/flutter.git --depth 1 -b 3.41.4 "$FLUTTER_HOME"
  fi
  export PATH="$FLUTTER_HOME/bin:$PATH"
fi

echo ">>> STEP 2: flutter --version"
flutter --version
echo ">>> STEP 3: flutter precache --ios"
run_with_retries 3 10 flutter precache --ios
echo ">>> STEP 4: flutter pub get"
run_with_retries 3 10 flutter pub get

# drift_dev 2.31 intermittently throws "Circular error when deserializing drift
# modules" (build-order dependent). Retry with a clean cache so a flaky codegen
# pass does not fail the whole archive. Unlike run_with_retries this cleans the
# build cache between attempts, which is what clears the circular-error state.
echo ">>> STEP 5: dart run build_runner build"
build_attempt=1
until dart run build_runner build --delete-conflicting-outputs; do
  if [ "$build_attempt" -ge 8 ]; then
    echo "build_runner failed after $build_attempt attempts" >&2
    exit 1
  fi
  echo "build_runner attempt $build_attempt failed; cleaning and retrying" >&2
  dart run build_runner clean || true
  build_attempt=$((build_attempt + 1))
done

echo ">>> STEP 6: cocoapods toolchain"
if ! command -v pod >/dev/null 2>&1; then
  export HOMEBREW_NO_AUTO_UPDATE=1
  echo ">>> STEP 6a: brew install cocoapods"
  run_with_retries 3 10 brew install cocoapods
fi

echo ">>> STEP 7: pod install"
cd ios
# CocoaPods downloads transitive source archives such as sqlite3 from external
# hosts. Xcode Cloud can fail a single attempt on transient DNS resolution.
run_with_retries 4 15 pod install

echo ">>> STEP 8: verify generated files"
require_generated_file "Flutter/Generated.xcconfig"
for configuration in Debug Release Profile; do
  lowercase_configuration="$(printf '%s' "$configuration" | tr '[:upper:]' '[:lower:]')"
  require_generated_file "Pods/Target Support Files/Pods-Runner/Pods-Runner.${lowercase_configuration}.xcconfig"
  require_generated_file "Pods/Target Support Files/Pods-Runner/Pods-Runner-resources-${configuration}-input-files.xcfilelist"
  require_generated_file "Pods/Target Support Files/Pods-Runner/Pods-Runner-resources-${configuration}-output-files.xcfilelist"
  require_generated_file "Pods/Target Support Files/Pods-Runner/Pods-Runner-frameworks-${configuration}-input-files.xcfilelist"
  require_generated_file "Pods/Target Support Files/Pods-Runner/Pods-Runner-frameworks-${configuration}-output-files.xcfilelist"
done

echo "Xcode Cloud Flutter iOS dependencies are ready."
