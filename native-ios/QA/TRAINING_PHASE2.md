# Training verification — run #126

**Branch:** `codex/default-theme-gate1`  
**Tested commit:** `074ab167f4ea6826f6d9a7c5536257ea2c1bd395`  
**Run:** [Actions #126](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42496892834)

Build succeeded on iPhone SE (3rd generation) and iPhone 16. Each device passed all 50 unit tests and all 13 UI tests. iPhone 18 Pro's app-test step was skipped; it remains untested.

## Verified Training workflows

- Multiple workout programs with independent flexible rotations; scheduled completion/skip and out-of-order completion.
- Program switching, saved draft ownership, and unfinished workout resume.
- Split reorder, exercise search/custom creation, exercise-specific tracking modes, supersets and round-based rest.
- Active workout five-column set entry, expanded current exercise, pinned blue rest card, ready/running/paused controls and timer recovery after app termination.
- Progression suggestion acceptance and decline.
- Completion summary and qualifying PR presentation.
- Multiple sessions on one date, historical set editing, deletion and Recently Deleted recovery.
- PR baseline eligibility and recalculation after historical corrections/deletions through store tests.

## Food verification in the same run

The same UI suite passed all Food tests on both devices: exact four Add Food paths, search/manual add and correction, date movement, history navigation/recovery, unknown-barcode manual fallback, goals/trends, hydration, favorites/recents/recipes and Add/Replace copying.

## Screenshots

Run #126 exports actual screenshot attachments, not generated images:

- [SE screenshots/test report](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42496892834/artifacts/13624920583)
- [iPhone 16 screenshots/test report](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42496892834/artifacts/13624832311)

Screenshots are candidates and are not approved baselines. The 2×4 Home geometry and theme designs are unchanged. HealthKit stays off, and tests use isolated synthetic data.