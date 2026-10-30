#!/bin/sh
set -eu

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "XcodeGen is required to create Logbook.xcodeproj. Install it with: brew install xcodegen" >&2
  exit 1
fi

cd "$(dirname "$0")"
xcodegen generate --spec project.yml
echo "Open native-ios/Logbook.xcodeproj in Xcode, select the Logbook scheme, then set a unique Team, bundle IDs, and App Group before signing."
