# Logbook v2 handoff audit and Default gate

**Audit date:** 2026-11-06  
**Source package:** `LOGBOOK_CODEX_COMPLETE_VISUAL_HANDOFF_v2.zip`  
**Authority:** `LOGBOOK_MASTER_SPEC.md` v1.2 and theme addendum §16.  
**Repository branch in this worktree:** `codex/default-theme-gate1`, created from the isolated QA branch at `8741ee53b9495d5558d6a35b152772fca3fbd646`. No changes were made to `main`. Build and simulator evidence must be updated from the macOS workflow before acceptance.

## Environment and evidence limits

This workspace is Linux. `xcodebuild`, `xcrun`, XcodeGen, and iOS Simulator are unavailable here. The Xcode project and test scheme exist, but no build, XCTest, screenshot, or runtime claim can be made from this environment. `native-ios/QA/artifacts/` contains no run output and `native-ios/QA/Baselines/` contains only its README. Therefore the implementation statuses below are source-audit results, not runtime passes. The test additions are ready for the macOS script; they have not executed.

No native screenshots are available in this checkout. The package has `themes/references/defaults/default_CONCEPT.png` and `default_COMPOSITE_CROP.png`, both style references, plus `themes/backgrounds/default_PROVISIONAL_BLUR.jpg`, which is a provisional starter background and is now bundled for the Default candidate. None is an approved pixel-perfect export. Reference gaps and screenshot tasks are listed in `VISUAL_DIFFS/README.md`.

## Requirement-to-implementation findings

| Area | Status | Source evidence | Finding |
|---|---|---|---|
| Four Home pages and horizontal paging | PARTIAL | `HomeScreen` uses a page-style `TabView`; `HomeState.defaultPages` defines Daily, Training, Food, Progress & History. UI test captures those pages. | Correct structure is present in source; simulator swipe behavior and rendered captures remain unverified. |
| Fixed athlete dock | PARTIAL | `LogbookDock` contains Training, Food, History, Sleep, Settings; bottom safe-area inset. | Five expected actions are present. Touch targets, insets, crop, and visual match need simulator review. Coach action is absent. |
| 2×4 equal-square grid | PARTIAL | `HomePageGrid` now derives one square `cellSide` from available width/height, centers the two-column grid, and places widgets on 8 cells. | Old code used separate column and row dimensions, producing non-square cells. New geometry is encoded and UI assertions were added; no simulator measurements yet. |
| Daily widget order and sizing | PARTIAL | `HomeState.defaultDailyPage`: large Calories & Protein Remaining at row 0, medium Next Workout row 2, two small widgets row 3; `DailyHomeUITests`. | Requested order is correct in source. New UI checks assert 2×2/2×1/1×1 relationships and dock clearance, but are unrun. |
| Daily macro/calorie details | PARTIAL | `HomeWidgetCard` and `CaloriesMacroVisual`. | Default now has a calorie ring, separate protein/carbs/fat bars, remaining values, and View Food affordance. Habits and detailed check-in still render generic summary text and lack the individually tappable subregions specified in §2.2. |
| Training/Food/Progress Home contents | PARTIAL | `HomeState.defaultPages`, generic `HomeWidgetCard`. | Four page containers exist, but several required charts, calendar details, trends, history, streak and suggestion behaviors are placeholders or incomplete. Do not infer completeness from their presence. |
| Home customization | PARTIAL | `HomeEditorScreen`, `LogbookStore` move/resize methods. | List-based editor and size/move/remove actions exist. Required long-press drag, predictable reflow, and full interaction guarantees are not verified. |
| Default theme engine | REFERENCE_LIMITED | `LogbookTheme.defaultTheme`, `ThemeTokens`, `ThemeBackdrop`, widget surfaces and dock. | Adds a shared semantic token structure and applies only the v2 Default styling. Palette, material, radius and opacity values remain provisional pending visual approval. Other legacy themes retain their prior token values and assets. |
| Current v2 theme catalogue | PARTIAL | `LogbookTheme` has the existing 16 legacy IDs plus a new Default ID. | The handoff’s 19 unique v2 themes are not implemented here. The legacy 16 were not removed or intentionally restyled. Remaining v2 themes are gated on Default approval. |
| Local persistence | PARTIAL | `LogbookStore`, `SharedStateFile`, repository tests. | Local JSON persistence and App Group sharing are present in source. Offline durability, migration, recovery and corruption behavior are not fully tested here. |
| WidgetKit / Lock Screen widgets | PARTIAL | `Sources/LogbookWidgets/LogbookWidgets.swift`. | Nutrition and training WidgetKit configurations include several system/accessory families. Full required widget inventory, live deep-link state and runtime behavior are not verified. |
| Live Activities / Dynamic Island | PARTIAL | `WorkoutActivityController`, `WorkoutActivityAttributes`, `WorkoutLiveActivityWidget`. | ActivityKit source exists. Lifecycle, timer semantics, device support, and Live Activity rendering have not been exercised. |
| Apple Watch / WatchConnectivity | PARTIAL | `WatchBridge`, `Sources/LogbookWatch/LogbookWatchApp.swift`, `WatchSnapshot`. | Companion target exchanges snapshots and workout actions in source; pairing, watchOS build, sync edge cases and watch UI are unverified. |
| Notifications | PARTIAL | `ReminderService`, Settings screens. | Local notifications are implemented in source; independent reminder defaults, scheduling behavior and delivery are untested. |
| HealthKit | BLOCKED by explicit user instruction | No HealthKit import/entitlement/request; Settings says access is off. | User explicitly chose no Health access. Keep disabled; no permission request or HealthKit implementation in this stage. |
| Authentication, cloud, coaching, Help | MISSING | No identity-provider/backend/coaching implementation found in `native-ios/Sources` or project targets. | Master spec §15 capabilities need a secure backend and real account/provider configuration. No simulated local-only coach UI should be presented as implementation. |
| Automated QA / visual baselines | PARTIAL | `LogbookTests`, `LogbookUITests`, `QA/Scripts`, workflow and issue register. | The test/screenshot workflow exists in source. Default geometry assertions and four-page captures were updated, but this environment cannot execute them. No screenshots have been approved or added as baselines. |

