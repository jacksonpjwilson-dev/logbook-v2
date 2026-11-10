# Logbook v2 handoff audit and Default gate

## Current milestone snapshot — 2026-11-08 (run #126)

Tested app source is `074ab167f4ea6826f6d9a7c5536257ea2c1bd395` on `codex/default-theme-gate1`. [Actions #126](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42496892834) succeeded on iPhone SE (3rd generation) and iPhone 16. Each device built successfully and passed 50/50 unit and 13/13 UI tests. The iPhone 18 Pro availability check passed, but its app-test step was skipped; it remains untested.

- **Training:** Program switching and independent rotations, scheduled/skip/out-of-order rules, split editing/search/custom exercises, tracking modes, supersets/rest, progression accept/decline, active workout/timer relaunch recovery, completion summary/PRs, same-day history, historical edit/delete/restore passed on both devices.
- **Food:** The exact four Add Food options, search/manual entry/correction, barcode fallback, serving selection, recents/favorites/recipes, Add/Replace copy, targets/remaining/trends/adherence, hydration, Food History correction and recovery passed. The suite exposed Food History taps being intercepted by the full-list swipe. The swipe is now scoped to the nutrition summary, and navigation passed on both devices.
- **Limits:** Food compact date picker lacks a dedicated UI assertion. CNF/Open Food Facts tests use controlled responses; live availability, terms, completeness and network-loss behavior are unverified. Physical camera scanning/permission is unverified. iPhone 18 Pro app tests are untested.
- **Artifacts:** actual unapproved Simulator captures and reports: [iPhone SE](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42496892834/artifacts/13624920583), [iPhone 16](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42496892834/artifacts/13624832311), [iPhone 18 Pro availability only](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42496892834/artifacts/13624205975).
- **Design and safety:** captures are candidates, not accepted baselines. The approved 2×4 Home geometry and all 16 themes remain unchanged; Default visual approval is pending. HealthKit remains disabled, tests use isolated synthetic data, and no production configuration or `main` branch was changed.

Historical snapshots below are retained as provenance; this section is the current status.

## Training verification and Food milestone — current source audit (2026-11-08)

This source audit section is historical; the current snapshot above supersedes its implementation and CI state. Current branch head and run results are tracked in `CURRENT_MILESTONE.md` and `REPORT.md`. Run #84 failure details and the local fixes are documented in REPORT.md and CURRENT_MILESTONE.md. Its iPhone 18 Pro QA step was skipped, so that simulator remains untested. Run #82 failed both available builds before tests because the large Food view expression exceeded Swift's type-check limit; the view was split into smaller computed sections/helpers before #83. See `REPORT.md` for actual results once completed.

### Current implementation findings

- **Training:** UI test source now drives program switching and scheduled skip, supersets and round-based rest, tracking-mode selection, progression decline, multiple sessions on a date, PR presentation, and historical edit/delete/restore. Store test source covers independent flexible rotations, out-of-order/discard/rest rules, draft program ownership, timer lifecycle, compatible tracking modes, first-session PR baseline and post-edit/deletion PR recalculation. Run #87 UI results and currently executing #88 are summarized in the top snapshot; the historical #84 results below are retained only as provenance.
- **Food:** persistent offline-first models and screens implement meal logging/editing, local/remote search, the exact four Add Food choices, manual and barcode paths, portion confirmation/conversion, favorites/recents, recipe persistence, Add/Replace copy with recoverable replacement, effective-dated nutrition goals, adherence and remaining calculations, 7-day trends, hydration history, Food History and Recently Deleted. Store tests cover persistence and calculations; the current UI test navigates search/manual entry/history correction/recovery and barcode manual fallback. The Food simulator tests in run #83 did not execute because compilation failed. Local candidate `edb4f74` adds horizontal date swipe tests, recipe/target/hydration/favorites/recents UI coverage and soft-delete/recovery/expiry for Food entries, water logs and recipes. It has not been pushed or run; do not count these additions as verified.
- **External data:** the CNF and Open Food Facts adapters use public HTTPS APIs and require no credential. Parser tests do not verify live service uptime, field completeness, licensing/attribution obligations, quality of serving-size provenance or offline recovery across runtime network changes. Those remain open validation items.
- **Scanner:** AVFoundation barcode capture exists; automated simulator UI covers safe manual fallback rather than real-world camera/barcode recognition. Physical scan verification remains open.
- **Visual constraints:** the user accepted the latest Default screenshots as a provisional working direction, not final approval. No geometry, theme or screenshot baseline was changed in these commits. The four-page Home grid/dock contract and unused split cells are preserved. Other theme implementations remain gated.
- **Environment/safety:** this Linux workspace cannot run Xcode. CI uses synthetic isolated stores. HealthKit remains disabled; neither production configuration nor `main` was touched.

The canonical row-level tracker and `CURRENT_MILESTONE.md` are updated for this source audit. They deliberately mark newly added acceptance paths unverified until the exact current commit completes CI.

## Current Training UI verification — 2026-11-08

**Branch:** `codex/default-theme-gate1`
**App source:** `f4b2cca17b3ba6bab2207783438f2296ffe93083`
**Tested commit:** `dfd8678efdc354d47aac0e549850a46bae533cdd`
**Evidence:** [GitHub Actions run #80](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42430593049)

Run #80 compiled and executed the QA workflow on iPhone 16 and iPhone SE (3rd generation), iOS 18.5. Each ran 34 unit tests and 7 UI tests: **41 passed, 0 failed, 0 skipped per device**. The iPhone 18 Pro test step was skipped; it remains **untested**. Run #79 previously failed the iPhone 16 drag-reorder assertion (40/41 there) but passed on SE (41/41). The test-only centered/slow-drop correction in `dfd8678` passed on both devices in #80. Run #80 is the latest fully green app/test evidence; run #42 is the historical green baseline before these expanded UI tests.

The passing UI suite drives real app screens through: Daily and all four Home pages, small check-in regions, Training Home/calendar, workout start and set entry, pinned rest timer and relaunch recovery, Workout Split editing/reordering, exercise search/selection/custom creation and prescription changes, explicit progression acceptance, completion summary, historical corrections, deletion and Recently Deleted restoration. The 34 unit tests include timer controls/recovery, rotation rules, split order, session persistence, PR baseline/recalculation and related Training business logic.

The blue rest timer is pinned immediately below the Active Workout header and outside the scrollable set list. Run #80 includes captures and an assertion that it stays visible above the exercise fields while scrolling. The approved 2×4 Home geometry and five-icon dock are unchanged.

The Training Split with one actual workout leaves seven cells empty. This follows master spec §2.3, which says not to fabricate entries. The eight-workout synthetic candidate fills the same fixed geometry. The request to remove the empty-space appearance is in tension with this explicit rule; no alternate approved content is available, so the empty positions remain and the conflict is recorded.

Default appearance and active-workout visuals remain **pending human review**. Actual candidates from iPhone 16 and SE are in `/workspace/logbook-training-review-run80/index.html` and `/workspace/logbook-training-review-run80.zip`; none is a protected baseline. Active Workout and completion/history sheets use grouped system surfaces instead of Home’s translucent style, and completion has substantial unused upper area. There is no screen-specific source art to authorize a correction.

The 26 original binary theme references are present in the supplied handoff workspace but not in the repository. Their exact filenames and target category folders are listed in `docs/handoff-v2/themes/REFERENCE_INDEX.md`; four Glass images are thumbnail-only. No theme, baseline, production configuration or `main` branch was changed. HealthKit remains disabled.

## Historical audit record — 2026-11-06

The audit sections below are retained for provenance and describe older snapshots. The current evidence above and the row-level canonical tracker supersede their historical test counts and implementation statuses.

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


## Daily Tracking & Food provider audit — 2026-11-10

**Repository evidence:** source commit `0acf4353f6f39b6f6597669cb34cbcc56a020c7a` adds persistent Sleep, Weight and Supplement records/workflows, updates `DailyHomeMetrics` to ignore naps and deleted records for overnight completion, and adds sleep history aggregation including naps. It is not yet runtime-verified; Actions #129 is pending. The prior fully verified source remains run #126 / `074ab167f4ea6826f6d9a7c5536257ea2c1bd395`.

**Food date navigation:** direct compact date-picker UI coverage is in runs #127/#128. Run #128's iPhone SE matrix job passed 50 unit and 13 UI tests; iPhone 16 remained in progress at audit time. iPhone 18 Pro application tests were skipped.

**Direct live-service probe (outside Logbook):** the Health Canada 2015 CNF API returned food and nutrient payloads; Open Food Facts product lookup returned barcode nutrition; OFF v2 full-text search returned 503, while `/cgi/search.pl` returned results. These are direct endpoint observations, not in-app network/parser/cache/retry verification. OFF API requirements include a meaningful User-Agent/contact, API usage declaration and request limits; its database content is ODbL. The current application has no configured user contact email. Health Canada 2026 CNF data is available as an Open Government Licence – Canada dataset; migration and source/licence presentation have not been implemented or approved.

**Still incomplete:** Progress & History lacks the complete five-tab chart contract, exercise-specific strength trends, balanced activity heatmap and Nutrition Adherence Home/history flow. Category-specific Sleep/Weight/Supplement history and recent-delete UI were added but await #129. Physical camera testing is unavailable without iPhone hardware. No themes, production data or `main` were changed.
