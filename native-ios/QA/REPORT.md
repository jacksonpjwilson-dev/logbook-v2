# Logbook QA report

## Latest completed run

**Run:** [Daily Home QA #42](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42396256800)  
**Tested source commit:** `85783dac2f65767e4d762064df46b9d81cda8c35`  
**Result:** Build and tests passed on iPhone 16 and iPhone SE (3rd generation). Each ran 33 unit tests and 4 UI tests: **37 passed, 0 failed, 0 skipped**.

- [iPhone 16 screenshot and test artifact](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42396256800/artifacts/13584290732)
- [iPhone SE screenshot and test artifact](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42396256800/artifacts/13583373258)
- [iPhone 18 Pro availability report](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42396256800/artifacts/13583483232) — simulator unavailable; test step skipped, **untested**.

The active-workout UI test starts a workout, starts the rest timer, terminates and relaunches the app, resumes the saved workout and confirms the timer remains active. Run #41 had exposed a stale “Ready” label in the top timer card; the fix is in commit `85783da` and passed on both available devices in #42.

## What the workflow verifies

The four Home pages and fixed widget geometry, Daily widget navigation, Training Split and calendar navigation, and active-workout timer/session recovery. The artifacts contain actual simulator PNGs and test logs. Screenshots remain candidates for human review; the workflow never approves or overwrites a baseline.

Run #26 failed compilation before tests (0 tests ran). Runs #39 and #42 passed all 37 tests on both available devices. See `TRAINING_PHASE2.md` for detailed implementation coverage, measurements and remaining UI tests.

## Open work

- Full XCUITest workflows for split drag/drop editing, set entry and completion summary, progression acceptance, historical editing and Recently Deleted restoration.
- Human review of Default-theme and active-workout appearance.
- iPhone 18 Pro simulator validation and physical-device checks.
- Food, Sleep, Weight, Supplements, complete History, cloud/authentication and coaching remain outside this Training verification.

No theme or screenshot baseline has been approved or replaced.