## Default implementation delivered in this worktree

- Added `default` theme ID; fresh `HomeState` now starts on Default. Existing saved theme values are not rewritten.
- Added semantic `ThemeTokens` for background, surfaces, text, accents, card material parameters and corner shape. Legacy theme visual values remain routed through their prior palette and rendering parameters.
- Bundled the handoff’s provisional Default blurred background in `Resources/LogbookAssets.xcassets/default.imageset`.
- Changed the grid from independent row/column sizing to one square-cell size, centered and constrained by the available Home width and height.
- Added the Default Daily calorie ring and three macro progress bars.
- Updated UI tests to assert Daily widget geometry and capture the four Home pages in Default only. Removed the old 16-theme screenshot loop from this gate.
- Updated QA instructions to require human visual review before baselines or additional v2 themes.

The above is not yet visually accepted, built, or tested. Default artwork/tokens are intentionally labelled provisional.

## Geometry contract now encoded in source/tests

For gap `g = 9 pt`, safe grid width `W`, and available grid height `H`, the implementation computes:

`cell = min((W - g) / 2, (H - 3g) / 4)`

`small = cell × cell`  
`medium = (2 × cell + g) × cell`  
`large = (2 × cell + g) × (2 × cell + g)`

The UI test asserts these equations and checks the bottom small widgets remain above the dock. These are equations from the source, **not measured simulator results**. Actual point rectangles will be attached by the UI test and must be reviewed on iPhone 18 Pro and a smaller simulator.

## Exact next verification

On a Mac with Xcode and XcodeGen installed, run:

```sh
./native-ios/QA/Scripts/run-daily-home-qa.sh "iPhone 18 Pro"
./native-ios/QA/Scripts/run-daily-home-qa.sh "iPhone 16e"
```

Open each generated `native-ios/QA/artifacts/daily-home-*/Logbook.xcresult` in Xcode and review the four `Home-*-Default-Candidate` PNG attachments plus the `Default Daily widget frames (points)` attachment. Confirm all content above the dock, no vertical scroll/clipping, theme legibility, and the actual Default style against the package references. The iPhone 16e name must be available in the selected Xcode runtime; if not, choose a smaller installed iPhone from Xcode’s Devices and Simulators list. Do not accept a screenshot baseline or proceed to other v2 themes until the user approves Default.
