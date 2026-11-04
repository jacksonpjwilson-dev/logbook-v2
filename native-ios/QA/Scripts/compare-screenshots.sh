#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
if [ "$#" -lt 2 ]; then
  echo "Usage: $0 candidate.png approved.png [diff.png] [max-difference-percent]" >&2
  exit 2
fi
xcrun swift "$ROOT/native-ios/QA/Scripts/compare-screenshots.swift" "$@"
