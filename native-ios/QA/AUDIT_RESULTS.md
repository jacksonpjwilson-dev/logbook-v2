# Logbook v2 handoff audit and Default gate

## Training milestone update — implementation in progress

**Review date:** 2026-11-07. Source updated on the isolated `codex/default-theme-gate1` branch. This section records source-level work added for Training System Phase 2; it does not claim runtime verification. This environment is Linux and has no `xcodebuild`, `xcrun`, Swift compiler, or Simulator. The branch CI run is the required compile/runtime check.

### Implemented in source for this phase

- Multiple named programs, one active program, independent flexible rotations, migration from the legacy single-program rotation, skip without history, and scheduled versus out-of-order session association.
- Program association is stored on a workout draft so switching programs does not change the origin of a running session. Completion advances only its originating scheduled slot; discard does not advance.
- Template management now includes per-program ordering, cross-program moves, exercise ordering, custom exercises, tracking mode, planned set/reps/rest configuration, and superset grouping controls.
- Active sessions retain tracking mode, set data, exercise/session notes, timer state and origin metadata in the existing persistent store. The UI provides exercise expansion, session-only replacement before work begins, optional progression suggestion acceptance, and completion summary.
- Completed records support set/note edits, soft-delete/restore/permanent deletion and expiry; PR and workout-summary values are derived from visible stored sessions so edits/deletions recalculate immediately. Weighted-and-reps Epley estimates use the first eligible performance as baseline, then one best event per exercise/session for later strict improvements.
- Training History provides a month calendar and multiple sessions per date, alongside PR and Recently Deleted sections.
- Added store tests for program isolation/migration/rotation, scheduled and out-of-order completion, partial saves/discard, session-origin preservation, PR baseline and recalculation, deleted-record expiry, alternate tracking modes, timer controls/recovery and superset rest.
- Added a UI screenshot attachment for the active workout in addition to the four Home pages.

### Verification state

- Prior run #26 failed compilation before tests on iPhone 16 and iPhone SE. The iPhone 18 Pro matrix entry skipped tests because that simulator was unavailable.
- Prior run #27 built and executed the Daily Home UI suite on iPhone 16 and iPhone SE; widget-geometry assertions passed on both. Its two failures were the JSON date round-trip timer assertion and the Start Workout navigation assertion. The local source addresses both, but those fixes have not yet passed CI.
- Run #28 attempted a build on iPhone 16 and iPhone SE but failed before test execution on a misspelled Calendar argument label in `CheckInHistorySettingsScreens.swift`. Both available-device jobs failed to compile; zero tests ran and no screenshot candidates were produced. The source now changes the label to `toGranularity:`; this fix is pending CI.
- No successful Phase 2 build, unit test, screenshot, iPhone SE result, or active-workout recovery has run against the current Training changes yet. iPhone 18 Pro remains untested.
- Default theme geometry, the 16 legacy themes and HealthKit-disabled configuration were not intentionally altered. This is a source-level statement pending the full CI run.

### Remaining verification and known limits

- CI must compile and run the expanded suite. Correct any actual compiler/test failures before reporting completion.
- A simulator UI test now captures Active Workout, but the current workflow only runs the Daily UI test suite; detailed interactions for every editor/history flow remain unverified.
- "Force quit then reopen" persistence is covered at repository reopen/unit-test level, not yet by an OS-level UI kill/relaunch scenario.
- Provisional Default visual work remains awaiting human review; these Training changes do not imply visual approval. iPhone 18 Pro remains unavailable/unverified.
- Authentication, coaching/cloud sync, Food/Sleep/Weight/Supplements, native integration runtime, Watch hardware, physical device, and remaining theme visual acceptance are outside this Training phase.

**Audit date:** 2026-11-06  
**Source package:** `LOGBOOK_CODEX_COMPLETE_VISUAL_HANDOFF_v2.zip`  
**Authority:** `LOGBOOK_MASTER_SPEC.md` v1.2 and theme addendum §16.  
**Repository branch in this worktree:** `codex/default-theme-gate1`, created from the isolated QA branch at `8741ee53b9495d5558d6a35b152772fca3fbd646`. No changes were made to `main`. The tested source commit is `9d6a724655218de42f0f4b70f66f9be37c7db12e`. GitHub Actions run: https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42274999088.

