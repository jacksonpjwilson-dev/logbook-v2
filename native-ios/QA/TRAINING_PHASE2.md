# Training verification status

**Branch:** `codex/default-theme-gate1`
**Tested source:** `f6c2bb3b58972616e7b10c302212c1ac30d19d44`
**Evidence:** [Actions run #89](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42455968938)

## Results

On both iPhone SE and iPhone 16, the build succeeded; 44/45 unit tests and 8/13 UI tests passed. The iPhone 18 Pro runner skipped app tests after its availability check and is untested. Run #89 artifacts are [SE](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42455968938/artifacts/13607604595) and [iPhone 16](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42455968938/artifacts/13608365639); neither set is approved.

Store/business-logic coverage passed for flexible independent rotations, scheduled skip and out-of-order behavior, discard, origin-program association, timer/superset timing, tracking modes, accepted/declined progression, multiple sessions per date, record edits/recovery and PR calculation. The only unit failure is old WaterLog JSON missing `createdAt`; the follow-up adds a backward-compatible default and is unverified.

UI passed on both devices for switching programs/skip/out-of-order completion, progression accept/decline, split reordering/search/custom exercise, Next Workout launch, Daily check-in interactions and hydration history recovery. The broader History UI test failed at an ambiguous Workout Calendar selector before its edit/delete/recovery assertions. Food/UI failures and the zero-sized Food widget AX-frame probe also make the overall run red. Rest-day non-advance, PR recalculation after deletion/restoration and app termination/relaunch still lack direct UI evidence. Do not close Training yet.

The follow-up currently being prepared adds a unique Calendar opener ID and more reliable back navigation. It also corrects the legacy decoder and Food/Home test issues; none of those changes have run. This Linux environment cannot run Xcode or Simulator. Keep the exact grid and empty split cells for short programs. HealthKit is disabled; no production changes or merge to `main`.
