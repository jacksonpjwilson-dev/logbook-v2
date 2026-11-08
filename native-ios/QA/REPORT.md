# Logbook QA report — Training and Food/Nutrition

**Run:** [Actions #126](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42496892834)  
**Branch / tested commit:** `codex/default-theme-gate1` / `074ab167f4ea6826f6d9a7c5536257ea2c1bd395`  
**Result:** Successful on iPhone SE and iPhone 16; iPhone 18 Pro app tests were skipped and remain untested.

| Simulator | Build | Unit | UI | Result |
|---|---|---:|---:|---|
| iPhone SE (3rd generation) | Passed | 50/50 | 13/13 | Passed |
| iPhone 16 | Passed | 50/50 | 13/13 | Passed |
| iPhone 18 Pro | Availability check passed | Not run | Not run | Untested |

## Coverage and findings

The Training UI and store tests passed for rotation/program switching/skip/out-of-order behavior, split editor and exercise search/customization, supersets and tracking modes, progression accept/decline, active workout/rest timer, termination recovery, completion summary/PRs, history editing, deletion and recovery.

Food/Nutrition tests passed for the exact four entry paths, search/manual entry, portion confirmation and correction, barcode unknown fallback, meal history/recovery, nutrition targets, trends/adherence, hydration, recipes/favorites/recents, and Add/Replace meal copy. Run #125 exposed an iPhone 16 navigation failure: the horizontal day-swipe gesture covered the whole Food list. The gesture was scoped to the macro summary and #126 passed Food History navigation on both devices.

Automated provider tests use controlled responses and verify CNF/Open Food Facts parsing, provider fallback and cached-data persistence. Live provider availability/terms/data completeness and network-loss behavior were not tested. Physical camera scanning was not tested; manual barcode entry and unknown-code fallback were tested. No API credentials are required.

## Screenshot artifacts

Actual Simulator screenshots are included in these per-device artifacts; they are candidates for review only and do not approve or overwrite visual baselines:

- [iPhone SE artifact](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42496892834/artifacts/13624920583)
- [iPhone 16 artifact](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42496892834/artifacts/13624832311)
- [iPhone 18 Pro availability artifact](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42496892834/artifacts/13624205975)

The UI test attaches screenshots for all four Home pages and key Training and Food flows. The approved grid geometry and all 16 themes were preserved; Default visuals remain provisional.

## Remaining checks

- Add a focused UI assertion for Food’s compact date picker.
- Verify live CNF/Open Food Facts requests and provider terms on a connected device.
- Verify physical camera scanning and camera permission fallback.
- Run on iPhone 18 Pro when that simulator is available.
- Continue with Sleep, Weight, Supplements, Habits and broader History.

Tests use synthetic QA data. HealthKit remains disabled; production configuration and `main` were not changed.