# iOS development and testing setup

## What this Codex workspace can run
The current Codex execution workspace is Linux. It has no Xcode, `xcodebuild`, `xcrun`, or iOS Simulator, so it cannot locally compile SwiftUI targets or capture simulator screenshots. GitHub Actions provides the project's macOS simulator CI. This environment finding applies to this workspace; check `uname -a`, `xcodebuild -version`, and `xcrun simctl list devices available` again in future environments.

## Mac setup (M2 MacBook Air)
1. Update/pull the intended development branch and confirm `git status` before opening Xcode. Keep unrelated local edits safe.
2. Install current Xcode from Apple, open it once, accept its license, and install the required iOS Simulator runtime. Install XcodeGen if the project script needs it (`brew install xcodegen`).
3. In Terminal at the repository root, check `xcodebuild -version`, `xcodegen --version`, and `xcrun simctl list devices available`.
4. Open `native-ios/Logbook.xcodeproj` in Xcode. Select the `Logbook` scheme. If the generated project is stale, regenerate only according to the repository's instructions (`native-ios/generate-project.sh`); do not edit generated project settings as a substitute for `native-ios/project.yml` without documenting why.

## Build and test
In Xcode choose an installed iPhone simulator in the run destination menu, then use Product → Build or Product → Test. For the scripted Daily QA workflow from the repository root:

```sh
./native-ios/QA/Scripts/run-daily-home-qa.sh "iPhone 16"
./native-ios/QA/Scripts/run-daily-home-qa.sh "iPhone SE (3rd generation)"
./native-ios/QA/Scripts/run-daily-home-qa.sh "iPhone 18 Pro"
```

Only run a simulator name shown as available. If Xcode cannot find the destination, open Xcode → Settings → Platforms and install its iOS runtime. Home geometry should be checked on one compact device and one large device; iPhone 18 Pro remains untested until a matching simulator or physical device actually runs the suite.

## Screenshot capture and review
The QA script creates real Simulator screenshots and an `.xcresult` under `native-ios/QA/artifacts/`. Open the `.xcresult` in Xcode to inspect test details and attachments. Candidate PNGs are not approved baselines. On GitHub, open the exact Actions run, select the device job, then download its named artifact under Artifacts. Inspect the per-device test summary and logs; a skipped job is not a pass. Keep comparisons on the same device, OS scale, fixture and appearance.

## Diagnosing failures
- Open the failing CI job and inspect the first compiler diagnostic in the `Run Daily Home QA` step; do not infer failure from the workflow title alone.
- Download the device artifact for `xcodebuild.log`, `summary.json`, screenshots and test report; open `.xcresult` locally when available.
- Distinguish build errors (no tests), assertion failures, simulator boot failures, and skipped devices. Check `xcrun simctl list devices available` for simulator inventory.
- For UI failures, inspect accessibility identifiers/hierarchy, test attachment screenshots/video and the rendered screen. Keep assertions meaningful; do not weaken them just to get a green run.

## Install on a physical iPhone
1. Connect and unlock the iPhone, trust the Mac if prompted, and select it as Xcode's run destination.
2. In the app target's Signing & Capabilities, enable automatic signing and select your Personal Team or developer team. Resolve any unique bundle ID and App Group provisioning requirements in the development branch only.
3. Build and run from Xcode. If iOS asks to trust the developer profile, follow the on-device Settings prompt. Keep the device build signed for development; TestFlight/App Store distribution requires separate signing and release authorization.
4. Verify offline launch, persistence, notification prompts, safe areas, and enabled native capabilities on device. No HealthKit permission is requested under the current user instruction.

## GitHub Actions
CI is an independent macOS check and remains useful when Codex runs on Linux. Read every matrix job and artifact separately. Record the exact commit SHA actually checked out by the runner. If simulator capacity or tool availability changes, mark the affected device not tested rather than assuming a pass.
