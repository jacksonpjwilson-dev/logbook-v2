# Logbook QA report — Daily Tracking & Progress

**Branch:** `codex/default-theme-gate1`  
**Current source commit:** `0acf4353f6f39b6f6597669cb34cbcc56a020c7a`  
**Latest complete green app-source baseline:** Actions #128, `a79ee507422e7f09d4ad56b9a5a157da17743f39`, [run](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42767782249). This run predates the check-in implementation in #129.

## Runs at report time

| Run | Commit | iPhone SE | iPhone 16 | iPhone 18 Pro |
|---|---|---|---|---|
| [#127](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42767506189) | `a56a882c30bbf9fb684244349a5b1daf71533905` | Passed: build, 50/50 unit, 13/13 UI | Passed: build, 50/50 unit, 13/13 UI | App tests skipped |
| [#128](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42767782249) | `a79ee507422e7f09d4ad56b9a5a157da17743f39` | Passed: build, 50/50 unit, 13/13 UI | Passed: build, 50/50 unit, 13/13 UI | App tests skipped |
| [#129](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42769523988) | `0acf4353f6f39b6f6597669cb34cbcc56a020c7a` | Queued/running | Queued/running | App tests expected to be skipped if unavailable |

Run #128 is the latest complete green source run, but it does not include the current check-in code. Run #129 is the first simulator verification of the new Sleep/Weight/Supplement workflows; results are not available yet.

## Food verification

Run #127 passed the direct Food compact date-picker, date-arrow/swipe and selected-date UI assertions on both iPhone SE and iPhone 16. Run #128 passed the provider-search changes on both available devices. Run #126 passed the core Food History edit/recovery, manual-entry, unknown-barcode fallback, targets, recipes, hydration and copy workflows on iPhone SE and iPhone 16.

A direct live API probe (outside the app) confirmed:
- Health Canada's legacy 2015 CNF endpoints responded with 5,690 foods and nutrient values for food code 1704 (Banana, raw): 89 kcal, 1.09 g protein, 22.84 g carbohydrate and 0.33 g fat per 100 g.
- Open Food Facts' product endpoint returned a Nutella result for barcode `3017620422003` with per-100-g nutrition values. The product response had no usable gram serving, so the app must not invent a serving conversion.
- The OFF `/api/v2/search` route returned HTTP 503 in the probe; the legacy full-text `/cgi/search.pl` endpoint returned HTTP 200 and results. The app was changed to the latter route and to search only on explicit submission, with bounded retry/backoff.

This probe proves those endpoints responded from the probe environment only. It does not prove that the app's current network stack, parser, cache, retry policy or offline behavior work against a live service. Mock response tests are not live-provider proof.

**Provider release checks:** Open Food Facts asks clients to use an identifiable User-Agent with contact information, limit search requests, and complete its API usage form. The app has a configurable `LogbookFoodProviderContactEmail` setting, but no product contact email was supplied/configured. OFF data is under ODbL/database-content terms; attribution and any share-alike obligations need a documented product review. Health Canada's 2015 CNF remains a legacy source; CNF 2026 is published as an Open Government Licence – Canada dataset. Confirm source attribution, versioning and serving-data policy before release.

## Sleep, Weight, Supplements and Habits

Commit `0acf4353f6f39b6f6597669cb34cbcc56a020c7a` adds:
- Overnight sleep on the wake date, separate nap records, computed or overridden durations, optional 1–5 quality rating, edit/delete/restore and 30-day expiry.
- One weight entry per date, lb/kg conversion, prior measurement comparison, historical correction and recovery.
- Daily or selected-weekday supplement schedules, optional dose descriptions, historical Taken/Undo, schedule gating, editing and recovery.
- Habit metrics that exclude naps/deleted records from the overnight Sleep requirement and count only scheduled doses; no-due days remain neutral.
- A 30-day sleep chart aggregated by wake date and including naps.

Unit and UI tests for these flows were added, but **none are counted as passed yet**. Actions #129 is pending. The Xcode workflow must also confirm backward-compatible state decoding and startup purge of expired deleted check-ins.

## Progress & History gaps

The following requirements remain incomplete: the five-tab Weight/Strength/Sleep/Calories/Protein chart contract and exercise-specific strength trends, balanced monthly activity heatmap, Nutrition Adherence Home widget/history, and complete category-specific history navigation/edit/recovery. Weight and calorie history charts and workout PR/history are present; a Sleep chart was added in the pending commit. See tracker rows P01–P03.

## Screenshots

Run #128 iPhone SE artifact: [download candidate screenshots and test report](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42767782249/artifacts/13741520414). These are actual simulator captures from commit `a79ee507422e7f09d4ad56b9a5a157da17743f39`, not from the new Check-in UI code. New check-in screenshots will only exist if #129's simulator test completes and uploads. All captures are review candidates; none are approved baselines.

Run #126 artifacts remain available for previous Home, Training and Food screenshots:
- [iPhone SE](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42496892834/artifacts/13624920583)
- [iPhone 16](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42496892834/artifacts/13624832311)
- [iPhone 18 Pro availability only](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42496892834/artifacts/13624205975)

## Constraints

HealthKit remains disabled. Production configuration and `main` were not changed. No approved theme or Home geometry was changed. iPhone 18 Pro application tests remain unverified; physical camera/barcode tests require a real iPhone and cannot be proven on the available CI simulators.
