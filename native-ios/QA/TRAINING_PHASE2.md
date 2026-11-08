# Training system UI milestone status

**Branch:** `codex/default-theme-gate1`
**App source commit under test:** `f4b2cca17b3ba6bab2207783438f2296ffe93083`
**UI-test-only follow-up:** `dfd8678efdc354d47aac0e549850a46bae533cdd`
**Latest fully green evidence:** [run #80](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42430593049), tested commit `dfd8678efdc354d47aac0e549850a46bae533cdd`.

## Implemented workflows and verified scope

- **Workout editor:** The end-to-end UI test creates a workout, enters edit mode, drags a workout, searches the built-in exercise library, selects an exercise, creates a custom exercise, and changes sets, reps and exercise-specific rest. Run #80 passed the full workflow on both iPhone SE and iPhone 16.
- **Active workout and rest timer:** UI test verifies current exercise expansion, the five-column set table, weight entry, completion of a set, +15-second extension, pause/resume, termination/relaunch recovery and Resume Workout navigation. The blue timer is tested and captured above the scrollable exercise list. Passed on both available devices in run #80.
- **Progression:** A real saved prior workout produces a suggestion on the next session; the test proves it is not applied before explicit acceptance and is applied afterward. Passed on both devices in #80. Declining a suggestion is not yet UI-tested.
- **Completion/history:** The UI test saves a partially completed session, captures the summary, edits historical weight/reps/completion/notes, deletes the workout and restores it from Recently Deleted. Passed on both devices in #80. PR-display/recalculation and multi-session calendar navigation are not covered end to end.
- **Training Home:** The UI test exercises the split/calendar and date/session navigation. A real one-workout fixture leaves seven positions empty; an eight-workout screenshot candidate fills the full fixed 2×4 layout.

## Exact run #80 outcomes

Each device executed **34 unit tests + 7 UI tests** on iOS 18.5.

- **iPhone SE (3rd generation):** 41 passed, 0 failed, 0 skipped.
- **iPhone 16:** 41 passed, 0 failed, 0 skipped.
- **iPhone 18 Pro:** QA test action skipped because the simulator was unavailable; **untested**.

The iPhone 16 drag assertion had failed in #79. Commit `dfd8678` adjusts the XCTest drop point to the destination-row center and holds briefly. Run #80 passed the actual reorder UI test on both available simulators.

## Remaining Training acceptance

- Explicit UI flows for creating/switching programs, program-specific rotations, scheduled skip and rest days.
- UI interaction for tracking-mode changes and superset grouping/round completion.
- Declined progression path; all prescription modes and validation.
- Multi-session dates and individual session navigation in History; complete PR presentation/recalculation after historical edits/deletes.
- Visual review of workout editor, active workout, completion summary and History.

## Visual and device limits

The Home grid and five-icon dock remain unchanged. The single-workout split’s open cells are intentional per master spec §2.3; adding filler would contradict the specification. The full eight-item screenshot is included for comparison. The Active Workout and summary sheets have grouped iOS surfaces and a large unused upper area in the completion presentation; the supplied original references do not define those screens closely enough to approve a redesign.

A gallery of 24 real run #80 PNG captures is at `/workspace/logbook-training-review-run80/index.html` and `/workspace/logbook-training-review-run80.zip`. Images are review candidates only. Reference binary filenames and target subfolders are listed in `docs/handoff-v2/themes/REFERENCE_INDEX.md`; the 26 supplied images are not yet mirrored into the GitHub repository.

This Linux workspace cannot run Xcode locally. HealthKit remains disabled. No production configuration or `main` branch was changed.
