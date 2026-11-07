# Current Logbook milestone

**Current objective:** Complete the remaining Training UI workflows and visual review after preserving the verified simulator baseline. The development framework documented in this milestone is in place; it does not mean the app is beta-complete.

**Development branch:** `codex/default-theme-gate1`  
**Branch head before the framework documentation commit:** `7dd0d6bf8e46cce8f8e9f14e453737d48ede53b`  
**Framework documentation commit:** `6d685ab54199578f923daafa9f80da00ef112425`  
**Last simulator-tested app source commit:** `85783dac2f65767e4d762064df46b9d81cda8c35`  
**Last completed simulator run:** [Daily Home QA #42](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42396256800).

## Verified baseline

On run #42, iPhone 16 and iPhone SE (3rd generation), iOS 18.5, each passed 33 unit tests and 4 UI tests: 37 passed, 0 failed, 0 skipped per device. UI coverage included all four Home captures, Daily subregion navigation, Training split/calendar navigation, and active workout rest-timer persistence through app termination, relaunch and resume. The timer-card stale “Ready” display found in #41 was corrected in `85783da` and passed on both tested simulators.

- [iPhone 16 artifact](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42396256800/artifacts/13584290732)
- [iPhone SE artifact](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42396256800/artifacts/13583373258)
- iPhone 18 Pro was unavailable; its job was skipped and remains **untested**.
- Run #26 failed to compile on iPhone 16 and SE before any tests ran (0 tests). Later fixes were verified by #42.
- The framework commit changed documentation only; it did not change tested app source.
- No screenshot baseline is approved; the Default visual appearance remains awaiting the user's review.

Detailed Training scope, exact tests, measurements and gaps: [`native-ios/QA/TRAINING_PHASE2.md`](../native-ios/QA/TRAINING_PHASE2.md). Audit and full test scope: [`native-ios/QA/AUDIT_RESULTS.md`](../native-ios/QA/AUDIT_RESULTS.md), [`native-ios/QA/REPORT.md`](../native-ios/QA/REPORT.md), and the canonical tracker.

## Current implementation boundary

Training business rules have substantial store-level test coverage. UI-level verification remains for split editing, exercise search/selection, accepting/declining progression, set-entry-to-summary, history editing/recovery, and multi-session details. Training Home's split card still needs visual refinement/review. Default and other Home appearances are not user-approved. Auth/coaching/cloud services and the remaining food/check-in/history workflows remain incomplete or blocked; see tracker.

## Next milestone

Add a focused, deterministic XCUITest set for the remaining Training editing/completion/history workflows; fix issues those tests expose; capture the affected screens on available small and large simulators; update the traceability rows with exact test evidence. Keep Home geometry, existing 16-theme approvals, HealthKit-disabled state, and production settings unchanged. Do not mark visual requirements approved without user acceptance.

## Environment and safety

The Codex execution workspace is Linux and has no Xcode, `xcodebuild`, `xcrun`, or iOS Simulator. Use GitHub Actions' macOS runners or the user's M2 Mac for native simulator verification. Use synthetic QA storage only. No main merge, production configuration changes, or HealthKit access.
