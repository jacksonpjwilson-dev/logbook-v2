# Current Logbook milestone — Training verification and Food/Nutrition

**Objective:** Close meaningful Training verification and implement the approved Food workflows. Current Default visuals are accepted as a provisional working direction only. Preserve approved Home layout and themes. No final visual approval, theme propagation, HealthKit, production configuration change, or merge to `main` is authorized.

**Development branch:** `codex/default-theme-gate1` (isolated worktree `work/logbook-next-milestone`).
**Current branch head:** `54c236485bcd16ffa685ce5cea02d9e27a0220f2`.  
**Latest tested app source:** `f6c2bb3b58972616e7b10c302212c1ac30d19d44`.
**Latest completed CI:** [Actions #89](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42455968938).
**Current CI:** [Actions #90](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42457771622), source `54c236485bcd16ffa685ce5cea02d9e27a0220f2`; SE, iPhone 16, and 18 Pro runner jobs are active, with app tests pending.

| Simulator | Build | Unit tests | UI tests | Result |
|---|---|---:|---:|---|
| iPhone SE (3rd generation) | Passed | 44/45 passed | 8/13 passed | Failed |
| iPhone 16 | Passed | 44/45 passed | 8/13 passed | Failed |
| iPhone 18 Pro | Availability check only | Not run | Not run | Untested; test step skipped |

Run #89's shared unit failure was legacy WaterLog JSON missing `createdAt`. UI failures included zero-sized Home frame probes, Food date navigation not updating as asserted, ambiguous macro swipe query, missing hydration/recipe controls after navigation or scrolling, and duplicate Workout Calendar/history navigation selectors. See `native-ios/QA/REPORT.md` for exact cases. Actual, unapproved artifacts: [SE](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42455968938/artifacts/13607604595), [iPhone 16](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42455968938/artifacts/13608365639), and [18 Pro availability](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42455968938/artifacts/13607691705).

The #90 candidate fixes old WaterLog decoding with a safe timestamp fallback; stabilizes Food date identity and day shifts; supplies the frame probe's actual dimensions; gives Workout Calendar a unique accessibility identifier; switches History back navigation to a swipe; and makes Food test navigation return to the relevant Home/list sections. The current CI is running; no result is claimed for this source yet. `git diff --check` passes. The local Linux workspace has no Xcode, Swift compiler or iOS Simulator.

**Last fully green source baseline:** run #80, commit `dfd8678efdc354d47aac0e549850a46bae533cdd`, 34 unit + 7 UI tests = 41/41 on SE and iPhone 16. It does not verify later source.

## Training status

The run #89 unit suites passed store/business tests for independent flexible program rotations, scheduled skip/out-of-order/discard, origin-program association, timer and superset timing, exercise tracking modes, progression acceptance/decline, same-day sessions, historical changes/recovery and PR calculation. UI passed program switching/skip/out-of-order completion, progression accept/decline, split reordering/search/custom exercise, Next Workout start, check-in widget interactions and water history recovery on both devices. The History UI test failed before completing edit/delete/restore due to calendar selector ambiguity. Rest-day non-advance, PR recalculation after deletion/restoration and relaunch after app termination still need direct UI coverage. Training is not fully verified.

## Food and Nutrition status

Persistent sources include meal logging/editing, the exact four Add Food options, CNF and Open Food Facts adapters, barcode scan with unknown-code manual fallback, verified serving conversion, manual correction, recents/favorites/recipes, Add/Replace copying, effective-dated nutrition targets and snapshots, calories/macros remaining, 7-day trends/adherence, hydration logging/history, Food History and recoverable deletion. Run #89 store coverage passed these core calculations and data flows aside from the legacy decoder test; the Food UI workflows were not green. The new hydration/Home-route and recipe/search test changes are not yet executed.

Public CNF and Open Food Facts APIs require no credentials. Live API uptime/completeness, licensing and attribution review, offline network transitions and physical camera scanning remain unverified. Catalog or device behavior must not be inferred from parser tests.

## Constraints and next actions

Keep the four swipeable Home pages, exact 2×4 grid and 1×1/2×1/2×2 widget geometry, fixed five-icon dock, no Home vertical scroll, empty split cells for short programs, all approved themes, and HealthKit off. No screenshot is approved. The original theme-reference image gaps remain listed in `docs/handoff-v2/themes/REFERENCE_INDEX.md`.

1. Publish the follow-up on the development branch and run the existing CI on SE and iPhone 16; leave iPhone 18 Pro untested unless its test step executes.
2. Inspect actual logs and artifacts, fix remaining failures, and update the tracker only from completed run evidence.
3. Close the direct Training UI evidence gaps, then continue Food workflows and integration validation.
4. After Training and substantial Food coverage, define the next milestone for remaining History, Sleep, Weight, Supplements, Habits, and external account/coaching setup.

CI uses isolated synthetic data. No production configuration or `main` branch was modified.
