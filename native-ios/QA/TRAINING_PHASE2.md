# Training System Phase 2 status

**Branch:** `codex/default-theme-gate1`  
**Scope:** Training verification and defect correction on the development branch. HealthKit remains disabled; no production configuration or `main` changes.  
**Latest completed run before this patch:** [Daily Home QA #36](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42389571701), commit `27a144f56fdd746e66653cbf7f9634f0fb5dfa91`.

## Current source coverage

| Area | Source state | Verification state |
|---|---|---|
| Named programs, one active selection, flexible independent rotations | Implemented; migration from legacy rotation, reorder/move/delete, skip, scheduled and out-of-order completion rules | Existing store scenarios cover >8 templates, independent rotations, skip, out-of-order completion, scheduled completion, migration and draft program switching. Added cases cover reorder/move/delete behavior. CI pending for additions. |
| Workout templates and exercise configuration | Implemented: search/custom exercises, ordering, sets/reps/rest, tracking modes and superset groups | Store tests cover superset grouping/round rest and session-only replacement. Editor UI interactions are not yet automated end to end. |
| Active workout | Implemented: five-column set entry, current/remaining exercise expansion, replacement guard, progression acceptance, notes, pause/resume, finish/discard, summary, timer and persistent draft | Unit tests cover timer controls, overrides, superset timing and repository reopen. UI test verifies launch, Ready state, duration control, five-column header and captures a review candidate. Detailed field editing, app termination, and progression acceptance are not yet UI tested. |
| Completion and rotation | Implemented: normal/confirmed partial completion advances only the originating scheduled slot; out-of-order completion and discard do not advance; skip advances without a record | Existing unit scenarios exercise scheduled, partial, out-of-order, program switch and discard. |
| History, notes and multiple same-day sessions | Implemented in Training History with per-session navigation, editable sets and notes, calendar aggregation | Added persistence scenario verifies two same-date sessions remain distinct and edited sets/notes survive repository reopen. Calendar UI navigation still needs UI automation. |
| Estimated 1RM and PR events | Derived from completed weighted-and-reps sets; first performance establishes baseline; one event per exercise/session; edits/deletes/restores recalculate | Existing store tests cover baseline, one-per-session and recalculation. |
| Recently Deleted | Soft delete, 30-day restore window and expiry purge | Existing unit test covers expiry; added timestamp validation prevents restoring before deletion time. |
| Home geometry and Default appearance | The approved 2-column × 4-row geometry is unchanged; Default screenshots remain review candidates | iPhone SE and iPhone 16 geometry assertions passed in run #36. Appearance is not approved. |

## Latest completed simulator results

Run #36 built successfully on the macOS 15 iPhone 16 and iPhone SE (3rd generation) simulators. Each ran 25 unit tests successfully. Two of three UI tests passed; the active-workout UI test failed in its test-only keyboard sequence while typing into a set field, before the attempted timer controls. The failure did not indicate an app crash or layout assertion failure. The next patch removes that brittle keyboard sequence while retaining active-session, Ready timer, duration control, five-column header and screenshot checks; deterministic store tests continue to cover timer state changes.

- iPhone 16: **25 unit passed; 2 UI passed, 1 UI failed**. [Run #36](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42389571701). Screenshot artifact: [iPhone 16](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42389571701/artifacts/13580744439).
- iPhone SE (3rd generation): **25 unit passed; 2 UI passed, 1 UI failed**. Daily grid passed with large 212.35 × 212.35 pt; measured medium 211.5 × 101.25 pt (element frame 212.35 × 107.35 pt); small widgets 101.85 × 101.85 pt and 102.35 × 101.85 pt. Their bottom edge was y=570.43 pt, above the dock top at y=606.5 pt. [Screenshot artifact](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42389571701/artifacts/13580739645).
- iPhone 18 Pro: the workflow job skipped the test step because no matching simulator was available. **Untested**, not passed.
- [Run #26](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42376326674) failed during the Xcode build on iPhone 16 and SE, before any tests executed. Its artifacts contain build/report output only; iPhone 18 Pro was unavailable.

## Added/updated verification in the pending commit

- Program reordering preserves the current scheduled template, then continues in the new order.
- Moving and deleting templates before the scheduled item preserve the scheduled item.
- Session-only replacement is rejected after exercise work begins and does not mutate the saved template.
- Superset merging keeps all exercises in the merged group; rest starts after the last exercise in a round.
- An unfinished workout recovers from repository storage with its original program, set data and notes after switching programs.
- Multiple completed workouts on the same day remain separate after reopening; historical set and notes edits persist.
- Recently Deleted rejects future-dated restoration; date persistence retains subsecond precision for timer recovery and continues decoding legacy whole-second timestamps.
- The active-workout UI test no longer types into a scrollable numeric field before tapping the timer.

The new tests are not passing until the next GitHub Actions run completes. This workspace has no Xcode or iOS Simulator, so it cannot execute them locally.

## Remaining unverified work

- End-to-end UI coverage for template drag/drop, custom exercise search/creation, progression acceptance, historical edit/calendar and Recently Deleted navigation.
- OS-level terminate/relaunch recovery (repository reopen is covered by unit tests, but the OS lifecycle is not simulated).
- Physical-device, Watch, Live Activity, and iPhone 18 Pro validation.
- Detailed Default visual acceptance; screenshots are candidates only and no baseline is overwritten.
- Source-reviewed training duration/volume statistics and completion-summary presentation still need simulator visual inspection.

The existing 16 approved non-Default themes have not been redesigned. No screenshot has been automatically approved.
