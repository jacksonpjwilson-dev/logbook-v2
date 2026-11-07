# Logbook QA report

## Last fully green baseline

**Run:** [Daily Home QA #42](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42396256800)  
**Tested app-source commit:** `85783dac2f65767e4d762064df46b9d81cda8c35`  
**Result:** iPhone 16 and iPhone SE (3rd generation), iOS 18.5, each passed 33 unit + 4 UI tests: **37 passed, 0 failed, 0 skipped**. The iPhone 18 Pro step was skipped and remains **untested**.

## Latest completed Training UI attempt

**Run:** [Daily Home QA #66](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42418581935)  
**Commit:** `7492512db7cb1085c90ccee193d376289561f781`  
**Build:** succeeded on iPhone 16 and SE.  
**Unit tests:** 34 passed, 0 failed on each device.  
**UI tests:** 7 cases per device:
- iPhone 16: 4 passed, 3 failed — timer Pause/Resume UI state, history completion-label assertion, and drag-reorder assertion.
- iPhone SE: 3 passed, 4 failed — three set-entry queries did not find fields in the then-current collapsed exercise UI, plus planned-exercise control discovery.
- iPhone 18 Pro: skipped; **untested**.

The test logs showed progression-suggestion acceptance passing on iPhone 16 in runs #65 and #66. Run #65 also passed split reorder, search and custom exercise creation on iPhone 16, though the full run failed. Run #66 demonstrates that UI test coverage is active but not yet reliable/green.

Current source/test fixes are on branch head `5fa556da6da8775d26bffeb5c56cf899f6fd035b`; their simulator run #71 is queued. Do not call these fixes verified until run #71 finishes. The last fully green app-source baseline therefore remains #42.

## Screenshot candidates

All captures are real simulator screenshots with synthetic QA data. None are approved baselines:
- [Run #65 iPhone 16 artifact](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42418302117/artifacts/13593435114)
- [Run #65 iPhone SE artifact](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42418302117/artifacts/13592459439)
- [Run #58 local review gallery](`/workspace/logbook-training-review/index.html`) and [ZIP](`/workspace/logbook-training-review.zip`), containing Daily Home, Training Home with one and eight real fixture workouts, and active-workout initial position. These predate the expanded-first-exercise source fix.

Fresh captures from runs #69–#71 are pending. Keep the exact run, device and commit attached to every screenshot.

## Scope and open work

- Finish iPhone 16 and SE end-to-end UI checks for drag/drop, exercise selection/prescription, set entry, timer pause/resume, progression, completion summary, historical editing and Recently Deleted recovery.
- Capture fresh screenshots of Daily Home, Training Home, active workout set entry and summary/history screens.
- Visually review Default against source art; no screenshot baseline or visual approval has been granted.
- The Training Split screenshot with one actual workout has empty unused positions by design under master spec §2.3. The 8-workout synthetic screenshot fills all eight positions. Do not add fabricated workout tiles.
- iPhone 18 Pro simulator, physical iPhone/Watch, full visual/theme acceptance, non-Training workflows, authentication/coaching/cloud behavior remain unverified or incomplete.

## Automated workflow history

Runs #63–#66 expose the recent UI issues; runs #67–#71 contain sequential accessibility, expanded-exercise, timer, history and test-selector corrections. At the time of this update #67–#68 were active and #69–#71 queued. See [all workflow runs](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/workflows/daily-home-qa.yml).

No HealthKit access, production data/configuration change, main-branch edit, theme redesign or screenshot-baseline approval occurred.