## Environment and evidence limits

This workspace is Linux and has no local Xcode or iOS Simulator. The isolated macOS GitHub Actions runner built and tested source commit `9d6a724655218de42f0f4b70f66f9be37c7db12e` on iPhone 16 / iOS 18.5: 7 tests passed (6 store/unit, 1 UI), 0 failed, 0 skipped. The workflow produced four PNG captures, uploaded in artifact `daily-home-qa-results` (run https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42274999088). The QA guard confirmed there were no missing-image runtime warnings. No screenshot was approved or added as a baseline.

The screenshots are real app captures, not generated mockups. They are review candidates only; the Default art and token measurements remain provisional. The package has `themes/references/defaults/default_CONCEPT.png` and `default_COMPOSITE_CROP.png`, both style references, plus `themes/backgrounds/default_PROVISIONAL_BLUR.jpg`, which is a provisional starter background and is now bundled for the Default candidate. None is an approved pixel-perfect export. Reference gaps and screenshot tasks are listed in `VISUAL_DIFFS/README.md`.

## Requirement-to-implementation findings

| Area | Status | Source evidence | Finding |
|---|---|---|---|
| Four Home pages and horizontal paging | PARTIAL | `HomeScreen` uses a page-style `TabView`; `HomeState.defaultPages` defines Daily, Training, Food, Progress & History. UI test captures those pages. | All four pages were rendered and captured; paging controls are visible. The UI test navigates by page-dot buttons, so the swipe gesture itself was not directly automated. |
| Fixed athlete dock | PARTIAL | `LogbookDock` contains Training, Food, History, Sleep, Settings; bottom safe-area inset. | All five actions were present in the iPhone 16 capture and UI hierarchy; dock was visibly above the home indicator. Coach action is absent. iPhone 18 Pro and smaller-device insets remain unverified. |
| 2×4 equal-square grid | PARTIAL | `HomePageGrid` now derives one square `cellSide` from available width/height, centers the two-column grid, and places widgets on 8 cells. | Old code used separate column and row dimensions, producing non-square cells. New geometry is encoded and UI assertions were added; no simulator measurements yet. |
| Daily widget order and sizing | PARTIAL | `HomeState.defaultDailyPage`: large Calories & Protein Remaining at row 0, medium Next Workout row 2, two small widgets row 3; `DailyHomeUITests`. | The iPhone 16 UI test verified the requested order, frame ratios, dock clearance and calorie-widget routing. Habits/check-in content and the workout quick action remain incomplete. |
| Daily macro/calorie details | PARTIAL | `HomeWidgetCard` and `CaloriesMacroVisual`. | Default now has a calorie ring, separate protein/carbs/fat bars, remaining values, and View Food affordance. Habits and detailed check-in still render generic summary text and lack the individually tappable subregions specified in §2.2. |
| Training/Food/Progress Home contents | PARTIAL | `HomeState.defaultPages`, generic `HomeWidgetCard`. | Four page containers exist, but several required charts, calendar details, trends, history, streak and suggestion behaviors are placeholders or incomplete. Do not infer completeness from their presence. |
| Home customization | PARTIAL | `HomeEditorScreen`, `LogbookStore` move/resize methods. | List-based editor and size/move/remove actions exist. Required long-press drag, predictable reflow, and full interaction guarantees are not verified. |
| Default theme engine | REFERENCE_LIMITED | `LogbookTheme.defaultTheme`, `ThemeTokens`, `ThemeBackdrop`, widget surfaces and dock. | Adds a shared semantic token structure and applies only the v2 Default styling. The provisional background asset loaded in the simulator and the captured pale blue translucent treatment is available for review. Palette/material/radius/opacity values are not visually approved. Other legacy theme tokens/assets were not intentionally changed. |
| Current v2 theme catalogue | PARTIAL | `LogbookTheme` has the existing 16 legacy IDs plus a new Default ID. | The handoff’s 19 unique v2 themes are not implemented here. The legacy 16 were not removed or intentionally restyled. Remaining v2 themes are gated on Default approval. |
| Local persistence | PARTIAL | `LogbookStore`, `SharedStateFile`, repository tests. | Local JSON persistence and App Group sharing are present in source. Offline durability, migration, recovery and corruption behavior are not fully tested here. |
| WidgetKit / Lock Screen widgets | PARTIAL | `Sources/LogbookWidgets/LogbookWidgets.swift`. | Nutrition and training WidgetKit configurations include several system/accessory families. Full required widget inventory, live deep-link state and runtime behavior are not verified. |
| Live Activities / Dynamic Island | PARTIAL | `WorkoutActivityController`, `WorkoutActivityAttributes`, `WorkoutLiveActivityWidget`. | ActivityKit source exists. Lifecycle, timer semantics, device support, and Live Activity rendering have not been exercised. |
| Apple Watch / WatchConnectivity | PARTIAL | `WatchBridge`, `Sources/LogbookWatch/LogbookWatchApp.swift`, `WatchSnapshot`. | Companion target exchanges snapshots and workout actions in source; pairing, watchOS build, sync edge cases and watch UI are unverified. |
| Notifications | PARTIAL | `ReminderService`, Settings screens. | Local notifications are implemented in source; independent reminder defaults, scheduling behavior and delivery are untested. |
| HealthKit | BLOCKED by explicit user instruction | No HealthKit import/entitlement/request; Settings says access is off. | User explicitly chose no Health access. Keep disabled; no permission request or HealthKit implementation in this stage. |
| Authentication, cloud, coaching, Help | MISSING | No identity-provider/backend/coaching implementation found in `native-ios/Sources` or project targets. | Master spec §15 capabilities need a secure backend and real account/provider configuration. No simulated local-only coach UI should be presented as implementation. |
| Automated QA / visual baselines | PARTIAL | `LogbookTests`, `LogbookUITests`, `QA/Scripts`, workflow and issue register. | The macOS workflow executed 6 store/unit tests and 1 UI test: 7 passed, 0 failed, 0 skipped. It exported 4 Home page captures and measured Daily geometry. The run is linked above. No screenshots have been approved or added as baselines. |

