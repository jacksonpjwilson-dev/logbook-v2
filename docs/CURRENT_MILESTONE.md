# Current Logbook milestone

**Objective:** Finish the Training UI workflow verification, review the actual Default Home and active-workout captures, and reconcile the canonical tracker. This milestone does not complete the app or authorize theme approval.

**Development branch:** `codex/default-theme-gate1`
**App source under test:** `f4b2cca17b3ba6bab2207783438f2296ffe93083` (pinned rest timer card)
**UI-test-only follow-up:** `dfd8678efdc354d47aac0e549850a46bae533cdd` (centered, slower drag gesture)
**Last fully green source/test run:** [#80](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42430593049), tested commit `dfd8678efdc354d47aac0e549850a46bae533cdd`. Run #42 remains the historical green app-source baseline before the current Training workflows. Run #79 was not fully green.
**Docs update:** the tracker, audit and report now reflect #80. This documentation-only commit will trigger the QA matrix again; it does not change the tested app-source or test bytes.

## Evidence status

Run #79 ran 34 unit tests and 7 UI tests per available device (iOS 18.5): SE passed 41/41; iPhone 16 passed 40 and failed 1 (the workout split drag assertion); iPhone 18 Pro test was skipped/untested.

Run #80 ran the same 34 unit + 7 UI tests per available device: iPhone SE **41 passed, 0 failed, 0 skipped**; iPhone 16 **41 passed, 0 failed, 0 skipped**. The iPhone 18 Pro step was skipped and remains **untested**. Commit `dfd8678` adjusts the test gesture to drop at the destination-row center and briefly hold; the actual reorder UI test passed on both devices in #80. #42 remains the older green baseline before the expanded Training workflows; #80 is now the newer fully green source/test evidence.

## Current implementation boundary

The app has real persistent Training UI flows for workout creation/reorder, exercise search and selection, custom exercises, prescription changes, active workout set entry, timer controls/recovery, explicit progression acceptance, completion summary, history editing, deletion and restoration. Run #80 passed the associated end-to-end UI flows on both available simulators. Superset editor interactions, program switching/skip in the UI, all tracking modes, declined progression, multi-session calendar drill-in, and PR presentation/recalculation UI still need dedicated acceptance tests.

The rest timer is now pinned in a blue card below the workout header and outside the scrollable exercise list. Run #80 screenshots and UI assertions confirm this on both devices, including after scrolling the set table. The approved 2×4 Home grid and dock have not changed.

The Training Split screenshot with one real workout has seven unused positions. Master spec §2.3 explicitly says to leave room instead of fabricating tiles; no alternate content is approved. An eight-workout QA fixture fills all positions. This discrepancy is documented rather than “fixed” by inventing workouts or changing the approved geometry.

## Screenshots and visual status

A downloadable gallery of 24 real PNG candidates from run #80 is available at `/workspace/logbook-training-review-run80/index.html` and `/workspace/logbook-training-review-run80.zip`. Every capture is labeled by device and workflow and is **not an approved baseline**. See `native-ios/QA/VISUAL_DIFFS/README.md`.

Daily grid measurements from run #80 (points):

| Device | Large | Medium measured | Small left / right | Dock frame |
|---|---:|---:|---:|---:|
| iPhone SE (3rd generation) | 212.35 × 212.35 | 211.5 × 101.25 | 101.85 × 101.85 / 102.35 × 101.85 | (19, 606.5, 67.5, 47) |
| iPhone 16 | 268.52 × 268.52 | 267.5 × 129.25 | 130.18 × 130.18 / 130.18 × 130.18 | (19, 757.67, 71, 47) |

No widget baseline was approved. The Home candidates show no clipping and the dock remains visible. The Active Workout and completion-summary sheets use standard grouped/light surfaces rather than the Home’s translucent Default surface; no original screen-specific visual reference is available to make a pixel comparison. Review remains pending.

The 26 original theme binary references are accessible in the supplied local handoff but are not in the repository. Their exact filenames and destination subfolders are recorded in `docs/handoff-v2/themes/REFERENCE_INDEX.md`. Four Glass assets are thumbnail-only. No theme or baseline was modified.

## Next work

1. Check the Actions run triggered by this documentation update; keep #80 as the app-source test evidence.
2. Resolve remaining Training UI coverage gaps without changing Home geometry.
3. Review Default appearance and resolve the Training Split empty-space request against the explicit master-spec rule before changing its internal layout.
4. Keep HealthKit disabled, and keep all changes on this development branch; no production configuration or `main` changes.

This workspace has no local Xcode or iOS Simulator. Simulator builds and screenshots are produced by GitHub Actions.
