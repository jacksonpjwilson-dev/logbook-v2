#!/bin/bash
set -u

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
DEVICE_NAME="${1:-iPhone 18 Pro}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
RUN_DIR="$ROOT/native-ios/QA/artifacts/daily-home-$STAMP"
RESULT="$RUN_DIR/Logbook.xcresult"
LOG="$RUN_DIR/xcodebuild.log"
SUMMARY="$RUN_DIR/summary.json"
REPORT="$ROOT/native-ios/QA/REPORT.md"
mkdir -p "$RUN_DIR/screenshots"

if ! command -v xcodebuild >/dev/null 2>&1 || ! command -v xcrun >/dev/null 2>&1; then
  echo "This QA run needs macOS with Xcode and iOS Simulator installed." >&2
  exit 2
fi
if ! command -v xcodegen >/dev/null 2>&1; then
  echo "XcodeGen is required to add the UI test target. Install it with 'brew install xcodegen'." >&2
  exit 2
fi

cd "$ROOT"
./native-ios/generate-project.sh

SIMULATOR_ID="$(xcrun simctl list devices available -j | python3 -c 'import json,sys; name=sys.argv[1]; d=json.load(sys.stdin); matches=[x["udid"] for group in d["devices"].values() for x in group if x.get("name")==name and x.get("isAvailable")]; print(matches[0] if matches else "")' "$DEVICE_NAME")"
if [ -z "$SIMULATOR_ID" ]; then
  echo "No available simulator named '$DEVICE_NAME'. Choose one from Xcode's Devices and Simulators window." >&2
  exit 2
fi
xcrun simctl boot "$SIMULATOR_ID" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$SIMULATOR_ID" -b
xcrun simctl status_bar "$SIMULATOR_ID" override --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100

set +e
xcodebuild \
  -project "$ROOT/native-ios/Logbook.xcodeproj" \
  -scheme Logbook \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -parallel-testing-enabled NO \
  -resultBundlePath "$RESULT" \
  CODE_SIGNING_ALLOWED=NO test 2>&1 | tee "$LOG"
TEST_EXIT=${PIPESTATUS[0]}
set -e

xcrun xcresulttool export attachments --path "$RESULT" --output-path "$RUN_DIR/screenshots" >/dev/null 2>&1 || true
xcrun xcresulttool get test-results summary --path "$RESULT" --format json > "$SUMMARY" 2>/dev/null || echo '{}' > "$SUMMARY"
SCREENSHOT_COUNT="$(find "$RUN_DIR/screenshots" -type f \( -iname '*.png' -o -iname '*.jpg' \) | wc -l | tr -d ' ')"
TEST_RESULT="FAILED"
if [ "$TEST_EXIT" -eq 0 ]; then TEST_RESULT="PASSED"; fi

python3 - "$REPORT" "$SUMMARY" "$RUN_DIR" "$DEVICE_NAME" "$TEST_RESULT" "$SCREENSHOT_COUNT" <<'PY'
import json, pathlib, subprocess, sys
report, summary_file, run_dir, device, result, screenshots = sys.argv[1:]
try:
    summary = json.loads(pathlib.Path(summary_file).read_text())
except Exception:
    summary = {}
def pick(*keys):
    return next((summary[k] for k in keys if isinstance(summary.get(k), (int, float))), "unknown")
try:
    commit = subprocess.check_output(["git", "rev-parse", "--short", "HEAD"], text=True).strip()
    branch = subprocess.check_output(["git", "branch", "--show-current"], text=True).strip()
except Exception:
    commit, branch = "unknown", "unknown"
issues = pathlib.Path("native-ios/QA/ISSUES.md").read_text().splitlines()
open_count = sum("| Open |" in line for line in issues)
progress_count = sum("| In Progress |" in line for line in issues)
text = f"""# Logbook QA report

- Run: `{pathlib.Path(run_dir).name}`
- Branch / commit: `{branch}` / `{commit}`
- Simulator: `{device}`
- Xcode result: **{result}**
- Tests passed / failed / skipped: {pick('passedTests', 'passedTestCount')} / {pick('failedTests', 'failedTestCount')} / {pick('skippedTests', 'skippedTestCount')}
- Screenshot attachments exported: {screenshots}
- Result bundle: `{pathlib.Path(run_dir).name}/Logbook.xcresult`

## Open work

- Open issues: {open_count}
- In progress: {progress_count}
- Daily Home: **Ready for Review** only if the UI test passed; appearance still requires your review.
- Other app screens: **Not Reviewed** in this QA workflow.
- Approved theme designs: preserved; screenshots are regression candidates and do not authorize a redesign.

## Review decision

No screenshot baseline is automatically replaced. Record a screen as Approved only after explicit human acceptance and use `Scripts/approve-baseline.sh` to add a protected baseline.
"""
pathlib.Path(report).write_text(text)
PY

echo "QA report: $REPORT"
echo "Screenshots: $RUN_DIR/screenshots"
echo "Xcode result bundle: $RESULT"
exit "$TEST_EXIT"