## Default implementation delivered in this worktree

- Added `default` theme ID; fresh `HomeState` now starts on Default. Existing saved theme values are not rewritten.
- Added semantic `ThemeTokens` for background, surfaces, text, accents, card material parameters and corner shape. Legacy theme visual values remain routed through their prior palette and rendering parameters.
- Bundled the handoff’s provisional Default blurred background in `Resources/LogbookAssets.xcassets/default.imageset`.
- Changed the grid from independent row/column sizing to one square-cell size, centered and constrained by the available Home width and height.
- Added the Default Daily calorie ring and three macro progress bars.
- Updated UI tests to assert Daily widget geometry and capture the four Home pages in Default only. Removed the old 16-theme screenshot loop from this gate.
- Updated QA instructions to require human visual review before baselines or additional v2 themes.

The Default candidate built and passed the listed automated tests. It is not visually accepted. Default artwork/tokens remain provisional.

## Geometry contract now encoded in source/tests

For gap `g = 9 pt`, safe grid width `W`, and available grid height `H`, the implementation computes:

`cell = min((W - g) / 2, (H - 3g) / 4)`

`small = cell × cell`  
`medium = (2 × cell + g) × cell`  
`large = (2 × cell + g) × (2 × cell + g)`

The UI test asserts these equations and checks the bottom small widgets remain above the dock. iPhone 16 / iOS 18.5 measured: large `(62.67, 177.00, 267.67, 267.67)`, medium `(62.67, 453.67, 267.67, 129.00)`, small-left `(62.67, 591.67, 129.33, 129.33)`, small-right `(201.00, 591.67, 129.33, 129.33)`, dock item top at `y=755.67`. Small widgets end at `y=721`, 34.33 points above the dock. iPhone 18 Pro and smaller-size capture remain to be run.

## Review and next verification

Open the downloadable review gallery and inspect the four PNG candidates before approving the Default appearance. The visible default screen follows the required large/medium/two-small structure and has no clipped widgets; the full-screen style is close to the supplied pale-blue blurred reference, which remains a concept/style image and does not define exact final colors. Do not use automated success as visual approval.

After review, rerun `./native-ios/QA/Scripts/run-daily-home-qa.sh "iPhone 18 Pro"` on the user's Mac and choose an installed smaller iPhone for a second run. Review the output for Dynamic Type, content clipping and sizing. Do not accept a screenshot baseline or implement other v2 themes until the user approves Default.
