# Current Logbook milestone — Daily Tracking & Progress

**Updated:** 2026-11-13 18:42 UTC  
**Development branch:** `codex/default-theme-gate1`  
**Current app-source commit:** `7d968256207bdeadd637ed415036b200b81c009b`  
**Last fully green app-source baseline before the current fixes:** Actions #128, `a79ee507422e7f09d4ad56b9a5a157da17743f39`. Actions #183 is pending; do not treat the new source as verified yet.

## Verification state

- [Actions #173](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/43459404652) failed on the restored Sleep Delete visibility and heatmap exact-date UI assertions. The iPhone SE build and unit suite passed; the iPhone 16 result was incomplete when this run was superseded. iPhone 18 Pro app tests were skipped.
- [Actions #175](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/43463934555), source `912ddff34f94550499dfcd8f7222b070ce0713ab`: iPhone SE passed build and 64 unit tests (1 skipped, 0 failures), with 14/16 UI tests passing; iPhone 16 passed build and 64 unit tests (1 skipped, 0 failures), with 13/16 UI tests passing. Both devices passed category-history/check-in editing and Habits/Check-in widget taps. Remaining UI failures included restored Sleep reachability and heatmap date navigation; Food History also failed on iPhone 16. iPhone 18 Pro app tests were skipped.
- [Actions #177](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/43465365651) was canceled; it produced no app verification.
- [Actions #182](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/43475359926), source `0a753e6d27cab6ff77187e39d096e795152f23b2`: iPhone 16 build passed, 64 unit tests ran (1 skipped, 0 failures), and 16 UI tests ran with 3 failures (Sleep restore visibility, Food History route, heatmap 2026-11-01 selection). The iPhone SE job was canceled; iPhone 18 Pro ran only its availability check, not app tests.
- [Actions #183](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/43483155422) tests source `7d968256207bdeadd637ed415036b200b81c009b`; it is queued. This source targets the three still-failing UI paths without relaxing the acceptance assertions.

## Diagnosis and current fixes

- **Restored Sleep control:** Actions #182 found the restored record and its Delete button in the accessibility tree, but the row remained off-screen (not hittable). The issue is list visibility after the restored active list changes, not a missing Delete action or a test locator. The fix waits for the restored record to enter the active list, scrolls to that exact row and its Delete target, and makes the UI test wait for hittability.
- **Heatmap date:** Actions #182 tapped the button whose stable ID was `activity-day-2026-11-01`, while History displayed `2026-11-02`. The exact date requirement remains in the test. The fix stores each cell's date key and day label together, uses the key directly in the tap action, and reapplies an explicit History route date on appearance to avoid stale SwiftUI route state.
- **Food History:** iPhone 16 Actions #182 did not show the Food History destination after the tap. The fix replaces the ambiguous list link with a state-driven navigation destination, retaining the same screen and record editor.

## Coverage already exercised

- Sleep/Weight/Supplement category History navigation and editing, and Habits/Check-in widget region navigation passed on both iPhone SE and iPhone 16 in #175; these paths also passed on iPhone 16 in #182.
- Unit tests in #182 passed for sleep wake-date/naps/recovery, weight unit comparisons and recovery, supplement schedule/undo/expiry, Habits streak and neutral no-due handling, deleted-food chart aggregation, activity scoring, same-day records, and persistent restore/expiry behavior.
- The Progress UI test reached its chart metric selection and calendar month controls before failing only on the selected-day value. The #183 run must confirm the corrected route and all end-to-end screens.

## Screenshots and safety

Screenshots are simulator-generated review candidates, not approved baselines. Prior complete captures are available in [#175 iPhone SE artifact](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/43463934555/artifacts/14061556277) and [#175 iPhone 16 artifact](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/43463934555/artifacts/14060254423). #182 has a full iPhone 16 artifact at [artifact 14063903278](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/43475359926/artifacts/14063903278); its iPhone SE job was canceled and did not produce a full capture set. Await #183 for refreshed candidates.

Keep the four Home pages, exact 2-column × 4-row grid, widget dimensions, five-icon dock and all approved themes unchanged. HealthKit stays disabled. Tests use isolated synthetic data. No production settings were changed and nothing was merged to `main`.

# Archived prior milestone notes (historical; superseded by current status above)

**Development branch:** `codex/default-theme-gate1`  
**Current app-source commit:** `705aec30376cbc9285c7cc4d4e1955666fab0160`  
**Last fully green app-source baseline:** Actions #128, `a79ee507422e7f09d4ad56b9a5a157da17743f39` — [run #128](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42767782249). Run #126 (`074ab167f4ea6826f6d9a7c5536257ea2c1bd395`) remains preserved as the prior accepted baseline; repository evidence shows #128 is the newer complete green run.

## Verification status

Run #131 tested source commit `aaf18f155b4b713eaa1cc6bb0cf6b93a9e25461e`. Build succeeded on iPhone SE (3rd generation) and iPhone 16, but the run failed on both: **54/55 unit tests and 11/14 UI tests passed per device**. The unit failure exposed a genuine legacy WeightLog decode issue (records without an `id`). UI failures involved Recently Deleted visibility, stale button-label assertions, a lazy same-day history row check, and a workout row that was off screen. The source and test corrections are committed after #131; they are not verified yet.

- [Run #131](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42771133119) and its actual, unapproved simulator candidates: [iPhone SE artifact](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42771133119/artifacts/13743096416) · [iPhone 16 artifact](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42771133119/artifacts/13742394589). [iPhone 18 Pro artifact](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42771133119/artifacts/13741268275) contains availability information only; app tests were skipped.
- Follow-up Actions #132–#149 were triggered by incremental commits. As of this report #132–#134 are running and #135–#145 are queued; none is evidence of a pass. [Actions list](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/workflows/daily-home-qa.yml?query=branch%3Acodex%2Fdefault-theme-gate1).

Run #128 passed iPhone SE and iPhone 16 builds, 50/50 unit tests and 13/13 UI tests on each. Its iPhone 18 Pro app tests were skipped. The SE and iPhone 16 screenshot artifacts are [here](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42767782249).

## Food

Food date-picker day navigation, arrows/swipe and selected-date UI assertions passed on both available devices in #127. Food History editing/recovery, manual-entry flows and the unknown-barcode fallback were exercised in #126. Those successes do not establish live-provider use through the app.

Direct live probes outside Logbook returned real source data:
- Health Canada's legacy 2015 Canadian Nutrient File endpoint returned 5,690 foods; code 1704 (raw banana) returned 89 kcal, 1.09 g protein, 22.84 g carbohydrate and 0.33 g fat per 100 g.
- Open Food Facts product lookup for barcode `3017620422003` returned per-100-g nutrition. Its `/api/v2/search` endpoint returned HTTP 503 in the probe, while the legacy `/cgi/search.pl` route returned HTTP 200. The app uses explicit search submission, the legacy route and bounded retry/backoff; simulator provider tests use controlled responses, so real in-app parsing, response error behavior, offline cache and data integrity remain unverified.
- OFF requires an identifiable contact-bearing User-Agent and asks API users to declare usage. No product contact email is configured. OFF data is subject to ODbL attribution/share-alike conditions; release attribution and database obligations need review. No API key was required in the probe.
- The 2015 CNF is legacy. Review the [2026 CNF dataset](https://open.canada.ca/data/en/dataset/1b6139bd-ed7e-4043-bc28-ff00e10f3109) and Open Government Licence – Canada before changing source data. Consult [Health Canada's CNF information](https://www.canada.ca/en/health-canada/services/food-nutrition/healthy-eating/nutrient-data/canadian-nutrient-file-about-us.html), [OFF API docs](https://openfoodfacts.github.io/documentation/docs/Product-Opener/api/) and [OFF terms](https://world.openfoodfacts.org/terms-of-use).
- Physical barcode-camera permission and scan tests require an iPhone with camera access. They remain untested; this does not block other app work.

## Sleep, Weight, Supplements and Habits

The current source implements wake-date overnight sleep, separate naps, duration overrides, optional 1–5 quality, historical edits, daily weight with lb/kg conversion and previous-entry comparison, scheduled supplements, Taken/Undo, and eligibility-aware check-ins/streaks. Synthetic unit tests cover wake-date attribution, naps, expiration/recovery, weight conversion, supplement weekdays and no-due days. Run #131 did not pass overall. The latest source additionally adds custom legacy decoders for WeightLog, Supplement and SupplementDose; a legacy taken dose defaults to an explicitly recorded completion. Follow-up UI assertions now use stable identifiers and scroll to deleted rows.

The last green baseline #128 did not contain this feature implementation. Do not call these flows verified until a complete run for the current source passes.

## Progress & History

The current source adds a data-backed Default Progress Home chart with Weight / Strength / Sleep / Calories / Protein, exercise selection for weighted strength trends, numbered 30-day activity cells with day navigation, PRs This Month and a 30-day Nutrition Adherence ring. Full History now includes selectable exercise-specific strength and protein charts; calorie trend aggregation excludes deleted foods. Activity score uses an equal-weight presence signal for Training, Food, Sleep and Weight, plus Supplements as a fifth category only when one is scheduled that day. This is an implementation choice recorded for validation, not a separately approved visual design.

These new widgets, history aggregations and cross-feature day navigation have no passing simulator evidence yet. Remaining work includes regression tests for heatmap eligibility/score, complete category-specific History editing/recovery and confirmation that every derived trend refreshes after edit, delete, restore and expiry. Visual approval remains pending.

## Guardrails

Preserve the four Home pages, exact 2-column × 4-row widget geometry, five-icon dock and all existing themes. Do not expand themes or approve/replace screenshot baselines. HealthKit remains disabled. Continue using synthetic test data; do not modify production configuration or merge to `main`. iPhone 18 Pro app tests remain untested.
