# Training System Phase 2 status

**Branch:** `codex/default-theme-gate1`  
**Status:** Implementation in progress; simulator verification pending CI.  
**Scope:** Training only. No merge, production configuration, HealthKit access, or approved theme changes.

| Requirement | Current source status | Verification |
|---|---|---|
| Multiple programs and one active selection | Implemented with migration from legacy rotation | Unit tests added; CI pending |
| Independent flexible rotations, including >8 sessions | Implemented | Unit tests cover 10 entries, switching, scheduled, skipped and out-of-order paths; CI pending |
| Draft keeps original program; discard does not advance | Implemented | Unit tests added; CI pending |
| Template exercise ordering, custom exercises, tracking modes, set/reps/rest, superset grouping | Implemented in editor/store | Source review only; UI interaction coverage pending |
| Active workout 5-column table and top blue timer | Existing implementation retained; tracking-aware entry, expansion, replacement, progression acceptance and session notes added | UI screenshot added; detailed interaction/recovery on simulator pending |
| Duration, completed/planned sets, volume, finish/save/discard and summary | Implemented in session model/UI | Unit/UI verification pending CI |
| Calendar, multiple same-day sessions, historical corrections | Implemented in Training History | Source review and store tests added; simulator navigation pending |
| Estimated 1RM, baseline, one PR/exercise/workout and recalculation | Derived from completed weighted/reps sets | Unit tests added for baseline/edit/delete/restore; CI pending |
| Recently Deleted, restore and 30-day expiry | Implemented with soft delete and purge | Unit tests added; CI pending |
| Repository reopen recovery | Timer/session payload persisted in existing JSON repository | Unit test added; OS-level force-quit/relaunch not tested |
| iPhone SE | Run #27 Daily geometry assertions passed; phase 2 source not yet run | Pending new workflow |
| iPhone 18 Pro | Not available in prior Actions runner | Untested |
| Default theme visuals | Existing review candidate; no visual approval implied | Awaiting human review |

## Tests added

- `testProgramsKeepIndependentFlexibleRotationsAndOutOfOrderCompletion`
- `testScheduledIncompleteWorkoutAdvancesButDiscardDoesNot`
- `testSwitchingProgramDuringDraftFinishesAgainstOriginProgram`
- `testLegacySingleRotationMigratesWithoutResettingItsUpcomingWorkout`
- `testEstimatedOneRepMaxUsesFirstWorkoutAsBaselineAndOnlyOneRecordPerExerciseWorkout`
- `testHistoricalEditsDeletionAndRestoreRecalculatePersonalRecords`
- `testRecentlyDeletedWorkoutExpiresAfterThirtyDays`
- `testExerciseTrackingModesUseTheirOwnMeasurementsWithoutFalsePRs`
- `testRestTimerPauseExtensionResumeAndSkipUseAbsoluteTime`
- `testSupersetRestBeginsOnlyAfterEveryExerciseCompletesTheRound`
- `testRestTimerUsesExerciseOverrideAndSurvivesRepositoryReopen`
- Existing Daily UI test now also asserts Start Workout opens the active session and captures `Training-Active-Workout-Default-Candidate`.

## Limitations

This workspace cannot run Xcode or the iOS Simulator. Do not mark this milestone verified until the new GitHub Actions run completes. The existing workflow emphasizes Daily Home and currently does not automate all workout editor, history-calendar, or active-session interactions. The screenshot artifact is a review candidate, not an approved baseline.
