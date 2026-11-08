# Current Logbook milestone — Training verification and Food/Nutrition

**Objective:** Finish meaningful Training verification and implement the approved Food workflows, updating tests and evidence. This work does not grant final visual approval or permission to alter the approved Home layout, implement other themes, enable HealthKit, change production configuration or merge to `main`.

**Development branch:** `codex/default-theme-gate1` (isolated worktree branch `work/logbook-next-milestone`).

**Latest remote commit:** `10fd85f930b437f8189c048b7e3d2e598b547e8a`.
**Latest tested commit:** `10fd85f930b437f8189c048b7e3d2e598b547e8a`, Actions run #85: https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42449791762. Builds succeeded on iPhone SE (3rd generation) and iPhone 16, but tests failed. Each device ran 42 unit tests with 2 failures. iPhone 16 ran 11 UI tests with 3 failures; iPhone SE ran 11 UI tests with 4 failures. Failures and candidate corrections are itemized in `native-ios/QA/REPORT.md`. The iPhone 18 Pro test step was skipped; that device remains **untested**.

**Prior fully green baseline:** run #80, commit `dfd8678efdc354d47aac0e549850a46bae533cdd`: 34 unit + 7 UI = 41/41 on iPhone SE and iPhone 16 (iOS 18.5). This is historical and does not verify the newer changes.

## Current implementation and evidence

### Training

The persistent implementation includes independent flexible program rotations, split editing/reorder, exercise search/custom entries, exercise prescriptions/tracking modes, supersets, session replacement, save/resume, timer recovery, progression acceptance/decline, completion summaries, multiple same-day sessions, historical edits/deletion/recovery and estimated-1RM PR recalculation. Run #85 passed program switching/scheduled-skip, split/editor/search/custom exercise, superset/rest and tracking-mode UI paths; it also passed the active workout/timer and completion/PR-summary path on the devices where those tests completed. The aggregate UI suites failed, so Training is **not fully verified**. The decline UI assertion used a non-stable field query, and SE’s restore assertion checked the first history row instead of the restored session. Stable-ID corrections are in the local candidate. Full rest-day UI, calendar drill-in to multiple same-day records, and recalculation visible after historical edits/deletes still need direct UI acceptance.

### Food and Nutrition

Implemented source includes meal logging/editing; local and public remote search; Canadian Nutrient File/Open Food Facts adapters; barcode lookup with unknown-code/manual fallback; verified serving conversion; manual food correction; independent favorites and recents; recipe create/edit/log; Add/Replace meal/day copy; effective-dated goals and historical snapshots; remaining totals/adherence/trends; hydration and history; offline state persistence; Food History editing and 30-day recovery; and Home-to-Food navigation. The four approved Add Food options remain Search Foods, Scan Barcode, Manual Entry and Recent Foods.

Run #85 executed Food store tests but had two failing test expectations: a legacy recipe fixture omitted its required identifier, and the Add-then-Replace scenario correctly soft-deleted three matching rows while its assertion expected two. Food UI tests exposed a date-picker/swipe gesture collision and an iPhone SE hydration-row lookup failure. The selected-date persistence bug from run #84 is fixed in #85, but the new Food flows have not yet passed as an end-to-end suite. A new trend chart selector and additional copy/recovery UI tests are local candidate changes awaiting CI.

Public CNF/Open Food Facts endpoints require no credential. Live availability, catalog completeness, licensing/attribution review, real barcode-camera recognition on a physical device and exhaustive offline/network-transition behavior remain unverified.

## Visual and device limits

The user accepted the recent Default styling as a provisional working direction only. The exact 2-column × 4-row Home grid, widget geometry, dock and existing themes are preserved; empty workout cells remain empty for shorter programs. No screenshot has been approved as a baseline, and other theme styling has not been propagated. Run #85’s captures are candidate screenshots only; fresh captures will come from the next run.

This Linux environment has no Xcode or Simulator. Simulator builds, tests and screenshots must come from GitHub Actions. HealthKit remains disabled and CI uses isolated synthetic data.

## Next actions

1. Publish the stable UI-test and test-fixture corrections plus Food trend, copy, recipe/water recovery coverage.
2. Run the exact new commit on iPhone SE and iPhone 16; record every test result and artifact. Keep iPhone 18 Pro untested unless its test action actually runs.
3. Fix remaining failures based on logs, repeat until the available-device suite is green, and reconcile `REQUIREMENTS_TRACEABILITY.csv`, `AUDIT_RESULTS.md`, `TRAINING_PHASE2.md` and `REPORT.md` from the executed evidence.
4. Only then report which Training and Food requirements have met their UI and persistence acceptance criteria and choose the next milestone.
