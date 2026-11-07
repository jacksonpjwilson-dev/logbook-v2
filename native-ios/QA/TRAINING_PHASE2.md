# Training System Phase 2 status

**Branch:** `codex/default-theme-gate1`  
**Scope:** Training workflows and Default Training Home content only. No HealthKit enablement, production configuration changes, or merge to `main`.  
**Latest completed run:** [Daily Home QA #37](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42391430833), commit `54275530e6a4e3d24218fe2b81bcdb71cf4c391f`.

## Implementation status

| Requirement | Source state | Verification |
|---|---|---|
| Named programs, exactly one active selection, independent flexible rotations | Implemented, including legacy migration, skip, reorder, cross-program move/delete, out-of-order completion and origin-program draft association | Existing unit tests cover >8 templates, switching, scheduled/partial/out-of-order completion and migration. Added tests cover split reorder, moving/deleting earlier entries and preserving scheduled selection. Pending next CI run. |
| Template editor and exercise catalog | Implemented: searchable built-in library, custom exercises, reorder, tracking mode, set/reps/rest, superset group/ungroup | Superset rotation/rest and session-only replacement are store-tested. Template editor and library UI are not fully automated. |
| Active workout | Implemented: top blue timer, 90s default/overrides, five-column weighted table, tracking-specific inputs, expand/collapse/progression, notes, pause, finish/discard, pinned stats, summary | Timer state/controls, override, superset rest and repository reopen have store tests. UI verifies start, Ready, duration control, table, screenshot and Resume entry. Test sequence that typed into a scrolled number field before tapping timer was removed after it failed on simulator keyboard focus. |
| Workout session, history and recovery | Implemented: autosaved draft, sessions keep originating program, session/exercise notes, multiple same-day sessions, historical set edits, soft delete/restore/purge | Existing and added store tests cover repository reopen, program switch during draft, two same-day sessions and edit persistence. OS-level app termination/relaunch is not verified. |
| Progression and personal records | Suggestions are explicit acceptance; completed weighted/reps sets derive Epley e1RM, first valid performance is baseline, max one PR per exercise/session, history edits/deletes/restores recalculate | Existing store tests cover acceptance, baseline, one-per-session and recalculation. Added invalid/zero-reps test ensures zero reps cannot complete an active set or create an e1RM record. Pending next CI run. |
| Recently Deleted | Soft delete, 30-day recovery, expiry purge | Existing expiry test plus new future-date restore guard. Pending next CI run. |
| Default Training Home | New interactive Workout Split widget shows the upcoming portion in the fixed 2×4 numbered tiles, highlights next, shows each workout's last completion, opens selected workout details, and links to full split. Workout Calendar now shows real month days, session labels/counts, current-week/today styling, month controls and date drill-in | New UI test checks tile, month controls, real calendar navigation and workout detail. Pending next CI run; screen remains a visual review candidate. |

The approved Home grid dimensions and page placements are unchanged. Run #36 verified the Daily grid geometry on both available simulators; run #37 did not change Home geometry.

## Verified prior simulator evidence

- [Run #36](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42389571701): iPhone 16 and iPhone SE each built and passed 25 unit tests; two of three UI tests passed. The third UI test failed in its synthetic keyboard/field-edit sequence before the rest-timer interaction. Its layout and active-workout screenshots were exported. The current test removes that brittle field sequence and asserts session resume from Training.
- Run #36 iPhone SE layout measurement: large 212.35 × 212.35 pt; medium measured 211.5 × 101.25 pt (outer element 212.35 × 107.35 pt); small cells 101.85 × 101.85 pt and 102.35 × 101.85 pt. Their lower edge is y=570.43 pt, before the dock at y=606.5 pt.
- iPhone 18 Pro was unavailable and its tests were skipped. **Untested**, not passed.
- [Run #26](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42376326674) failed during compilation on iPhone 16 and SE before any tests. Artifacts contain failure reports/logs only.
- [Run #37](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42391430833) also failed before tests: Swift could not type-check the expanded Workout Calendar day-detail `body`. The aggregate summary is now extracted into a small subview; this correction and the implementation listed above are pending CI.

## Remaining verification and limits

- Await next CI results for the new unit cases and Default Training Home interactions, then fix any failures.
- Run active workout keyboard entry and completion-summary interactions on simulator; unit tests do not prove visual accessibility or clipping.
- Exercise full split editor, progression prompt, historical editor, calendar detail and Recently Deleted UI end to end.
- Test OS-level force-close recovery, physical iPhone, Watch/Live Activity, and iPhone 18 Pro when a simulator/device is available.
- Review actual screenshots for Default Home and active workout. Screenshots are candidates only. No baselines or themes have been approved or changed.
- Food, Sleep/Weight/Supplements, and Progress & History Home visual discrepancies remain outside this Training-only correction.
