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

if ! command -v flutter >/dev/null 2>&1; then
  FLUTTER_HOME="$HOME/flutter"
  if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
    # Pin to 3.41.4 to keep parity with GitHub Actions and local dev.
    # Cloning plain 'stable' picks the newest Flutter, which ships Dart
    # 3.12 and makes IconData a final class -- that breaks lucide_icons
    # 0.257.0 (LucideIconData extends IconData).
    run_with_retries 3 10 git clone https://github.com/flutter/flutter.git --depth 1 -b 3.41.4 "$FLUTTER_HOME"
  fi
  export PATH="$FLUTTER_HOME/bin:$PATH"
fi

flutter --version
run_with_retries 3 10 flutter precache --ios
run_with_retries 3 10 flutter pub get
dart run build_runner build

if ! command -v pod >/dev/null 2>&1; then
  export HOMEBREW_NO_AUTO_UPDATE=1
  run_with_retries 3 10 brew install cocoapods
fi

cd ios
# CocoaPods downloads transitive source archives such as sqlite3 from external
# hosts. Xcode Cloud can fail a single attempt on transient DNS resolution.
run_with_retries 4 15 pod install

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
