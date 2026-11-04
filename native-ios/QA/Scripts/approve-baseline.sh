#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 reviewed-candidate.png screen--device--theme" >&2
  exit 2
fi
CANDIDATE="$1"
KEY="$2"
if [ ! -f "$CANDIDATE" ]; then echo "Candidate image not found: $CANDIDATE" >&2; exit 2; fi
if [[ ! "$KEY" =~ ^[A-Za-z0-9._-]+$ ]]; then echo "Baseline key may contain only letters, numbers, dot, underscore, and hyphen." >&2; exit 2; fi
BASELINES="$ROOT/native-ios/QA/Baselines"
DEST="$BASELINES/$KEY.png"
if [ -e "$DEST" ] || [ -e "$BASELINES/$KEY.json" ]; then
  echo "Refusing to overwrite an existing approved baseline. Preserve it and use a separately reviewed change." >&2
  exit 3
fi
printf "You are approving this screenshot as a protected visual baseline:\n  %s\nType APPROVE to confirm: " "$CANDIDATE"
read -r CONFIRMATION
if [ "$CONFIRMATION" != "APPROVE" ]; then echo "No baseline saved."; exit 1; fi
printf "Approved by (name or initials): "
read -r APPROVER
if [ -z "$APPROVER" ]; then echo "An approver name is required." >&2; exit 2; fi
mkdir -p "$BASELINES"
cp "$CANDIDATE" "$DEST"
SHA="$(shasum -a 256 "$DEST" | awk '{print $1}')"
COMMIT="$(git -C "$ROOT" rev-parse HEAD)"
DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
python3 - "$BASELINES/$KEY.json" "$KEY" "$APPROVER" "$DATE" "$COMMIT" "$SHA" <<'PY'
import json, pathlib, sys
path, key, approver, date, commit, sha = sys.argv[1:]
pathlib.Path(path).write_text(json.dumps({
    "screen": key,
    "status": "Approved",
    "approved_by": approver,
    "approved_at_utc": date,
    "commit": commit,
    "sha256": sha,
}, indent=2) + "\n")
PY
echo "Protected baseline saved: $DEST"
