# Current Logbook milestone — Training verification and Food/Nutrition

**Development branch:** `codex/default-theme-gate1`  
**Current branch / tested commit:** `074ab167f4ea6826f6d9a7c5536257ea2c1bd395`  
**Latest completed CI:** [Actions #126](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42496892834) — successful on iPhone SE (3rd generation) and iPhone 16.  
**Prior fully green app source baseline:** run #80, `dfd8678efdc354d47aac0e549850a46bae533cdd`; superseded by #126 on the two available simulators.  
**iPhone 18 Pro:** availability check only; app test skipped, untested.

| Simulator | Build | Unit tests | UI tests | Result |
|---|---|---:|---:|---|
| iPhone SE (3rd generation) | Passed | 50/50 | 13/13 | Passed |
| iPhone 16 | Passed | 50/50 | 13/13 | Passed |
| iPhone 18 Pro | Availability check passed | Not run | Not run | Untested; app-test step skipped |

## Training

All 13 Training tracker rows now have completed automated evidence from #126. Unit and UI coverage exercises independent flexible program rotations, scheduled completion/skip, out-of-order sessions, program switching with saved workout ownership, split reorder/search/custom exercises, superset grouping/rest behavior, exercise tracking modes, progression accept/decline, active workout table and pinned timer, pause/resume and process-termination recovery, completion summary, multiple sessions/history, edits/deletion/recovery, and PR presentation/recalculation.

## Food and Nutrition

Persistent Food workflows are implemented and passed the available simulator tests: the exact four Add Food entry choices, search and serving confirmation, manual entry/correction, unknown barcode manual fallback, cached foods after repository reopen, recents/favorites/recipes, meal/day copy with Add/Replace, nutrition goals and remaining calculations, hydration history, Food History correction and Recently Deleted recovery. The full suite caught a swipe-gesture conflict on iPhone 16; the date-swipe gesture now applies only to the nutrition summary, and the Food History route passed on both devices in #126.

The compact Food date picker is implemented but still lacks a dedicated UI assertion. Live CNF/Open Food Facts availability, provider terms/completeness and device network-loss behavior have not been verified. No API credentials are required. Physical camera scanning/permission behavior remains unverified; barcode entry and unknown-code fallback passed.

## Screenshots and visual status

Run #126 artifacts contain actual Simulator screenshot attachments for all four Home pages, active workout/set entry and timer recovery, split editor, progression states, completion summary/history, and Food Home, Food History/edit/recovery, barcode fallback, targets/recipes/hydration and copy flows:

- [iPhone SE screenshots and test report](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42496892834/artifacts/13624920583)
- [iPhone 16 screenshots and test report](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42496892834/artifacts/13624832311)
- [iPhone 18 Pro availability report only](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42496892834/artifacts/13624205975)

All captures are candidates, not approved baselines. The Default appearance remains provisional, pending your visual approval. No visual baselines or theme designs were changed.

## Boundaries and remaining work

The approved 2×4 Home grid, widget geometry, four Home pages, fixed five-icon dock, and all 16 approved themes were preserved. HealthKit remains disabled. Tests used isolated synthetic data. No production configuration, personal data or `main` branch was changed.

Next: add a focused Food date-picker accessibility/UI check; perform live provider and physical-camera validation; then continue the next remaining domain milestone (Sleep, Weight, Supplements, Habits and broader History). Authentication/coaching and Apple-device integrations remain outside this Food verification run.