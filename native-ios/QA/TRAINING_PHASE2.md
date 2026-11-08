# Training system UI milestone status

**Development branch:** `codex/default-theme-gate1`
**Latest tested commit:** `10fd85f930b437f8189c048b7e3d2e598b547e8a`
**Evidence:** [Actions run #85](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42449791762)

## Run #85

Build succeeded on iPhone SE (3rd generation) and iPhone 16. Each executed 42 unit tests with 40 passing and 2 failing. iPhone 16 executed 11 UI tests with 8 passing and 3 failing; iPhone SE executed 11 UI tests with 7 passing and 4 failing. The iPhone 18 Pro test step was skipped and remains **untested**. Failures are described in `REPORT.md`.

The unit failures were inaccurate test setup/expectations: missing required legacy recipe identifier and an undercount of three matching destination entries soft-deleted by Replace. The UI decline check matched an ambiguous TextField and the restore assertion checked a differently sorted History row; both are corrected locally using stable identifiers. Neither correction has yet been run in CI.

## Evidence for implemented Training paths

- **Program and rotation:** UI path switches between independently rotating programs and confirms scheduled skip advances only the selected program without creating history. Passed in run #85 on both available simulators.
- **Workout Split editor:** UI path creates and reorders templates, searches/selects a catalog exercise, creates a custom exercise, and configures prescription/tracking; passed in #85 on SE and iPhone 16.
- **Superset and tracking:** UI path creates a superset and checks rest starts after the round; exercise mode selection and its store behavior were exercised. Passed in #85 on available devices.
- **Timer and live session:** existing UI and store coverage exercises the blue pinned timer, default/override durations, +15, pause/resume, skip/Ready behavior and persisted recovery. Earlier green evidence is run #80; current changes are covered by #85 where cases executed.
- **Progression:** acceptance path and completion summary/PR presentation ran in #85; the new decline check failed due to an ambiguous element, and the corrected stable-set check is pending CI.
- **History:** store tests cover multiple same-day sessions, edits, soft delete/recovery, first-session baseline and PR recalculation. The UI path reached deletion/recovery but SE’s final assertion used the wrong history row; exact restored-ID check is pending CI. Calendar drill-in for multiple same-date sessions and UI-visible PR recalculation after historical edit/deletion remain incomplete.

## Current scope gaps

Training implementation is broad but not yet fully accepted. Remaining direct checks include a rest-day UI path; preserving a draft's originating program when switching programs; calendar navigation among multiple sessions on one date; visible PR updates after historical corrections/deletions; and all currently pending corrected UI assertions. Run #85 aggregate failures mean no blanket Training completion claim is appropriate.

The approved Home grid remains 2×4 with exact widget sizes; programs with fewer than eight workouts leave unused cells empty. Visual styling is provisionally accepted only; no final visual approval or baseline protection action has been taken. Home geometry, dock and 16 theme designs were not changed. The iPhone 18 Pro is untested. HealthKit is disabled.
