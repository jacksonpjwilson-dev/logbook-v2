# Logbook QA and visual acceptance

This is the lightweight QA entry point. `ISSUES.md` is the shared issue register; `REPORT.md` is the latest test summary; `Baselines/` stores screenshots only after an explicit approval. Generated simulator results and screenshots are kept under the ignored `artifacts/` directory. The current review gate captures the **Default theme only**; it does not migrate or retheme the existing theme set.

## Run the Daily Home workflow

On a Mac with Xcode, iOS Simulator, and XcodeGen installed:

```sh
./native-ios/QA/Scripts/run-daily-home-qa.sh "iPhone 18 Pro"
```

Pass another installed simulator name to check a smaller size, such as `"iPhone 16e"`. The workflow regenerates the project from `project.yml`, sets a stable simulator status bar, launches with a synthetic QA-only data store, runs unit and UI tests, exports screenshot attachments, and updates `REPORT.md`. It never opens or writes the app’s normal App Group store. `--ui-testing` bypasses the three-second splash only in UI tests. The UI test captures all four Home pages in Default, records Daily widget frames in points, and asserts square small/large cells plus the 2×1 medium proportions.

Screenshots are captured for all four Home pages in Default. They are candidates until reviewed. No baseline is added or replaced automatically, and the v2 theme catalogue is not implemented beyond Default until visual approval.

## Compare and accept a screenshot

After reviewing the Xcode test result and the generated candidate PNG, compare it with an approved baseline for the same device, theme, and screen:

```sh
./native-ios/QA/Scripts/compare-screenshots.sh candidate.png native-ios/QA/Baselines/daily-home--iphone-18-pro--default.png diff.png
```

The comparison reports the changed-pixel percentage and writes a red difference image. Same device size and simulator settings are required. A missing baseline is **Not Reviewed**, not a pass.

To approve a first baseline, use the explicit acceptance script:

```sh
./native-ios/QA/Scripts/approve-baseline.sh candidate.png daily-home--iphone-18-pro--default
```

The script asks for a typed `APPROVE`, refuses to overwrite an existing baseline, and records a SHA-256, date, and Git commit in a sidecar file. To replace a baseline later, review the diff, preserve the old image in Git history, and make an explicit reviewed change; do not copy over it automatically.

## Review in Xcode

Open the generated `native-ios/Logbook.xcodeproj`, choose the `Logbook` scheme and an iPhone simulator, then Product → Test. Open `native-ios/QA/artifacts/<run>/Logbook.xcresult` in Xcode to inspect tests and screenshot attachments. The run script also exports PNGs beside the result bundle. On GitHub, download the `daily-home-qa-results` workflow artifact and open its `.xcresult` in Xcode.

## Acceptance boundary

Automated checks verify view presence, widget order/size/bounds, routing, rendering, and test outcomes. They do not approve aesthetics. Only your explicit acceptance changes a screen to **Approved** and allows the screenshot to become a protected baseline. Existing approved theme assets are preserved. The v2 Default candidate needs your review before any other v2 theme is implemented.

## Extending coverage

After Daily Home is running and reviewed, add one screen group at a time: Training, Food, Check-ins, History, Settings, then native extensions. Each group should add stable synthetic state, accessibility identifiers, deterministic UI tests, screenshots, core store tests, and acceptance notes before its baseline is approved.
