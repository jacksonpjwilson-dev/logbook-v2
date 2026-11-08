# Current Logbook milestone — Training verification and Food/Nutrition

**Objective:** Close meaningful Training verification and implement/test approved Food workflows. The user accepts current Default visuals as a provisional working direction only. Preserve the approved Home layout and all themes; no final visual approval, theme propagation, HealthKit, production configuration changes or merge to `main` is authorized.

**Development branch:** `codex/default-theme-gate1` (local isolated worktree: `work/logbook-next-milestone`).

**Remote source head:** `f04bfdd2d5184a31c99bc41f165d6348b2a7c8f6`.
**Latest executed run:** Actions #87, source commit `f04bfdd2d5184a31c99bc41f165d6348b2a7c8f6`: https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42451731246. Builds succeeded on iPhone SE (3rd generation) and iPhone 16, but tests failed. iPhone 18 Pro's test step was skipped; that device remains **untested**.

| Simulator | Build | Unit tests | UI tests | Result |
|---|---|---:|---:|---|
| iPhone SE (3rd generation) | Passed | 43: 42 passed, 1 failed | 13: 9 passed, 4 failed | Failed |
| iPhone 16 | Passed | 43: 42 passed, 1 failed | 13: 8 passed, 5 failed | Failed |
| iPhone 18 Pro | Not run | Not run | Not run | Untested (test step skipped) |

The single unit failure is a legacy `WaterLog` JSON fixture that omits its required `id`; production decoding is not implicated. The UI failures include Food previous-day/date-swipe assertions, Food water-goal sheet presentation, a missing lazy-list hydration control on one simulator, and a progression-decline test that reselected a different lazy TextField. A source-level Food screen issue was identified: several independent `.sheet` modifiers were attached to the same List. The local candidate consolidates these routes into one typed sheet presentation. Tests now target the Food macro gesture surface, wait for date changes and retain the exact workout set accessibility identifier.

Run #87 produced unapproved screenshot/test artifacts: [iPhone 16](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42451731246/artifacts/13606208757), [iPhone SE](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42451731246/artifacts/13605984952), and the [iPhone 18 Pro availability note](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42451731246/artifacts/13606187009). Captures are candidates only; no approved visual baseline was overwritten.

**Last fully green source baseline:** run #80, commit `dfd8678efdc354d47aac0e549850a46bae533cdd`: 34 unit + 7 UI = 41/41 on iPhone SE and iPhone 16 (iOS 18.5). It does not verify later app-source changes.

## Training status

Persistent code and business logic cover named workout programs and independent flexible rotations; split editing and exercise search/custom exercises; alternate tracking modes and supersets; workout persistence, rest timer and progression; completion summaries; multiple sessions, historical correction/deletion/recovery; and estimated-1RM PR recalculation. The latest UI run passed key editor, program switching/skip, workout/superset/timer, completion/history and PR-summary paths. Overall Training is **not yet closed** because run #87 is red and the new out-of-order completion assertion in the candidate is unexecuted. Explicit direct UI evidence is still needed for rest-day behavior, calendar navigation to multiple same-day sessions, and PR display recalculation after historical edit/delete/restore. Store-level tests cover rotation/reopen, timer recovery, superset timing, alternate modes, and PR recalculation.

## Food and Nutrition status

Existing core workflows use persisted local data: meal/food logging and correction; the four exact Add Food options; CNF/Open Food Facts search and barcode adapters; unknown-barcode manual fallback; only verified servings; recent/favourite foods; recipes with logged nutrient snapshots; Add/Replace copy; dated targets and adherence; water logs and recovery. The candidate adds Food Home's seven-day metric selector and hydration actions, direct widget-to-Food destinations, and additional UI paths for trends, recipes, copy, and recovery. These changes have not yet run in Actions.

Public CNF/Open Food Facts endpoints require no credentials. Live availability, catalog completeness, licensing/attribution review, exhaustive offline/network transition behavior and physical-device camera barcode recognition remain unverified. Simulator tests exercise manual barcode fallback, not camera recognition.

## Visual and device limits

The user's latest review accepts styling only as a provisional working direction. Preserve four horizontally swipeable Home pages, exact 2-column × 4-row square-cell geometry, approved 1×1/2×1/2×2 widget sizes, the fixed five-icon athlete dock, no vertical Home scroll, and all current themes. Empty workout positions are valid for shorter splits. No screenshot is approved. The repository's original art gaps remain recorded in `docs/handoff-v2/themes/REFERENCE_INDEX.md`.

This Linux workspace has no Xcode or iOS Simulator. Simulator builds, tests and screenshots must be produced by the GitHub Actions macOS workflow. CI uses isolated synthetic data. HealthKit stays disabled.

## Next actions

1. Publish the local candidate, including the Food single-sheet route, Food Home widgets/interactions, corrected UI assertions and test fixture.
2. Run candidate on iPhone SE and iPhone 16; capture current Home/Food/Training/active-workout screens as unapproved artifacts. Keep iPhone 18 Pro untested unless its UI test step actually executes.
3. Diagnose any remaining red tests from actual logs and fix genuine product issues. Do not mark Training or Food verified from build success alone.
4. Update `native-ios/QA/REQUIREMENTS_TRACEABILITY.csv`, `AUDIT_RESULTS.md`, `TRAINING_PHASE2.md`, `REPORT.md`, and generated `docs/REQUIREMENTS_PROGRESS.md` from the resulting evidence.
5. Keep remaining direct Training acceptance paths open until the UI evidence is complete; then plan the next Food/Health/Accounts work without changing the constraints above.
