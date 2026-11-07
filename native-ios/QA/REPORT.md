# Logbook QA report

This report is updated by `Scripts/run-daily-home-qa.sh` after a simulator test. The latest completed run is #28.

- Workflow: [Daily Home QA run #28](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42385984214)
- Tested source commit: `14cda399d8c2fda1a6f90b5604a2da8e87abd9d3`
- iPhone 16 and iPhone SE (3rd generation): Xcode build failed before tests because of an invalid `Calendar.isDate` argument label in `CheckInHistorySettingsScreens.swift:198`; the compiler also reported a type-check timeout for the containing History view after the syntax error. **0 tests executed; no screenshot candidates were produced.**
- The local fix changes the label to `toGranularity:`; it is not verified until a follow-up Actions run succeeds.
- iPhone 18 Pro: simulator unavailable on its runner; QA tests were skipped. **Untested**, not passed.
- Artifacts: iPhone 16 ID `13579413097`; iPhone 18 Pro unavailable-device report ID `13579741521`. The iPhone 16 artifact contains the failed Xcode log; no SE screenshot artifact was produced before this report update.
- Baselines: unchanged; no candidate has been approved.

Run #27 separately passed Daily geometry assertions on iPhone 16 and SE but had two test failures on both devices. Its fixes were included in #28, but #28 did not reach test execution. The active-workout screenshot capture is included in the source, but no new screenshot exists yet. See `TRAINING_PHASE2.md` for the detailed status.
