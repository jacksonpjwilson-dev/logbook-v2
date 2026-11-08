# Logbook QA report

## Current app-source and test evidence

**Branch:** `codex/default-theme-gate1`
**App source:** `f4b2cca17b3ba6bab2207783438f2296ffe93083`
**Latest green run #80:** [GitHub Actions](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42430593049), tested commit `dfd8678efdc354d47aac0e549850a46bae533cdd`.
**Prior run #79:** [GitHub Actions](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42429166112), failed only one iPhone 16 UI assertion.

Run #80 built and tested the app on iOS 18.5 simulators. Each available device ran 34 unit + 7 UI tests:

- iPhone SE (3rd generation): **41 passed, 0 failed, 0 skipped**.
- iPhone 16: **41 passed, 0 failed, 0 skipped**.
- iPhone 18 Pro: QA test step skipped; **untested**.

The centered/slow-drop UI-test adjustment passed the drag-and-drop workflow on both available devices. Run #79 remains a recorded failure (40/41 on iPhone 16); #80 establishes the newer fully green app/test baseline. `f4b2cca` is the app-source commit; `dfd8678` changes only the UI test gesture.

## Screenshot gallery

Run #80 produced 24 real iPhone 16 and iPhone SE PNG candidates for Daily, Training, Food, Progress & History, Workout Split Editor, Active Workout, progression, completion and history.

- Gallery HTML: `/workspace/logbook-training-review-run80/index.html`
- Downloadable gallery ZIP: `/workspace/logbook-training-review-run80.zip`

The gallery marks each image **CANDIDATE — NOT APPROVED**. No visual baseline was added or overwritten.

## Visual and requirements status

The Home grid measurements, timer placement and Training drag/reorder assertions passed on both devices in #80. Training Home’s unused positions with a short split are retained per master spec §2.3; the eight-workout fixture fills the same approved geometry. Default appearance and active-workout sheet styling remain pending human visual review.

The supplied handoff contains 26 original theme reference binaries outside the repository. Exact names, categories and repository destination paths are in `docs/handoff-v2/themes/REFERENCE_INDEX.md`. Four Glass images are thumbnail-only. The 16 formerly approved themes were not modified, and no visual candidate is automatically approved.

The Linux environment has no `xcodebuild` or iOS Simulator. CI provides simulator builds and test evidence. HealthKit is disabled; no production config or `main` branch was changed.
