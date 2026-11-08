# Current Logbook milestone — Training verification and Food/Nutrition

**Objective:** Close meaningful Training verification and implement the approved Food workflows. Current Default visuals are accepted as a provisional working direction only. Preserve approved Home layout and themes. No final visual approval, theme propagation, HealthKit, production configuration change, or merge to `main` is authorized.

**Development branch:** `codex/default-theme-gate1` (isolated worktree `work/logbook-next-milestone`).
**Current branch head:** `22c6ef4d71af3c0b2d2e2045d7520fb083af7334`.
**Latest tested app source:** `54c236485bcd16ffa685ce5cea02d9e27a0220f2`.
**Latest completed CI:** [Actions #90](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42457771622).
**Current CI:** [Actions #91](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42459866908), source `22c6ef4d71af3c0b2d2e2045d7520fb083af7334`; simulator jobs are running.

| Simulator | Build | Unit tests | UI tests | Result |
|---|---|---:|---:|---|
| iPhone SE (3rd generation) | Passed | 44/45 passed | 8/13 passed | Failed |
| iPhone 16 | Passed | 44/45 passed | 8/13 passed | Failed |
| iPhone 18 Pro | Availability check only | Not run | Not run | Untested; test step skipped |

Run #90's unit failure was legacy `FoodRecipe` JSON missing `updatedAt`; the local decoder now supplies a backward-compatible default. UI failures were (a) zero-size frame probes on the Food Home page, (b) date controls/swipe not updating the expected selected day, (c) search's Cancel state hiding Done, and (d) returning from a workout detail failing to return to the selected calendar day. Local fixes target the actual widget roots, stable date state, closing search before Done, and explicit calendar navigation. Those fixes have not yet run. Unapproved #90 artifacts: [SE](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42457771622/artifacts/13608512203), [iPhone 16](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42457771622/artifacts/13609390347), and [18 Pro availability](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42457771622/artifacts/13607842943).

Commit `22c6ef4` adds backward-compatible WaterLog/FoodRecipe decoding, stable Food date state, actual widget-root geometry assertions, explicit Workout Calendar navigation, and a search dismissal step before Done. Actions #91 is testing these changes now. The Linux workspace has no Xcode, Swift compiler or iOS Simulator.

**Last fully green source baseline:** run #80, commit `dfd8678efdc354d47aac0e549850a46bae533cdd`, 34 unit + 7 UI tests = 41/41 on SE and iPhone 16. It does not verify later source.

## Training status

Run #90 unit suites passed store/business tests for independent flexible program rotations, scheduled skip/out-of-order/discard, origin-program association, timer and superset timing, exercise tracking modes, progression acceptance/decline, same-day sessions, historical changes/recovery and PR calculation. UI passed program switching/skip/out-of-order completion, progression accept/decline, split reordering/search/custom exercise, Next Workout start, check-in widget interactions and water history recovery on both devices. The History UI test failed when returning from a workout to its selected calendar day; the local calendar-path correction is untested. Rest-day non-advance, PR recalculation after deletion/restoration and relaunch after app termination still need direct UI coverage. Training is not fully verified.

## Food and Nutrition status

Persistent sources include meal logging/editing, the exact four Add Food options, CNF and Open Food Facts adapters, barcode scan with unknown-code manual fallback, verified serving conversion, manual correction, recents/favorites/recipes, Add/Replace copying, effective-dated nutrition targets and snapshots, calories/macros remaining, 7-day trends/adherence, hydration logging/history, Food History and recoverable deletion. In #90, 44/45 store/unit tests passed on each available simulator; Food Home, prior-day selection and recipe/search UI scenarios still failed and are not complete end-to-end evidence. Current targeted fixes are not yet tested.

Public CNF and Open Food Facts APIs require no credentials. Live API uptime/completeness, licensing and attribution review, offline network transitions and physical camera scanning remain unverified. Catalog or device behavior must not be inferred from parser tests.

## Constraints and next actions

Keep the four swipeable Home pages, exact 2×4 grid and 1×1/2×1/2×2 widget geometry, fixed five-icon dock, no Home vertical scroll, empty split cells for short programs, all approved themes, and HealthKit off. No screenshot is approved. The original theme-reference image gaps remain listed in `docs/handoff-v2/themes/REFERENCE_INDEX.md`.

1. Inspect Actions #91 on SE and iPhone 16; leave iPhone 18 Pro untested unless its app-test step executes.
2. Inspect logs/artifacts, correct remaining failures, and update tracker status only from completed run evidence.
3. Close the direct Training UI evidence gaps, then continue Food workflows and integration validation.
4. After Training and substantial Food coverage, define the next milestone for remaining History, Sleep, Weight, Supplements, Habits, and external account/coaching setup.

CI uses isolated synthetic data. No production configuration or `main` branch was modified.
