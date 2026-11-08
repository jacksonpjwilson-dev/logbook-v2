# Training system verification status

**Development branch:** `codex/default-theme-gate1`
**Latest tested source:** `f28e71c9fcfa4ddf3289e5467d3e591737eedb35`
**Evidence:** [Actions run #88](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42454022156)

## Latest executed results

Both SE and iPhone 16 builds succeeded. The iPhone SE ran 43 unit tests (42 passed, 1 failed) and 13 UI tests (6 passed, 7 failed). The iPhone 16 ran 43 unit tests (42 passed, 1 failed) and 13 UI tests (8 passed, 5 failed). The common unit failure is the invalid `legacy-water` UUID test fixture. The iPhone 18 Pro test step was skipped; it remains untested. The full details are in `REPORT.md`.

The aggregate failure does not erase successful individual tests, but it means the Training milestone is not closed. The store tests exercised the program rotations, skip/out-of-order/discard rules, timer and superset behavior, exercise tracking, progression rule, historical records and PR calculation. The UI suite exercised the split editor and portions of program switching, training, summary and history. Direct UI paths added locally for calendar navigation and visible PR recalculation have not yet executed.

## Evidence and remaining UI work

- **Programs/schedule:** Business-logic tests cover independent flexible rotations, scheduled skip, out-of-order completion, discard and workouts retaining their origin program. The program switch/skip UI test passed in earlier run #87; the latest candidate adds a completed out-of-order UI path, but #88 did not establish a green suite. Rest-day UI non-advance still needs a direct test.
- **Split editor/exercises:** UI test drives reorder, catalog search, custom exercise creation, sets/reps/rest settings, tracking mode and superset grouping. Reordering failed once on SE in #88, so repeatability needs confirmation.
- **Active workout/timer:** UI/store tests cover the blue floating timer, default and custom rest duration, pause/resume/+15/skip, superset interval behavior, pinned finish control, saved session and store reopen. App termination/relaunch remains a direct UI evidence gap.
- **Progression:** UI covers explicit acceptance. The decline test is being changed because the numeric TextField's displayed value was unstable across lazy-list updates; the unit test confirms declining records dismissal without writing the suggested weight.
- **History/PR:** Store tests verify same-day sessions, editable workout records, recovery and recalculated PRs. UI exercises editing/deletion/restoration and summary PR presentation. The local candidate adds navigation to both same-day sessions from the calendar and asserts visible PR recalculation after historical edit. PR after deletion/restoration remains a direct UI gap.

## Current follow-up candidate

Not yet published/tested. It adds calendar session identifiers and UI navigation, a visible PR-row assertion after editing, fixes the legacy UUID fixture, and stabilizes the Food UI failures discovered in #88. The exact approved Home geometry remains unchanged. Empty split cells are correct for rotations with fewer than eight workouts. Visual direction remains provisional; themes and baselines are unchanged.

Run #88 screenshots/reports are available as unapproved artifacts: [iPhone SE](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42454022156/artifacts/13607506214) and [iPhone 16](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42454022156/artifacts/13607580740). No local Xcode/Simulator is available in this Linux workspace. HealthKit remains disabled; production configuration and `main` remain untouched.
