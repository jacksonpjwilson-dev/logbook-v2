# Logbook requirements progress

Row-level implementation and evidence status is maintained in [REQUIREMENTS_TRACEABILITY.csv](../native-ios/QA/REQUIREMENTS_TRACEABILITY.csv). Source presence and a successful build do not establish a verified workflow.

**Current branch/source:** `codex/default-theme-gate1` / `cbe90804bd7eda542f0d9c5c6d1f02b90b1eeebf`.  
**Latest complete green app-source baseline:** Actions #128, `a79ee507422e7f09d4ad56b9a5a157da17743f39` ([run #128](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42767782249)); iPhone SE and iPhone 16 each passed build, 50 unit and 13 UI tests. iPhone 18 Pro app tests were skipped. #126 is retained as an earlier baseline, not the newest green result.

Run #131 built on iPhone SE and iPhone 16 but failed with 54/55 unit and 11/14 UI tests passing on each. Its old-weight decoding and accessibility/lazy-row test failures are addressed in later commits but remain unverified. As of this report, follow-up runs #132–#134 are running and #135–#145 are queued. Do not promote affected rows to VERIFIED until a complete current-source run passes.

| Status | Requirement rows |
|---|---:|
| VERIFIED | 18 |
| IMPLEMENTED — UNVERIFIED | 11 |
| IN PROGRESS | 16 |
| NOT STARTED | 17 |
| BLOCKED | 2 |

Food date-picker navigation is verified in #127 on both available simulators. Food History edit/recovery and unknown-barcode manual fallback were tested in #126. Actual CNF/OFF endpoint probes returned real data, but live provider integration through Logbook—including parser behavior, error handling, caching, offline replay, licensing/attribution compliance and data integrity—is not verified. A product contact email is needed for the OFF User-Agent/usage declaration. Physical barcode camera tests need an iPhone.

Sleep, Weight, Supplements and Habits implementation has synthetic unit/UI coverage, but #131 failed; subsequent migration and UI-test fixes have no completed green run yet. The exact test outcomes and artifact links are in [QA/REPORT.md](../native-ios/QA/REPORT.md).

Progress Home implementation now includes five data-based 30-day metrics, strength exercise selection, a numbered cross-feature activity heatmap and adherence/PR widgets; Full History gained strength and protein charts, and deleted food entries are excluded from nutrition trends. These additions are pending simulator/UI verification and visual review. Full category-specific History editing/recovery and trend recalculation after all mutations remain open.

iPhone 18 Pro app tests remain skipped/unverified. The Home geometry and existing themes are preserved; no screenshots have been accepted as baselines.
