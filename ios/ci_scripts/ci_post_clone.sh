#!/bin/sh

# Xcode Cloud clones a clean repository before archiving. Flutter iOS archives
# need build_runner outputs, Generated.xcconfig, and CocoaPods file lists
# generated in that clean clone.
set -eu

echo "Preparing Flutter iOS dependencies for Xcode Cloud..."

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
    git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_HOME"
  fi
  export PATH="$FLUTTER_HOME/bin:$PATH"
fi

flutter --version
flutter precache --ios
flutter pub get
dart run build_runner build --delete-conflicting-outputs

if ! command -v pod >/dev/null 2>&1; then
  export HOMEBREW_NO_AUTO_UPDATE=1
  brew install cocoapods
fi

cd ios
pod install

echo "Xcode Cloud Flutter iOS dependencies are ready."
