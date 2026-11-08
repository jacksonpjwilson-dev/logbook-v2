# Logbook QA report

## Latest completed CI

**Branch:** `codex/default-theme-gate1`
**Tested source:** `54c236485bcd16ffa685ce5cea02d9e27a0220f2`
**Actions run:** [#90](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42457771622)

| Simulator | Build | Unit tests | UI tests | Result |
|---|---|---:|---:|---|
| iPhone SE (3rd generation) | Passed | 44/45 passed | 8/13 passed | Failed |
| iPhone 16 | Passed | 44/45 passed | 8/13 passed | Failed |
| iPhone 18 Pro | Availability check only | Not run | Not run | Untested; step skipped |

The single unit failure on both tested devices is `testLegacyNutritionPayloadDecodesWithoutNewFoodFields`: a legacy saved recipe lacks the newer `updatedAt` field. The local follow-up adds a backwards-compatible decoder default, but it is not in the tested commit yet.

The five UI failures on both available simulators were:

- `testDailyHomeLayoutAndCaptureAllHomePages`: Food-page frame probes had zero-sized accessibility frames.
- `testFoodCopyAddAndReplaceUsesSelectedDateAndMatchingMeal`: tapping the previous-day control did not change the selected date as asserted.
- `testFoodManualEntryOptionsHistoryCorrectionAndRecovery`: the Food date swipe did not change the selected date as asserted.
- `testFoodTargetsHydrationFavoritesRecentsAndRecipeWorkflow`: active search presented Cancel/Clear instead of the Done toolbar action.
- `testWorkoutCompletionHistoryEditingAndRecentlyDeletedRecovery`: returning from an individual calendar workout did not restore the calendar date screen.

The local follow-up changes the frame test to inspect accessible widget roots, stores the selected Food date as a stable date key, exits search before pressing Done, and gives the calendar its own navigation path. These changes have not been built or run. The Linux development environment has no Xcode, Swift compiler or iOS Simulator.

## Screenshots and results

Actual, unapproved run #90 artifacts:

- [iPhone SE result bundle, screenshots, and test logs](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42457771622/artifacts/13608512203)
- [iPhone 16 result bundle, screenshots, and test logs](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42457771622/artifacts/13609390347)
- [iPhone 18 Pro availability report](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42457771622/artifacts/13607842943)

These are simulator captures from the failed run and are candidates for review only. No image is automatically approved or used to overwrite a baseline.

## Training verification

Run #90 passed business/store tests for independent flexible workout-program rotations, scheduled skip and out-of-order behavior, discard, workout origin-program retention, rest timer and supersets, exercise tracking modes, progression accept/decline, multiple same-day sessions, completed-record edits and recovery, and PR calculation. On both simulators, UI tests passed for program switching/rotation, split reordering/search/custom exercise, progression decisions, starting the next workout, daily check-in regions and hydration history recovery. The calendar history UI test failed as listed above. Rest-day non-advance, app termination recovery, and PR recalculation after deleting/restoring a record still lack direct UI proof. Training is not fully verified.

## Food and Nutrition verification

The implementation includes persistent meal logging/editing, the exact four Add Food choices, CNF/Open Food Facts adapters, barcode scan and unknown-code manual fallback, serving conversions, manual food correction, recent/favorite foods, saved recipes, Add/Replace copying, dated goals/snapshots, remaining calorie/macro calculations, nutrition trends/adherence, hydration history, Food History and recoverable deletion. The #90 store suite ran 45 tests (44 passed, 1 failed) on each available simulator. Food-specific end-to-end UI scenarios were not green, so the Food milestone is not complete.

The #90 UI suite did verify Home navigation to the Food page, hydration quick-add/history recovery, individual meal navigation, four Add Food options, and some Food navigation; it failed in the four Food cases listed above. The current local candidate must pass those scenarios before reporting the user-facing flows as verified.

Canadian Nutrient File and Open Food Facts public APIs require no credentials. Live API availability/completeness, provider attribution and licensing review, offline transitions, and physical-camera barcode scanning remain unverified. The simulator scanner UI uses manual barcode entry and does not prove camera behavior.

## Current untested follow-up

Local changes address the run #90 decoder, date, accessibility-frame, search-dismissal, and calendar-return defects. `git diff --check` must pass before commit. They will be reported only after a new Actions run completes. Current Home geometry, five-icon dock, all existing themes and HealthKit-off configuration are preserved. Default visuals remain provisional and user approval is separate from technical tests. No production configuration or `main` branch has been modified.
