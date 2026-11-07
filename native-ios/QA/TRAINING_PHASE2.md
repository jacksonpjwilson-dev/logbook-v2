# Training system UI milestone status

**Branch:** `codex/default-theme-gate1`  
**Last fully green source:** `85783dac2f65767e4d762064df46b9d81cda8c35` (run #42)  
**Latest completed attempt:** [run #66](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42418581935), commit `7492512db7cb1085c90ccee193d376289561f781`  
**Current head at update:** `5fa556da6da8775d26bffeb5c56cf899f6fd035b`; simulator result pending run #71.

## Implemented source, with evidence limits

- Programs and rotations: multiple named programs, independent rotation indexes, flexible length, skip/discard/out-of-order rules and draft program association exist in the store. Thirty-four unit tests passed on iPhone 16 and SE in run #66. The UI does not yet have full create/switch/skip end-to-end coverage.
- Split editor: template/exercise reorder via SwiftUI List edit mode, exercise search, custom exercise creation, tracking mode, set/reps/rest steppers and superset controls are implemented. Run #65 passed reorder/search/custom exercise UI on iPhone 16. Run #66 reproduced reorder assertion failure on iPhone 16 and exercise-control discovery failure on SE. The new drag/stepper query corrections in #71 are pending.
- Active workout: five-column weighted table, per-mode inputs, current/remaining exercise cards, blue timer at the top, bottom-pinned statistics, notes and finish/discard/summary flows exist. The current exercise was not expanded when the draft had no explicit focus ID; commit #8e20443 now selects the focused or first exercise on appearance and session change. It has not yet been simulator-verified.
- Timer: store tests cover 90-second default, override, pause/resume/+15/skip/Ready, session recovery and superset timing. UI timer pause did not reliably expose Resume in runs #63–#66. Commit #33e5356 uses one stable pause/resume control and an accessible paused/running value; verification is pending run #70/#71.
- Progression: suggestions remain opt-in and update the active set only after explicit acceptance. The UI flow passed on iPhone 16 in runs #65 and #66; SE did not reach it because the old active exercise was collapsed/fields were inaccessible.
- Completion/History: summary, historical edits and Recently Deleted restoration are implemented. Run #65 reached summary and History editing but failed an assertion that expected the wrong accessible label after a completion toggle. The assertion now expects “Mark set complete” after toggling a completed set off in #33e5356. Full history edit/delete/restore UI verification remains pending.
- Training Home: split and monthly calendar screens are real, interactive and retain approved external geometry. Eight-workout fixture fills the 2×4 numbered split grid. A one-workout program leaves unused positions blank as required by master spec §2.3.

## Simulator evidence

- Run #42: iPhone 16 and SE each passed 33 unit + 4 UI tests; it predates these editor/completion workflows.
- Run #65: 34 unit tests passed on both devices. iPhone 16 UI suite passed progression acceptance and split reorder/search/custom exercise, but 2 of 7 cases failed (timer pause state and history-label assertion). iPhone SE had 4 of 7 UI failures.
- Run #66: 34 unit tests passed on both devices. iPhone 16 UI: 4/7 passed, 3 failed (timer, history assertion, drag order). SE UI: 3/7 passed, 4 failed (set fields and prescription controls).
- iPhone 18 Pro jobs are skipped; the simulator is **untested**.
- [Run #65 iPhone 16 screenshot artifact](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42418302117/artifacts/13593435114); [SE artifact](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42418302117/artifacts/13592459439). Screenshots are candidate evidence only, not approved baselines.
- The local [run #58 gallery](`/workspace/logbook-training-review/index.html`) predates the first-exercise expansion correction.

## Remaining acceptance criteria

Latest simulator runs #67–#71 were still underway or queued at this update. A complete green run is still required. Also outstanding: exercise tracking UI across all measurement modes, superset editor interaction, decline-progression test, multi-session date navigation through History, historical edit and Recently Deleted recovery through the UI, and fresh active-workout/editor/history captures on iPhone 16 and SE. Visual comparison and user approval remain separate from automated tests.
