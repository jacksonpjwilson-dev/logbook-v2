# Logbook QA report

## Current source and latest completed run

**Development branch:** `codex/default-theme-gate1`
**Remote source head:** `f28e71c9fcfa4ddf3289e5467d3e591737eedb35`
**Latest completed run:** [Actions #88](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42454022156), source `f28e71c9fcfa4ddf3289e5467d3e591737eedb35`.

| Simulator | Build | Unit tests | UI tests | Result |
|---|---|---:|---:|---|
| iPhone SE (3rd generation) | Passed | 42 passed / 1 failed (43) | 6 passed / 7 failed (13) | Failed |
| iPhone 16 | Passed | 42 passed / 1 failed (43) | 8 passed / 5 failed (13) | Failed |
| iPhone 18 Pro | Availability check only | Not run | Not run | Untested; test step skipped |

The common unit failure was `testLegacyNutritionPayloadDecodesWithoutNewFoodFields`: the fixture used the invalid UUID string `legacy-water`. The current candidate changes this to a valid UUID; that fix has not run yet.

UI failures from the run logs: frame assertions included child content rather than the exterior Food widget frames; the Food previous-day button did not update the tested date label; the macro swipe accessibility ID matched multiple descendants; the Water Goal sheet failed to appear after changing from another Food sheet; and the progression-decline test read a changed numeric-field value even though the store-level decline test verifies no suggested weight is written. SE additionally failed to find a lazy hydration action and failed one split reordering gesture. No product behavior is considered fixed until the next run confirms it.

Actual, unapproved run #88 screenshots and test reports:

- [iPhone SE artifact](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42454022156/artifacts/13607506214)
- [iPhone 16 artifact](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42454022156/artifacts/13607580740)
- [iPhone 18 Pro availability note](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42454022156/artifacts/13607275657)

Earlier run #87 is [here](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42451731246); it also failed. The last fully green source baseline remains run #80 at `dfd8678efdc354d47aac0e549850a46bae533cdd`, with 34 unit + 7 UI tests passing on SE and iPhone 16. It does not verify later changes.

## Training verification

Store-level tests cover independent program rotations, scheduled skip, out-of-order completion and discard, origin-program association, rest-timer pause/resume/extension/skip/reopen, superset round timing, tracking modes, progression acceptance and decline, first-workout PR baseline, one event per exercise per workout, multiple same-day sessions, historical corrections and deletion/recovery, and PR recalculation. The #88 unit suite executed those sources except for the failing legacy fixture test; the aggregate run remains red.

Simulator UI tests exercise the split editor, exercise search/custom exercises, prescriptions, tracking-mode selection, superset rest behavior, program switching/skip, progression, workout completion and PR presentation, and history correction/deletion/recovery. A local follow-up adds same-day calendar session drill-in and visible PR recalculation after editing. Direct UI evidence remains open for rest-day non-advance, PR recalculation after deletion/restoration, and app termination/relaunch recovery. Training is not verified complete.

## Food and Nutrition implementation

Persistent code covers food and meal logging/editing, the exact four options Search Foods / Scan Barcode / Manual Entry / Recent Foods, CNF/Open Food Facts clients, barcode unknown-code fallback, manual foods, only verified serving conversions, favorites/recents, recipes, Add/Replace copy, date-specific targets and snapshots, calories/macros/adherence, trends, hydration logging/history and Recently Deleted recovery. Food Home includes trend metric selection, hydration actions, meal shortcuts and adherence/Easy Next widgets with deep links.

The provider adapters use public services and require no credentials. CI has not verified live provider availability, completeness, licensing, camera scanning on physical hardware or all offline/network transitions. Simulator UI covers the safe manual barcode fallback.

## Candidate currently being prepared

The unpublished local candidate includes:

- Valid UUID in the legacy WaterLog fixture; custom hydration entry with range validation and historical-date persistence.
- Nutrition-on-target streak across more than seven days and when the current day has no log.
- Saved recipes in search/favorites and tests preserving nutrient snapshots after recipe edits.
- Food sheets attached to the screen container, grouped macro accessibility and an explicit date identity.
- Exterior-frame accessibility anchors for Food Home grid measurements.
- UI flow for opening both same-day sessions from Workout Calendar and asserting visible PR recalculation after editing history.

This candidate has not been published or executed. `git diff --check` passes. This workspace is Linux and has no Xcode, Swift compiler or simulator, so local builds/screenshots are unavailable. The next action is to publish this exact candidate on the existing development branch, inspect its Actions logs, fix failures, then publish/test again. Never approve screenshots automatically.

## Guardrails

The approved 2×4 Home grid and widget geometry, five-icon dock, all existing themes, HealthKit-off state and isolated synthetic test data are preserved. The user accepts Default styling as provisional, not final. No screenshot baseline was overwritten. No production configuration or `main` branch was changed.
