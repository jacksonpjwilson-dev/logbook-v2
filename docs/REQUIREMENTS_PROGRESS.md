# Logbook requirements progress

The canonical row-level evidence lives in [REQUIREMENTS_TRACEABILITY.csv](../native-ios/QA/REQUIREMENTS_TRACEABILITY.csv). Statuses are evidence-gated; a source implementation or a passing build alone does not count as verified functionality.

**Current source:** `codex/default-theme-gate1` at `0acf4353f6f39b6f6597669cb34cbcc56a020c7a`.  
**Last complete verified source baseline:** run #127, `a56a882c30bbf9fb684244349a5b1daf71533905`; see [run #127](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42767506189). It passed on iPhone SE and iPhone 16 (50 unit + 13 UI per device). Run #129, which contains new Sleep/Weight/Supplement code, is pending.

| Status | Requirement rows |
|---|---:|
| VERIFIED | 18 |
| IMPLEMENTED — UNVERIFIED | 11 |
| IN PROGRESS | 16 |
| NOT STARTED | 17 |
| BLOCKED | 2 |

Food date-picker navigation is verified in #127 on iPhone SE and iPhone 16. Open Food Facts search throttling is being tested in #128 (SE passed, iPhone 16 pending). Live provider use through Logbook, provider licensing/attribution and physical camera scanning remain unverified.

Sleep, Weight, Supplements and Habit behavior are implemented in the current source commit and have store/UI tests pending in #129. Do not move those rows to VERIFIED until the run succeeds on the available simulators.

Progress requirements remain open: the full five-tab chart contract, exercise-specific strength trends, balanced monthly heatmap, Nutrition Adherence details/widget and category-specific History completion. iPhone 18 Pro app tests remain skipped/unverified.
