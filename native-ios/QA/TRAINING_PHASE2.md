# Training System Phase 2 status

**Branch:** `codex/default-theme-gate1`  
**Tested implementation commit:** `85783dac2f65767e4d762064df46b9d81cda8c35`  
**Latest CI:** [Daily Home QA run #42](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42396256800)  
**Scope:** Training workflows and Default Training Home content. No HealthKit access, production configuration change, theme redesign, or merge to `main`.

## Implementation and verification

| Area | Implemented behavior | Evidence and remaining coverage |
|---|---|---|
| Programs and rotation | Named workout programs, one active selection, independent flexible-length rotations, legacy migration, scheduled skip without history, out-of-order completion, discard, and draft association with its original program. Reordering/moving/deleting earlier split items preserves the scheduled item. | Unit tests passed for independent rotations, >8 templates, migration, scheduled/incomplete/discard behavior, program switching during an active draft, and split reordering. The program/editor UI is not fully automated end to end. |
| Split editor and exercise library | Searchable exercise catalog, custom exercises, template/exercise reordering, tracking modes, sets/reps/rest, and superset grouping. Session-only replacement is allowed before work starts. | Store tests passed for tracking modes, superset ordering/rest, replacement rules and split reordering. Drag/drop, search, and edit controls still need full UI workflow coverage. |
| Active workout | Current exercise progression, superset rounds, five-column set table, Previous values, exercise/session notes, pinned summary and Finish & Save, discard, completion summary, optional progression acceptance, default/overridden rest, pause/resume/+15/skip/Ready. Draft and absolute rest-timer state persist. | Store tests cover logging/finishing/reopening a workout, progression, timer controls/overrides, supersets, notes/state persistence, and replacement. XCUITest starts a scheduled workout, exercises the timer, terminates the app, relaunches it, resumes the saved session and confirms the timer is still active. The full set-entry-to-summary interaction still lacks an XCUITest. |
| History and records | Multiple sessions per date, calendar month/date navigation, editable set history, notes, Recently Deleted recovery/expiry, training aggregates, weighted-and-reps Epley estimates, first performance as baseline, one PR per exercise per workout, and recalculation after edits/deletes/restores. | Store tests passed for same-day records/reopen, historical edits/deletion/restore, e1RM baseline/PR rules and 30-day expiry. Full UI tests for calendar session detail, historical editing and Recently Deleted remain. |
| Default Training Home | Workout Split tiles and real monthly Workout Calendar are interactive. Existing 2-column × 4-row Home grid, 1×1 / 2×1 / 2×2 widget geometry, dock and non-scrolling Home remain unchanged. | Simulator UI tests passed for split tile details, calendar month/date navigation and workout-detail navigation. Captures are review candidates, not approved baselines. |

## CI results

Run #42 built and tested commit `85783da` on macOS 15.8.2 / iOS Simulator 18.5:

- **iPhone SE (3rd generation):** 33 unit + 4 UI tests; **37 passed, 0 failed, 0 skipped**. [Download screenshots and test report](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42396256800/artifacts/13583373258)
- **iPhone 16:** 33 unit + 4 UI tests; **37 passed, 0 failed, 0 skipped**. [Download screenshots and test report](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42396256800/artifacts/13584290732)
- **iPhone 18 Pro:** **untested**. Its test step was skipped because that simulator is unavailable on the macOS 26 runner. [Availability report](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42396256800/artifacts/13583483232)

The UI suite includes the Daily four-page captures, Daily widget interaction, Training split/calendar navigation, and active-workout start plus timer persistence after app termination and relaunch.

Run #41 initially failed 36/37 on both available devices. Its video showed the blue rest card stuck at “Ready” while the pinned footer timer ran. Commit `85783da` makes the timeline read the latest persisted timer value. Run #42 then passed on both devices, including the relaunch test. The running +15-second behavior is also asserted in the timer unit test.

Run #26 failed compilation on iPhone 16 and SE before tests; 0 tests ran. Later fixes were verified by runs #39 and #42. There is no outstanding iPhone SE build/layout failure. iPhone 18 Pro remains untested.

## Layout measurements

The approved widget geometry was not changed in this phase. Measured on the existing screenshot/UI geometry checks:

- **iPhone SE (3rd generation):** large 212.35 × 212.35 pt; medium outer 212.35 × 107.35 pt (interior 211.5 × 101.25 pt); small cells 101.85 × 101.85 and 102.35 × 101.85 pt. Bottom widgets ended at y=570.43 pt; dock began at y=606.5 pt, leaving about 36 pt clearance.
- **iPhone 16:** large 268.52 × 268.52 pt; medium outer 268.52 × 129.85 pt (interior 267.5 × 129.25 pt); small cells about 130.18 × 130.18 pt. Dock clearance was about 36 pt.

These are simulator measurements, not approval of Default-theme appearance. Default reference styling and active-workout visuals remain open for your review.

## Remaining validation

- Add XCUITests for editing a split by drag/drop, entering/completing set data through the UI, completion summary, accepting/declining progression, editing a historical session, and restoring a deleted workout.
- Review the exported Default Home and active-workout PNGs. No baselines were approved or overwritten.
- Test iPhone 18 Pro when its simulator is available, and test a physical iPhone before beta distribution.
- Watch/Live Activity hardware behavior, authentication/coaching, cloud sync and non-Training subsystems are not verified by this milestone.

