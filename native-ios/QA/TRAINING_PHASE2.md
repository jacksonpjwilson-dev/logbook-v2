# Training verification status

**Branch:** `codex/default-theme-gate1`
**Tested source:** `54c236485bcd16ffa685ce5cea02d9e27a0220f2`
**Evidence:** [Actions run #90](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42457771622)

## Results

On iPhone SE and iPhone 16 the build passed, and each device ran 45 unit tests (44 passed, 1 failed) and 13 UI tests (8 passed, 5 failed). The only unit failure was the legacy nutrition payload fixture missing `FoodRecipe.updatedAt`, unrelated to Training. The iPhone 18 Pro test step was skipped by the workflow availability check and remains untested.

Unit/store behavior passed for independent flexible rotations, program switching, scheduled skips, out-of-order completions, discard, program association for drafts, timer/superset behavior, tracking modes, progression decisions, multiple sessions per day, edits/recovery, and PR calculations. The UI suite passed program switching and rotation, split reorder/search/custom exercise, progression accept/decline, Next Workout start, check-in interactions, and hydration history recovery.

The calendar history UI path failed when returning from a selected workout detail to the calendar. Commit `22c6ef4d71af3c0b2d2e2045d7520fb083af7334` now gives the calendar a dedicated navigation path; Actions #91 is testing it. Rest-day non-advance, app termination/relaunch recovery, and UI-level PR recalculation after deletion/restoration still need direct evidence. Training is not closed.

Run #90 artifacts are actual captures and test results, not approved baselines: [iPhone SE](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42457771622/artifacts/13608512203), [iPhone 16](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42457771622/artifacts/13609390347), and [18 Pro availability](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42457771622/artifacts/13607842943). Keep the exact two-column by four-row grid and empty cells for short splits. This Linux workspace cannot run Xcode or Simulator.
