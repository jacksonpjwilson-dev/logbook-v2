# Current Logbook milestone

**Objective:** Complete end-to-end Training editor, active-workout, progression, completion and history UI verification, then review Default visuals. This is not a beta-complete milestone.

**Development branch:** `codex/default-theme-gate1`  
**Latest app/test source commit:** `5fa556da6da8775d26bffeb5c56cf899f6fd035b` (UI-test corrections; simulator result pending run #71). Later commits update evidence documents only and do not change app/test source.  
**Last fully green app-source baseline:** `85783dac2f65767e4d762064df46b9d81cda8c35`, run [#42](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42396256800).  
**Latest completed attempt:** run [#66](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42418581935), source `7492512db7cb1085c90ccee193d376289561f781), failed UI tests.  
**Newer attempts:** #67 and #68 in progress; #69–#71 queued when this note was written. The current source fixes are not yet simulator-verified.

## Evidence status

Run #42 remains the last complete green baseline: on iPhone 16 and iPhone SE (3rd generation), iOS 18.5, each ran 33 unit + 4 UI tests (37 passed, 0 failed, 0 skipped). Run #42 does not verify the newer Training editor, set-entry, progression, completion or history UI workflows. Its iPhone 18 Pro step was skipped; that device remains **untested**.

Run #66 compiled and passed all 34 unit tests on each available device. Its UI suite had 7 tests:
- iPhone 16: 4 passed, 3 failed (rest timer Pause/Resume state, historical completion assertion, split reorder assertion).
- iPhone SE: 3 passed, 4 failed (weight entry controls not exposed in the then-current collapsed-state UI, plus planned-exercise control discovery).
- iPhone 18 Pro: skipped; **untested**.

Run #65 separately passed the progression-acceptance workflow and split editor reorder/search/custom-exercise workflow on iPhone 16, while its full UI suite still failed 2 of 7 tests. A green isolated workflow does not make the full milestone green.

Commits #8e20443, #33e5356 and #5fa556d address the observed collapsed initial exercise, timer control/test state, history label assertion, and unstable drag/stepper selectors. They are **implemented, awaiting run #69–#71 evidence**. Do not mark them verified until the simulator jobs complete.

## Current implementation boundary

The source has persistent program/template editing, exercise search and custom creation, tracking modes and prescriptions, superset controls, active workout logging and rest timer, explicit progression acceptance, completion summary, historical set editing and Recently Deleted recovery. Store/business-logic coverage is broad, but the complete UI workflows are not yet verified across both available simulators.

The approved Home geometry is unchanged. An eight-workout synthetic Training split fills the numbered 2-column × 4-row widget. With one actual workout, the other positions remain blank as required by §2.3 of the master specification; do not fabricate workouts to fill the card. The Default style remains pending visual review and no screenshot baseline is approved.

## Visual references and artifacts

Actual screenshots from earlier simulator runs are review candidates only:
- [iPhone 16 run #65 artifact](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42418302117/artifacts/13593435114)
- [iPhone SE run #65 artifact](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42418302117/artifacts/13592459439)
- Earlier local gallery: `/workspace/logbook-training-review/index.html` and PNGs under `/workspace/logbook-training-review/screenshots/` (run #58 candidates, predating the expanded-exercise fix).

The 26 original binary reference files are still not mirrored in GitHub. Their exact names and destination folders are listed in [REFERENCE_INDEX.md](handoff-v2/themes/REFERENCE_INDEX.md); copy unchanged to `docs/handoff-v2/themes/references/{defaults,featured,glass,overview}/`. The local handoff workspace contains them. Four glass references are thumbnail-only and remain resolution-limited.

## Next work

1. Let runs #67–#71 finish; inspect both iPhone 16 and SE job logs, not only the aggregate run badge.
2. Fix any remaining app or test failures; capture active workout set entry, split editor, completion summary and history on current source.
3. Preserve the fixed Home geometry and intentional unused split cells; review actual screenshot layout and default appearance without changing themes.
4. Update the tracker and audit from exact completed evidence. Keep visual approval separate from test success.

HealthKit remains disabled. No production configuration or `main` branch changes were made. The local execution workspace has no Xcode or iOS Simulator.
