# Current Logbook milestone — Training verification and Food

**Objective:** Close the remaining focused Training UI checks and deliver the persistent Food/Nutrition workflows in the approved specification. This is not visual approval, app completion, or authorization to change Home geometry, other themes, production data, HealthKit or `main`.

**Development branch:** `codex/default-theme-gate1` (isolated local worktree branch `work/logbook-next-milestone`)
**Current source correction (local):** `c2e18bd` fixes the direct Manual Entry option exposed by run #83. It is awaiting publication to the development branch because the shell Git remote is temporarily unreachable; GitHub repository tools will be used for the already-authorized development-branch update.
**Previous verified app/test baseline:** run #80, commit `dfd8678efdc354d47aac0e549850a46bae533cdd`, 34 unit + 7 UI tests on each of iPhone SE (3rd generation) and iPhone 16; 41/41 on both. iPhone 18 Pro was skipped and untested.
**Run #82:** commit `be9b3cec6b98f55b896a7383181c10ff9e204d99`; failed on both available simulator builds before test execution because Swift could not type-check the composed Food screen expression in a reasonable time. This source-level issue was corrected by splitting `FoodScreen` into smaller computed sections/helpers.
**Run #83 result:** [GitHub Actions run #83](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42447491962), commit `1cd8109f3e203d1b6d9e3241e975a2edaaa081e7`, failed to compile on both iPhone SE and iPhone 16 before test execution. The compiler found that the required direct Manual Entry action selected a missing `FoodEntryMode.manual` case. This is fixed in local commit `c2e18bd`; it has not yet been published or tested. iPhone 18 Pro was skipped and remains **untested**.

## Training implementation and pending verification

The current source now includes simulator UI paths for program switching/independent rotation and scheduled skip, declined progression, multiple sessions on one date, PR presentation, workout history edit/delete/restore, exercise tracking-mode selection, superset grouping and round-based rest timing. Existing store tests cover flexible program rotations, scheduled/out-of-order/discard rules, preserving the original program on a draft, timer pause/extension/reopen, tracking-mode PR eligibility, first-workout PR baseline, maximum one PR per exercise/workout, and PR recalculation after historical edits/deletion.

These added UI checks were not executed in run #83 because compilation failed before tests. They remain **unverified** until a later run completes. Rest-day UI, draft program-switch UI, all tracking-mode input validation, full calendar drill-in for multiple same-day sessions and complete PR recalculation presentation remain narrower gaps. Preserve the exact Home geometry; unoccupied split cells remain empty when the user has fewer than eight workouts.

## Food/Nutrition implementation and verification boundary

Implemented persistent Food flows include meal creation/rename/expand/edit; the exact four Add Food choices (Search Foods, Scan Barcode, Manual Entry, Recent Foods); local and remote search; favorites as an independent filter; quantity confirmation and serving conversion with only verified food-specific portions; manual personal foods; barcode lookup and unknown-barcode manual fallback; recipes with ingredient/yield nutrition; Add/Replace meal/day copying with recoverable replacement; date-specific calorie/macro targets; remaining values and adherence; seven-day trends; hydration quick-add/custom amounts, goals and history; Food History correction and Recently Deleted recovery; offline persistence; and food navigation from Home.

Canadian Nutrient File and Open Food Facts use public HTTP endpoints with attribution/source metadata and no app credential. The unit suite tests the provider response parser and data rules, but does not establish live endpoint uptime, licensing review, provider completeness, camera scanning on hardware, or offline behavior under every failure mode. Barcode camera access uses AVFoundation; CI only exercises its manual fallback because simulator camera scanning is not a meaningful physical barcode test. Food unit/UI execution in run #83 did not occur because the build failed before tests. UI coverage still needs to be expanded for recipe editing/logging, meal copy Add/Replace, goal/history controls, hydration, favorites/recent flows, day swiping/calendar selection and live/offline provider failure.

## Preserved constraints

- Four Home pages, fixed 2-column × 4-row square-cell grid, small 1×1, medium 2×1, large 2×2, no Home vertical scroll, fixed five-icon dock.
- Current visual style is provisional working direction only. No screenshot or visual baseline has been approved or overwritten; other themes have not been propagated.
- HealthKit remains disabled. No `main` merge, production configuration change, or use of personal data.
- This Linux worktree has no Xcode/iOS Simulator. GitHub macOS Actions is the only simulator verification path available here.

## Next actions

1. Publish the local `c2e18bd` manual-entry correction to the development branch; run #83 found it by failing before tests. Rerun without indefinite retries.
2. Add meaningful Food UI coverage for currently untested workflows, commit the increments to the development branch, and wait for their actual CI results.
3. Refresh tracker, issue register, audit and test report from the completed evidence; download actual simulator screenshots as review candidates.
4. Keep remaining visual acceptance separate and identify the next milestone after Food/Training evidence is reconciled.
