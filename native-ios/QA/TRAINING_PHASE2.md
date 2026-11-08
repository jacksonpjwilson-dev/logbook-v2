# Training system UI milestone status

**Development branch:** `codex/default-theme-gate1`
**Latest executed commit:** `f04bfdd2d5184a31c99bc41f165d6348b2a7c8f6`
**Evidence:** [Actions run #87](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42451731246)

## Run #87 results

Builds succeeded on iPhone SE (3rd generation) and iPhone 16. Both ran 43 unit tests: 42 passed, 1 failed (legacy WaterLog decode fixture lacked a required ID). iPhone 16 ran 13 UI tests: 8 passed, 5 failed. iPhone SE ran 13 UI tests: 9 passed, 4 failed. The iPhone 18 Pro test step was skipped and is **untested**. Failure details are in `REPORT.md`.

The candidate fixes the WaterLog fixture and narrows the progression assertion to the exact same set input. New direct tests and code corrections have not been run yet.

## Evidence for implemented Training paths

- **Programs and rotation:** run #87's switching/skip path passed on the available simulators. The candidate adds completing a non-next workout after skipping and checking that the scheduled next workout remains unchanged; that new UI assertion awaits CI.
- **Workout Split editor:** the UI path creates/reorders templates, searches and selects a catalog exercise, adds a custom exercise, and configures prescriptions/tracking. This path passed where executed in #87.
- **Superset and tracking:** UI/store paths exercise alternate modes and ensure the timer starts after the superset round; cases passed where executed in #87.
- **Timer and session persistence:** store tests cover 90-second default and per-exercise override, pause/resume/+15/skip absolute-time behavior, and repository reopen recovery. The blue top-floating card and pinned footer have simulator UI coverage from prior runs; no physical device is attached here.
- **Progression:** explicit acceptance and completion summary/PR presentation paths passed in #87. The decline UI comparison failed because the query could select a different lazy-loaded TextField; the candidate records and reacquires the same stable identifier. Re-run is pending.
- **History/PR:** store tests cover multiple same-day sessions, historical edits/deletes/restores, baseline rules and recalculation. The UI has historical editing/deletion/recovery, but the aggregate #87 run was red. Direct UI navigation between same-date sessions and visible PR recalculation after edit/delete/restore remain incomplete.

## Current scope gaps

Training is **not verified complete**. Run #87 failed on both available simulators. Remaining direct UI evidence includes rest-day non-advance, draft program association on program switch, calendar navigation among multiple same-day records, PR display recalculation after historical correction/deletion, and a saved-session relaunch recovery flow. Fixes to the #87 assertions are in the current candidate, not yet executed.

The exact approved 2×4 grid and widget geometry remain unchanged; short rotations leave empty cells. Visual styling is provisionally acceptable only. No screenshot is a final approved baseline. All current themes remain unchanged, HealthKit disabled, and iPhone 18 Pro untested.
