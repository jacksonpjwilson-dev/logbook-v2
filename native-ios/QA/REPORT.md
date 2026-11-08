# Logbook QA report

## Current test evidence

**Development branch:** `codex/default-theme-gate1`
**Current remote commit:** `7b7ba8c91344359adb8602e8d2fdc089251f09d3` (run #84 completed, failed)
**Local candidate:** `edb4f74` plus selected-date fix, test corrections and live-workout PR test (not published or simulator-tested)
**Run #83:** [GitHub Actions](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42447491962) — failed compile on iPhone SE and iPhone 16 because `FoodEntryMode.manual` was missing. Fixed in `7b7ba8c`.
**Run #84:** [GitHub Actions](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42448118207) — builds succeeded; on each of iPhone SE and iPhone 16, 40 unit tests ran with 14 assertion failures and 10 UI tests ran with 3 failures. Unit failures trace to selected-date Food logging; UI failures were stale Food sheet taps, progression-label parsing, and the workout PR summary assertion. iPhone 18 Pro test was skipped and remains **untested**.
**Previous fully green evidence:** [Run #80](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42430593049), commit `dfd8678efdc354d47aac0e549850a46bae533cdd`: 34 unit + 7 UI = **41 passed, 0 failed, 0 skipped** on both iPhone SE and iPhone 16 (iOS 18.5); iPhone 18 Pro skipped/untested.

Run #82 tested `be9b3ce` and failed both available device builds before tests due to Swift type-check complexity in the Food screen. The screen was refactored into smaller view sections/helpers in `1cd8109`. Run #83 exposed the missing manual-entry enum case, fixed in `7b7ba8c`. Run #84 compiled and executed tests but failed as detailed above. The current local candidate fixes the date parameter and test assumptions and adds a live-session PR regression; it needs a new CI run.

## Scope on the current commit

Training unit/UI coverage now includes independent program rotations and scheduled skip, progression acceptance/decline, superset grouping and round rest behavior, exercise tracking-mode selection, multiple completed sessions on one date, PR display, historical editing and Recently Deleted recovery. Store tests additionally cover rotation edge cases, timer lifecycle, tracking-mode PR eligibility, first-workout baseline, and recalculation after historical edits/deletions. In run #84, program-switch/scheduled-skip, superset/rest timing, tracking-mode selection and split editor/search/custom exercise UI checks passed on both available devices. The completion-summary PR check failed, so visible PR presentation remains unresolved. See `TRAINING_PHASE2.md` and the canonical tracker for precise UI-versus-store boundaries.

Food/Nutrition source now includes persistent food and meal logging/editing, search, the exact four approved Add Food paths, manual entry, barcode provider/parser and unknown-code fallback, favorites/recents, verified portions, reusable recipes, meal/day copy Add/Replace, historical nutrition targets, calorie/macro remaining and adherence, 7-day trends, hydration goals/log/history, Food History editing/recovery, and offline state persistence. Unit tests cover business rules and persistence. Current UI automation source covers the four Add Food choices, local search and selection, manual entry, history correction, deletion/restoration and barcode manual fallback. Run #84 executed 40 unit and 10 UI tests per device but failed on selected-date persistence and one obsolete Food sheet dismissal tap. These are corrected locally and require re-verification.

Food UI acceptance still needs tests for recipe edit, copy Add/Replace, calendar selection and Recently Deleted UI across water and recipes; controlled provider online/offline error handling. Date swipe, recipe creation/log, goals/hydration, favorite/recents, and 30-day food/water/recipe recycle-bin tests are newly written in the local candidate and have not yet executed. The CI parser tests do not establish live Canadian Nutrient File/Open Food Facts availability or licensing/completeness. Camera barcode scan requires meaningful testing on physical hardware; the simulator verifies the manual fallback only.

## Screenshot and visual status

Run #84 uploaded simulator-specific screenshot artifacts despite test failures; these are non-approved candidates. Artifact downloads are available from the run page. The local fixes have not yet produced new screenshots. The previous fully green gallery remains the run #80 24-PNG gallery:

- `/workspace/logbook-training-review-run80/index.html`
- `/workspace/logbook-training-review-run80.zip`

No candidate has been accepted as a baseline. The visual direction is provisional. Approved widget geometry, dock and existing theme definitions remain unchanged. The Home screenshot evidence is not a substitute for feature UI coverage or visual approval.

## Environment and constraints

This Linux workspace has no Xcode or iOS Simulator. All native build, test and capture evidence must come from the macOS GitHub Actions run for its exact commit and device. HealthKit stays disabled. No production configuration or `main` branch was changed. CI test data is isolated synthetic data.
