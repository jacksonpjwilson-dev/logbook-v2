# Logbook QA report

## Latest executed source evidence

**Development branch:** `codex/default-theme-gate1`
**Latest tested commit:** `f04bfdd2d5184a31c99bc41f165d6348b2a7c8f6`
**Actions run #87:** https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42451731246

| Simulator | Build | Unit tests | UI tests | Result |
|---|---|---:|---:|---|
| iPhone SE (3rd generation), macOS 15 | Passed | 42 passed / 1 failed (43 executed) | 9 passed / 4 failed (13 executed) | Failed |
| iPhone 16, macOS 15 | Passed | 42 passed / 1 failed (43 executed) | 8 passed / 5 failed (13 executed) | Failed |
| iPhone 18 Pro, macOS 26 | Availability check only | Not executed | Not executed | Untested; test step skipped |

The common unit failure was `testLegacyNutritionPayloadDecodesWithoutNewFoodFields`: its old `WaterLog` fixture omitted the model's required `id`. The candidate fixture now includes a legacy identifier.

The iPhone 16 UI failures were Food previous-day selection/date swipe, water-goal presentation, the hydration control not entering the accessibility tree during one lazy-list traversal, and progression decline comparing different lazy set fields. iPhone SE had the date and progression failures plus two Food navigation/hydration failures. App and simulator builds succeeded; the test suite did not.

## Training verification

Run #87 passed several Training flows on available simulators: Daily/Training Home navigation, split editing and exercise selection, tracking modes/superset/rest behavior, completion summary/PR presentation, program switch/skip, and history editing/deletion/recovery where those cases completed. Do not count the branch's aggregate suite as passing. The candidate adds an out-of-order-completion UI assertion and binds the progression decline assertion to the same stable set identifier; both await a fresh run.

Store-level coverage in the candidate includes independent program rotations and repository reopen, discard/scheduled completion behavior, persistent active session/rest timer recovery, superset round timing, alternate tracking modes, first-lift PR baseline, and recalculation after historical edit/delete/restore. Exact test outcomes for those sources will be reported from the next CI run, not inferred here.

Open direct UI acceptance includes rest-day display/non-advance, multiple same-day session calendar drill-in, PR recalculation displayed after historical changes, and end-to-end saved-session recovery after app termination.

## Food and Nutrition implementation

The app has real local persistence and navigation for meal logging/editing, exact Search Foods / Scan Barcode / Manual Entry / Recent Foods options, food search, provider provenance, verified serving conversions, manual correction, independent favourites/recents, recipes, meal/day copying with Add/Replace, date-specific goals, calories/macros/adherence, water history, and Recently Deleted recovery. Public Canadian Nutrient File and Open Food Facts adapters are implemented without credential requirements.

The current candidate adds the Default Food Home widgets and their actions: 7-day Calories/Protein/Carbs/Fats trends with historical goals, hydration status/quick add/full log, compact meal rows with direct meal navigation, adherence streak markers and contextual Easy Next. Food routes deep-link into the appropriate list section or exact four-option Add Food menu. This source candidate and its expanded UI coverage have **not yet run** in CI.

## Artifacts and screenshots

Run #87 artifacts are actual Simulator captures and test reports, not approved baselines:

- [iPhone 16 screenshots and test result bundle](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42451731246/artifacts/13606208757)
- [iPhone SE screenshots and test result bundle](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42451731246/artifacts/13605984952)
- [iPhone 18 Pro runner availability report](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42451731246/artifacts/13606187009)

Run #87 measured iPhone 16 Daily Home frames (points): large `268.52 × 268.52` at `(62.24, 176.57)`, medium measured interior `267.5 × 129.25` at approximately `(62.24, 453.24)`, small widgets `130.18 × 130.18` at x `62.24` and `200.57`, dock top y `757.67`. Geometry assertions completed; the approved geometry is unchanged. iPhone SE's captured layout was also measured by the workflow. Candidate captures remain for review and were not accepted as reference baselines.

## Candidate changes awaiting CI

- Consolidate Food-screen modal routes into one typed `.sheet(item:)` presentation, eliminating multiple `.sheet` modifiers on a single List.
- Preserve the required four Add Food choices with distinct sheet identities.
- Make Food date swipe a high-priority gesture on the macro summary surface and give that region an accessibility identifier.
- Wait for day selection to settle in UI assertions and compare the same progression set field before/after declining.
- Add the required identifier to the legacy `WaterLog` fixture, make the UI scroll helper fall back to app-level swipes when no List collection view is exposed, and test out-of-order workout completion.
- Add Food Home trend/hydration/meals/adherence/Easy Next interactions and screenshots.

**Candidate source commit:** pending publication and Actions execution. No local Xcode, Swift compiler or iOS Simulator is available in this Linux workspace, so this report cannot claim local builds or simulator tests.

## Baseline and guardrails

The last fully green source baseline remains run #80, commit `dfd8678efdc354d47aac0e549850a46bae533cdd`: 34 unit + 7 UI tests = 41/41 on iPhone SE and iPhone 16. Run #87 is newer but red. All 16 existing themes and approved Home geometry remain unchanged. The current visual direction is provisional only. HealthKit stays disabled; CI uses isolated synthetic data; no production configuration or `main` branch was modified.
