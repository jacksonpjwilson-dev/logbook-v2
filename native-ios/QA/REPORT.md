# Logbook QA report

## Latest executed CI evidence

**Development branch:** `codex/default-theme-gate1`
**Latest tested commit:** `10fd85f930b437f8189c048b7e3d2e598b547e8a`
**Actions run #85:** https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42449791762
**Builds:** succeeded on iPhone SE (3rd generation) and iPhone 16. iPhone 18 Pro test action was skipped; it is **untested**.

| Simulator | Unit tests | UI tests | Result |
|---|---:|---:|---|
| iPhone SE (3rd generation) | 42 executed, 40 passed, 2 failed | 11 executed, 7 passed, 4 failed | Failed |
| iPhone 16 | 42 executed, 40 passed, 2 failed | 11 executed, 8 passed, 3 failed | Failed |
| iPhone 18 Pro | Not executed | Not executed | Untested (job test step skipped) |

The two unit failures were test-fixture/expectation problems rather than production logic regressions: the legacy recipe payload omitted required `id`, and the Add-then-Replace unit case expected two soft-deleted records although three destination rows matched meals represented in the source. Both test corrections are in the pending local candidate.

UI failures on both devices:

- Food day swipe interacted with the compact date picker, leaving the selected day one day off after the follow-up action. The gesture is now limited to the macro summary area and the test swipes away from the picker.
- Food hydration `+500` could not be found after the nutrition-target sheet closed on iPhone SE; the next test adds an explicit Food-screen return assertion and will re-check the row on both sizes.
- Progression decline compared different lazy-list TextFields because the prior query matched by label. The test now follows one stable set-field accessibility ID; a store test explicitly checks that decline leaves prescription values unchanged.

Additional iPhone SE UI failure:

- Workout Recently Deleted restoration assertion checked the first history row rather than the exact restored workout. The test now carries the workout UUID from the Restore button to the corresponding History row.

The workflow still produced actual Simulator screenshot candidates. Download them from the run’s [iPhone 16 artifact](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42449791762/artifacts/13606170507) or [iPhone SE artifact](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42449791762/artifacts/13605871052). Neither is an approved visual baseline. The iPhone 16 log measured the Daily layout at: large 268.52 × 268.52 pt; medium 267.5 × 129.25 pt interior measurement; small 130.18 × 130.18 pt each; dock top at y=757.67 pt. Geometry assertions passed in that run.

## Current implementation and remaining verification

Training has persistent programs/rotations, templates, exercise selection and prescriptions, supersets, active workout lifecycle, timer recovery, progression, history, deletion recovery and PR calculation. Run #85 passed several focused UI paths, including program switching/skip, Workout Split editor/search/custom exercise, tracking mode/superset/rest, workout summary/PR presentation. However, the aggregate run failed; the corrected decline and restore UI checks have not run yet. Direct calendar drill-in for multiple sessions, rest-day UI, and UI-visible PR recalculation after historical edits/deletes remain open.

Food implementation includes logged meals and edits, local/public search, exact four Add Food options, CNF/Open Food Facts adapters, unknown-barcode fallback, verified conversions, manual corrections, independent favourites/recent items, recipes, Add/Replace copy, historical nutrition goals, remaining totals/adherence/trends, hydration history, offline persistence and Food History/recovery. The latest source adds selectable calories/protein/carbs/fat trends and omits unlogged dates from plotted averages. Added metric, Add/Replace, recipe recovery and water recovery UI tests are not yet executed. Run #85 Food tests failed at the assertions described above, so Food has **not** passed end-to-end verification.

External CNF/Open Food Facts calls use public APIs and require no credential. Live uptime/catalog completeness, applicable licensing and attribution review, runtime network-loss/offline transitions, and camera barcode recognition on a physical iPhone are unverified. Simulator barcode flow tests only the manual fallback.

## Pending candidate changes

Local source changes currently correct the #85 assertions, constrain the Food swipe gesture, add Food trend metric selection, exercise Add/Replace copy and water/recipe recovery, and add a recipe snapshot unit regression. They have not yet been published or run in CI. Record their exact commit and outcome here after the next workflow completes.

## Baseline and guardrails

Run #80 remains the previous last fully green app/test baseline: commit `dfd8678efdc354d47aac0e549850a46bae533cdd`, 34 unit + 7 UI = 41/41 on both available devices. It does not cover the later code. The user’s latest visual feedback approves the Default appearance only as a provisional direction. No screenshot is approved or overwritten as a baseline; the 16 existing themes and exact Home geometry remain unchanged. HealthKit is disabled; tests use isolated synthetic state; no production configuration or `main` branch was modified.

This environment is Linux without Xcode or iOS Simulator. Actual build/test and Simulator screenshot evidence must come from the macOS Actions workflow.
