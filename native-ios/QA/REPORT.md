# Logbook QA report

This report is updated by `Scripts/run-daily-home-qa.sh` after a simulator test. The last known completed run is #27. The next run is required to validate the current Training Phase 2 source.

- Workflow: [Daily Home QA run #27](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42382271551)
- Tested source commit: `45f42d4a505f58b4d900431e1ae5fc85f43edb6b`
- iPhone 16: build succeeded; 14 tests passed, 2 failed, 0 skipped. Daily grid/layout assertions passed. Failures were a strict persisted-Date equality in rest-timer recovery and the Home Start Workout action not presenting the active workout.
- iPhone SE (3rd generation): build succeeded; 14 tests passed, 2 failed, 0 skipped. Daily grid/layout assertions passed, so run #27 did not show an SE geometry failure. Same two failures as iPhone 16.
- iPhone 18 Pro: simulator unavailable on its runner; QA tests were skipped. **Untested**, not passed.
- Artifacts: iPhone 16 ID `13578721172`; iPhone SE ID `13577954498`; unavailable-device report ID `13577769726`. Run #27 artifacts contain real simulator screenshots and Xcode results.
- Baselines: unchanged; no candidate has been approved.

The current source includes fixes for the two run #27 failures and Training Phase 2 changes. Those changes are not verified until a new Actions run finishes. The active-workout screenshot capture was added to that test, but there is no result artifact for it yet. See `TRAINING_PHASE2.md` for the detailed status.
