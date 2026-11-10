# Current Logbook milestone — Daily Tracking & Progress

**Development branch:** `codex/default-theme-gate1`  
**Current source commit:** `0acf4353f6f39b6f6597669cb34cbcc56a020c7a`  
**Latest complete green app-source run:** Actions #128, `a79ee507422e7f09d4ad56b9a5a157da17743f39` — [run #128](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42767782249).

## Verification

Run #128 succeeded on iPhone SE (3rd generation) and iPhone 16: each built successfully, passed 50/50 unit tests and 13/13 UI tests. Its workflow included the compact Food date-picker and explicit online search behavior. iPhone 18 Pro app tests were skipped. Screenshot artifacts: [SE](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42767782249/artifacts/13741520414) · [iPhone 16](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42767782249/artifacts/13741154325).

Run #129 adds Sleep/Weight/Supplement features, persistence, recovery and UI tests. It is in progress: [run #129](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42769523988). **Do not call the new workflows verified until this run passes.** Run #128 remains the last complete verified source baseline.

## Food

Food date-picker navigation, arrows/swipe and selected date passed on both devices in #127. Broader Food History correction/recovery, manual entry, unknown-barcode fallback, meal copy, recipes, goals, hydration and local persistence passed in #126.

Direct probes outside Logbook found that the legacy Health Canada 2015 CNF API responded with food/nutrient values; Open Food Facts product lookup and its legacy full-text CGI route returned data, while `/api/v2/search` returned HTTP 503. App code now uses explicit search submission, `/cgi/search.pl` and bounded retry/backoff; #128 passed on both devices. The direct probes are not app-integrated network/parser/cache/offline verification.

Open Food Facts asks for a contact-bearing User-Agent, limited requests and API usage declaration. No product contact email is configured. ODbL attribution/derivative database obligations need documented release review. The 2015 CNF source is legacy; review the 2026 CNF dataset (Open Government Licence – Canada) and serving policy. Physical camera/permission testing requires a real iPhone. No API key is required.

## Sleep, Weight, Supplements and Habits

Commit `0acf4353f6f39b6f6597669cb34cbcc56a020c7a` implements main overnight sleep assigned to wake date, separate naps and aggregated hours, duration override, optional quality, historical editing, weight unit conversions/one-per-date, previous-entry comparison, dated supplement schedules/doses/Taken-Undo, and 30-day recovery. Habit eligibility excludes naps and deleted records and treats unscheduled supplement days as neutral. A Sleep trend chart sums main sleep and naps by wake date.

Store and UI tests are pending in #129. Do not report these workflows as verified until the simulator run completes.

## Progress work still open

Complete the master spec's five chart tabs, exercise-specific strength trends, balanced monthly activity heatmap, Nutrition Adherence Home widget/history, and complete category-specific History navigation/edit/recovery. Current History includes weight/calorie and training PR charts; the new Sleep chart awaits #129.

Keep the fixed four Home pages, 2×4 geometry and five-icon dock. Do not implement additional themes or approve/overwrite screenshot baselines. HealthKit stays disabled. Use synthetic data. Do not change production configuration or merge to `main`.