# Logbook QA report

## Latest test run

**Branch:** `codex/default-theme-gate1`
**Tested source:** `f6c2bb3b58972616e7b10c302212c1ac30d19d44`
**Actions run:** [#89](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42455968938)

| Simulator | Build | Unit tests | UI tests | Result |
|---|---|---:|---:|---|
| iPhone SE (3rd generation) | Passed | 44/45 passed | 8/13 passed | Failed |
| iPhone 16 | Passed | 44/45 passed | 8/13 passed | Failed |
| iPhone 18 Pro | Availability check only | Not run | Not run | Untested; test step skipped |

The shared unit failure is legacy `WaterLog` decoding without `createdAt`. The follow-up adds a backward-compatible timestamp default. UI failures are: Food Home frame probes returning zero-sized AX frames; selected Food date not changing in the tested control path; macro-swipe element ambiguity; a Food hydration/recipe-navigation control not being visible after scrolling; and duplicate Workout Calendar button matching/history navigation. Follow-up changes address these failures but have not run yet. Exact device failure logs are in the linked Actions run.

Run #89 screenshots and reports are actual, unapproved artifacts:

- [iPhone 16 captures](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42455968938/artifacts/13608365639)
- [iPhone SE captures](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42455968938/artifacts/13607604595)
- [iPhone 18 Pro availability note](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42455968938/artifacts/13607691705)

## Training verification

On both SE and iPhone 16, the UI suite passed the program switching/rotation/skip/out-of-order path, progression acceptance and decline, Workout Split drag/search/custom-exercise path, Next Workout start, Daily small-widget interactions and water history recovery. The unit suites passed 44 of 45 tests; the passing cases cover independent rotations, scheduled/out-of-order completion, superset timing, tracking modes, progression logic, same-day sessions, persistent drafts, historical edits/deletion/recovery and PR calculation. The failed unit case is data-compatibility decoding for legacy water logs. The History UI test did not finish its full edit/recovery path because its calendar navigation selector was ambiguous. Rest-day non-advance and app termination recovery remain without direct UI evidence. Training is not closed.

## Food / Nutrition verification

The app source includes persistent meal entry/editing, the four required Add Food choices, CNF/Open Food Facts adapters, barcode fallback, manual foods, verified serving conversions, recents/favorites, recipes, Add/Replace copying, date-specific nutrition goals and snapshots, remaining totals, seven-day metrics/adherence, custom and preset hydration, history editing and recovery. Store tests for these functions passed in #89 except the unrelated WaterLog legacy decoder fixture. Food UI tests did not pass end to end: date navigation, Food widget frame measurement, macro swipe selection, hydration controls and recipe search flow need another run after the fixes.

Public CNF and Open Food Facts endpoints need no credentials. Live network availability, provider completeness and licensing/attribution review, offline transitions, and physical-camera barcode scanning remain unverified. The simulator cannot prove physical camera behavior.

## Candidate follow-up and guardrails

The current unpublished candidate fixes legacy decoding with a timestamp default, gives the Food summary a stable identity, normalizes date shifting, frames the Home widget AX probe, uses a stable Workout Calendar identifier, makes History back navigation explicit, and adjusts Food UI navigation/scroll behavior. It has not been built or tested. The Linux workspace has no Xcode, Swift compiler or Simulator. `git diff --check` passes.

The last fully green source baseline remains run #80, commit `dfd8678efdc354d47aac0e549850a46bae533cdd` (34 unit + 7 UI = 41/41 on SE and iPhone 16); it does not verify later source. No screenshot is approved or replaces a baseline.

The four Home pages, exact 2×4 grid and 1×1/2×1/2×2 geometry, five-icon dock, all themes, HealthKit-off setting and isolated synthetic data are preserved. No production configuration or `main` branch was modified.
