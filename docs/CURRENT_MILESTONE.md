# Current Logbook milestone — Training verification and Food/Nutrition

**Objective:** Close meaningful Training verification and implement the approved Food workflows. Current Default visuals are accepted as provisional working direction only. Preserve the approved Home layout and all themes. No final visual approval, theme propagation, HealthKit, production configuration change, or merge to `main` is authorized.

**Development branch:** `codex/default-theme-gate1` (local isolated worktree `work/logbook-next-milestone`).

**Remote source head:** `f28e71c9fcfa4ddf3289e5467d3e591737eedb35`.
**Latest completed CI:** [Actions #88](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42454022156), source commit `f28e71c9fcfa4ddf3289e5467d3e591737eedb35`.

| Simulator | Build | Unit tests | UI tests | Result |
|---|---|---:|---:|---|
| iPhone SE (3rd generation) | Passed | 42/43 passed | 6/13 passed | Failed |
| iPhone 16 | Passed | 42/43 passed | 8/13 passed | Failed |
| iPhone 18 Pro | Availability check only | Not run | Not run | Untested; workflow skipped test step |

The common unit failure is an invalid UUID in the `WaterLog` legacy fixture. UI failures include Home widget accessibility-frame measurement, Food date navigation, ambiguous macro accessibility identifiers, Water Goal sheet presentation, an unstable decline-value assertion, and on SE only a hydration lookup and split drag. Run #88 artifacts are actual, unapproved captures/reports: [SE](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42454022156/artifacts/13607506214), [iPhone 16](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42454022156/artifacts/13607580740), and the [18 Pro availability note](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42454022156/artifacts/13607275657).

The local candidate adds a valid UUID fixture, parent-frame measurements that exclude child overflow, grouped macro accessibility, explicit date identity, Food sheets attached to the screen container, custom hydration entry, full-length nutrition streak logic, saved-recipe search/favorites, same-day calendar session drill-in and visible PR recalculation assertions. It has not been published or run. `git diff --check` passes. This Linux workspace has no Xcode, Swift compiler or iOS Simulator.

**Last fully green source baseline:** run #80, commit `dfd8678efdc354d47aac0e549850a46bae533cdd`, 34 unit + 7 UI tests = 41/41 on SE and iPhone 16. It does not verify later source. Run #87 was also red; see `native-ios/QA/REPORT.md`.

## Training status

Persistent business logic and store tests cover independent flexible program rotations, scheduled skip/out-of-order completion/discard, draft program ownership, timer lifecycle/recovery, superset rest timing, exercise tracking modes, explicit progression acceptance/decline, same-day sessions, historical editing/deletion/recovery and estimated-1RM PR calculation/recalculation. Run #88's UI suite remained red. The local follow-up adds direct same-date calendar navigation and visible PR recalculation after history edits. Remaining direct UI evidence includes rest-day non-advance, PR recalculation after deletion/restoration, and session recovery after app termination. Training is not verified complete.

## Food and Nutrition status

Persistent source workflows cover meal logging/editing, the exact four Add Food options, Canadian Nutrient File and Open Food Facts search adapters, barcode scanning with unknown-code manual fallback, verified serving conversion, manual correction, recents/favorites, recipes and nutrient snapshots, Add/Replace copying, dated nutrition goals/adherence, seven-day trends, water history and recoverable deletion. Run #88 did not verify the Food/Home changes because UI tests failed. The local candidate adds tests and bounded custom hydration entry, and fixes the observed route/accessibility issues.

CNF and Open Food Facts endpoints require no credentials. Live service availability, catalog completeness/licensing review, network transition/offline guarantees and physical camera scanning remain unverified. Do not describe provider or hardware behavior as tested from parser/simulator tests.

## Constraints and next actions

Keep four swipeable Home pages, the exact 2×4 grid and 1×1/2×1/2×2 widget sizing, the fixed five-icon dock, no Home vertical scrolling, empty split cells for short programs and all existing themes. No screenshot is approved. The original theme-reference image gaps remain listed in `docs/handoff-v2/themes/REFERENCE_INDEX.md`.

1. Publish the local candidate on the development branch and run CI on SE and iPhone 16.
2. Diagnose each failure from actual logs, fix functional defects and repeat until the relevant tests pass. Capture screenshots as unapproved artifacts; leave iPhone 18 Pro untested unless its test step executes.
3. Update the canonical tracker and audit only from actual run evidence; keep Training and Food open until every applicable acceptance criterion is verified.
4. After Training verification and substantial Food coverage, define the next milestone for remaining History, Sleep, Weight, Supplements, Habits and external account/coaching setup.

CI uses isolated synthetic data. HealthKit remains disabled. No production configuration or `main` branch was modified.
