# Logbook QA report

## Current test evidence

**Development branch:** `codex/default-theme-gate1`
**Current source correction (local):** `c2e18bd` — not yet published to GitHub at the time of this report
**Run #83:** [GitHub Actions](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42447491962) — **failed before tests on iPhone SE and iPhone 16** because `FoodEntryMode.manual` was missing. The iPhone 18 Pro test action was skipped; that simulator remains **untested**.
**Previous fully green evidence:** [Run #80](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42430593049), commit `dfd8678efdc354d47aac0e549850a46bae533cdd`: 34 unit + 7 UI = **41 passed, 0 failed, 0 skipped** on both iPhone SE and iPhone 16 (iOS 18.5); iPhone 18 Pro skipped/untested.

Run #82 tested `be9b3ce` and failed both available device builds before tests due to Swift type-check complexity in the Food screen. The screen was refactored into smaller view sections/helpers in `1cd8109`; run #83 is checking that fix and the expanded Training/Food suite. No test result for #83 is claimed yet.

## Scope on the current commit

Training unit/UI coverage now includes independent program rotations and scheduled skip, progression acceptance/decline, superset grouping and round rest behavior, exercise tracking-mode selection, multiple completed sessions on one date, PR display, historical editing and Recently Deleted recovery. Store tests additionally cover rotation edge cases, timer lifecycle, tracking-mode PR eligibility, first-workout baseline, and recalculation after historical edits/deletions. All new run #83 simulator coverage is pending. See `TRAINING_PHASE2.md` and the canonical tracker for precise UI-versus-store boundaries.

Food/Nutrition source now includes persistent food and meal logging/editing, search, the exact four approved Add Food paths, manual entry, barcode provider/parser and unknown-code fallback, favorites/recents, verified portions, reusable recipes, meal/day copy Add/Replace, historical nutrition targets, calorie/macro remaining and adherence, 7-day trends, hydration goals/log/history, Food History editing/recovery, and offline state persistence. Unit tests cover business rules and persistence. Current UI automation source covers the four Add Food choices, local search and selection, manual entry, history correction, deletion/restoration and barcode manual fallback. Run #83 did not execute the suite because compilation failed.

Food UI acceptance still needs tests for recipe builder/edit/log, copy Add/Replace, goals/history controls, hydration entry/history, favorite/recents, horizontal date navigation/calendar, and provider online/offline error handling. The CI parser tests do not establish live Canadian Nutrient File/Open Food Facts availability or licensing/completeness. Camera barcode scan requires meaningful testing on physical hardware; the simulator verifies the manual fallback only.

## Screenshot and visual status

Run #83 should upload actual simulator screenshots and test reports after the two available jobs finish. Until then, the last downloadable candidate gallery is the 24-PNG run #80 gallery:

- `/workspace/logbook-training-review-run80/index.html`
- `/workspace/logbook-training-review-run80.zip`

No candidate has been accepted as a baseline. The visual direction is provisional. Approved widget geometry, dock and existing theme definitions remain unchanged. The Home screenshot evidence is not a substitute for feature UI coverage or visual approval.

## Environment and constraints

This Linux workspace has no Xcode or iOS Simulator. All native build, test and capture evidence must come from the macOS GitHub Actions run for its exact commit and device. HealthKit stays disabled. No production configuration or `main` branch was changed. CI test data is isolated synthetic data.
