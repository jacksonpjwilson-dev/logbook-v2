# Logbook QA report — Daily Tracking & Progress

**Branch:** `codex/default-theme-gate1`  
**Current source commit:** `705aec30376cbc9285c7cc4d4e1955666fab0160`  
**Last fully green app-source baseline:** Actions #128, `a79ee507422e7f09d4ad56b9a5a157da17743f39` ([run](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42767782249)). Run #126 remains preserved as a historical baseline. Run #131 is a failed verification of earlier check-in source; later fixes have not completed a run.

## Runs

| Run | Commit | iPhone SE (3rd gen) | iPhone 16 | iPhone 18 Pro |
|---|---|---|---|---|
| [#126](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42496892834) | `074ab167f4ea6826f6d9a7c5536257ea2c1bd395` | Passed build, 50/50 unit, 13/13 UI | Passed build, 50/50 unit, 13/13 UI | App tests skipped |
| [#127](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42767506189) | `a56a882c30bbf9fb684244349a5b1daf71533905` | Passed build, 50/50 unit, 13/13 UI | Passed build, 50/50 unit, 13/13 UI | App tests skipped |
| [#128](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42767782249) | `a79ee507422e7f09d4ad56b9a5a157da17743f39` | Passed build, 50/50 unit, 13/13 UI | Passed build, 50/50 unit, 13/13 UI | App tests skipped |
| [#129](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42769523988) | `0acf4353f6f39b6f6597669cb34cbcc56a020c7a` | Build failed; no tests | Build failed; no tests | App tests skipped |
| [#131](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42771133119) | `aaf18f155b4b713eaa1cc6bb0cf6b93a9e25461e` | Build passed; 54/55 unit, 11/14 UI | Build passed; 54/55 unit, 11/14 UI | App tests skipped |
| #132–#149 | Intermediate check-in, chart and test-fix commits through current source | Running/queued; no final pass yet | Running/queued; no final pass yet | App tests skipped by availability rule |

Run #131 failures:
- Both devices: `testLegacySleepAndWeightRecordsDecodeWithNewOptionalFields` failed because old weight JSON without an ID could not decode.
- Both devices: `testCheckInSleepNapWeightAndSupplementWorkflow` could not find the Recently Deleted sleep restore action while its row was below the visible list.
- iPhone 16: `testDailySmallWidgetRegionsOpenTheirMatchingCheckInSections` used obsolete visible labels instead of current stable accessibility identifiers; `testWorkoutSplitEditorSupportsReorderingExerciseSearchAndCustomExercises` checked an off-screen lazy workout row.
- iPhone SE: `testDailySmallWidgetRegionsOpenTheirMatchingCheckInSections` used the same obsolete labels; `testWorkoutCompletionHistoryEditingAndRecentlyDeletedRecovery` re-counted a lazy same-day label instead of verifying the retained session by ID.

Source and UI-test corrections, legacy supplement decoding, Default Progress widgets, strength/protein history series, selected heatmap-day navigation and a deleted-food trend regression test are committed through `705aec30376cbc9285c7cc4d4e1955666fab0160`. These corrections are pending Actions #132–#149; do not describe them as passing until an exact current-source run finishes green.

## Food evidence

- #127 verified Food date arrows/swipe, selected date and direct date-picker navigation on both available simulators.
- #126 verified Food History edit/recovery, manual entry and unknown-barcode fallback.
- Direct live endpoint probes outside Logbook returned CNF and OFF data. CNF code 1704 (raw banana) returned per-100-g values: 89 kcal, 1.09 g protein, 22.84 g carbohydrate and 0.33 g fat. OFF barcode `3017620422003` returned per-100-g data but no verified gram serving, so no serving conversion was inferred. OFF `/api/v2/search` returned HTTP 503; `/cgi/search.pl` returned HTTP 200.
- The app's network/parser/cache path has not been tested against those live responses; current simulator provider tests use controlled responses. OFF needs a configured contact-bearing User-Agent and usage declaration, with ODbL attribution/share-alike release review. The legacy CNF endpoint/source should be reviewed against the 2026 dataset and Open Government Licence – Canada. No API key was needed for direct probes.
- Physical camera permission and barcode scanning remain unverified without an actual iPhone.

## Current implementation and remaining work

Sleep/Weight/Supplement check-ins now have wake-date overnight sleep, naps, duration override, quality, one weight/day with conversions/comparison, configurable daily/weekday supplement schedules, Taken/Undo and 30-day soft-deletion recovery. Habits use overnight sleep, weight and due supplements with no-due days neutral. These are implemented but not simulator-verified at the current source SHA.

Default Progress Home now has data-derived Weight, Strength, Sleep, Calories and Protein 30-day metrics, strength exercise selection, numbered daily heatmap navigation, PRs This Month and Nutrition Adherence. History includes strength and protein charts; the calorie series excludes soft-deleted foods. The new screens have no current passing simulator capture yet. Remaining open: heatmap scoring regression coverage, complete category-specific History navigation/edit/recovery, and recalculation checks across edit/delete/restore/expiry for every trend.

## Screenshots and safety

Run #131 generated real Simulator candidates even though the run failed: [iPhone SE artifact](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42771133119/artifacts/13743096416) · [iPhone 16 artifact](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42771133119/artifacts/13742394589). They show earlier source and are not approved. Run #128 artifacts remain available: [SE](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42767782249/artifacts/13741520414) · [iPhone 16](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42767782249/artifacts/13741154325). iPhone 18 Pro has availability information only.

Keep the four Home pages, exact 2×2 × 4 widget geometry, five-icon dock and all existing theme designs. No visual baseline is approved by passing automation. HealthKit remains disabled. Tests use isolated synthetic data. No production configuration or `main` branch was changed.
