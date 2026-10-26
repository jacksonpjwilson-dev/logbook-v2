# Quality Gates & Requirement Traceability

Codex must maintain a table for every requirement ID from `FUNCTIONAL_REQUIREMENTS.md` and each major UI requirement from `DESIGN_AND_THEMES.md` with: `ID | Code path | Unit/integration/UI tests | Test result + run URL | Screenshot (if UI) | Status | Notes`.

## Stage 1 release gate (development only)
- [ ] **TST01** Full native Node test suite runs with verified exit status, not only a custom JS runner: `node --test tests/stage1-*.test.cjs`.
- [ ] **TST02** GitHub Actions run is green on `logbook-v2-upgrade` and job logs are reviewed; workflow not skipped/disabled.
- [ ] **TST03** Firestore emulator tests run with `demo-logbook-stage1` or another `demo-` ID and loopback Firestore/Auth; no production credential, URL, account or security rules can be reached.
- [ ] **TST04** Actual browser IndexedDB reload/persistence verified in Chromium and iPhone Safari/installed PWA where possible; power-off equivalent, offline, tab switching, full reload and storage quota/error cases.
- [ ] **TST05** Two concurrent edits to different records merge without dropping either.
- [ ] **TST06** Two conflicting edits to same record remain preserved on both sides and prompt clear side-by-side selection. Resolution stays resolved on next sync.
- [ ] **TST07** Deletion vs edit, tombstone propagation and offline stale device rejoin do not resurrect deleted content silently.
- [ ] **TST08** Queued writes survive interrupted upload, failed durable write, restart, concurrent asynchronous local operations and server CAS failure.
- [ ] **TST09** Migration of every relevant legacy object/sidecar is lossless; ambiguous duplicate ID/name mappings stop for review; no arbitrary guesses; migration rerun is idempotent.
- [ ] **TST10** Verified backup before migration and restore; unchanged original remains recoverable; rollback itself is durable; interrupted migration/restore can be recovered.
- [ ] **TST11** Version history/deletions recoverable for full 30 days with precise time boundary; normal workout/food history is not pruned after 30 days.
- [ ] **TST12** Restoring from another device and resolving concurrent user conflicts preserves unaffected unrelated records. Restore Summary accurately previews changes, includes confirmation and Undo.
- [ ] **TST13** Firestore rules enforce user isolation, authenticated scope and no development-to-production cross-access. Do not deploy synthetic emulator rules.
- [ ] **TST14** Existing `main`, current deployed `preview-widget`, and real personal data untouched; verify with Git compare and workflow/environment inventory.
- [ ] **TST15** Development-only UI integration with fictional data: local add/edit, sync, pending, conflict review, restore/undo and offline reopening. Tests and screenshots exist.

## Stage 2 Training acceptance
- [ ] **TRA01** Rest does not advance rotation; Finish & Save does; Discard doesn't; skipping ahead records skipped positions only; historical correction never silently changes current position.
- [ ] **TRA02** Session snapshot survives template edit, exercise rename and multi-device template update; immutable completed snapshot except explicit versioned correction.
- [ ] **TRA03** Incomplete plan persists into saved history with done flags, but only complete valid working sets count toward analytics and PR.
- [ ] **TRA04** Original/replacement Linked Exercise Cards correctly preserve original performed sets/PRs and separately attribute replacement.
- [ ] **TRA05** Rest countdown and workout manual paused/active/elapsed time survive background/closing, across timestamp changes; resumed banner persists.
- [ ] **TRA06** 1–15 Epley PR rule, 1-rep actual, >15 exclusion only for estimated 1RM; rep-specific PR and heaviest weight; one combined celebration per set; corrections recalculate results.
- [ ] **TRA07** Superset completion/rest semantics, five-column accessible set entry, previous-history prefills never mark done.
- [ ] **TRA08** Workout summary previous-session comparisons only when valid, active/inactive time separate.

## Stage 3 Nutrition acceptance
- [ ] **NUT01** Every Add Food route has explicit quantity review (saved meal per ingredient included); no one-tap silent bypass.
- [ ] **NUT02** Unit conversions reject incompatible/missing factors; no guessed grams per count or density.
- [ ] **NUT03** Food log snapshots do not change when food catalog definitions change; explicit historical correction updates affected analytics.
- [ ] **NUT04** Bulking vs cut/maintenance adherence calculations meet exact 90%, 90–110% calorie / 90% protein rules, effective-dated targets and current-day provisional status.
- [ ] **NUT05** Water quick-add and custom amounts have event identity, date accuracy, no duplicate count, deletion Undo; water excluded from calorie streak.

## Stage 4 Sleep/Weight/Supplements acceptance
- [ ] **SWS01** Sleep wake-date assignment, bed/wake, duration override and goals correct across midnight/time zones.
- [ ] **SWS02** Weight one official per day, original unit preserved, 7-day trend shown only with >=3 actual entries, no fake zeros.
- [ ] **SWS03** Supplement versioned schedules and completed-workout-day rule, explicit Taken doses, correctly denominated adherence, 0-scheduled = satisfied.
- [ ] **SWS04** Once-per-day daily check-in and missing-sleep follow-up respect dismissal and prior records; push/reminders degrade gracefully on iOS.

## Stage 5 Home/UI/Appearance acceptance
- [ ] **UI01** Four correct default pages and exact five-item dock; no Home Screen vertical scroll; widgets are editable/reorderable across pages.
- [ ] **UI02** All 38 types accounted for (Food10 Training10 Body9 History8 Home1) and S/M/L variants where applicable; no clipped values at expected iPhone widths.
- [ ] **UI03** Smart Tidy + Undo and Hybrid Widget Gallery; quick deep actions navigate correctly.
- [ ] **UI04** 16 exact named reference themes with Premium Glass default; each matches original user imagery rather than a generic substitute, verified screenshots.
- [ ] **UI05** Cold-open-only splash, reduced-motion, accessible contrast, smooth widget/app transitions, icon manifest/iPhone home installation.

## Stage 6 acceptance
- [ ] **HIS01** Five history categories and calendar 3 modes; interactive real-data chart ranges including All/custom.
- [ ] **HIS02** Historical changes propagate into every dependent chart/streak/volume/PR without fabricated observations.
- [ ] **E2E01** Installed iPhone PWA, offline, background/reopen, theme persistence, device scaling, sync and service worker update path tested.
- [ ] **E2E02** Data integrity regression passes across all modules and all approved theme combinations.
- [ ] **E2E03** Document limitations, final diff, CI run links, rollback plan, user acceptance issues and release recommendation.
- [ ] **E2E04** Request explicit user authorization to merge/deploy. No automated production release.

## Working cadence
After each significant implementation increment:
1. Commit only development-branch changes.
2. Run focused tests and full applicable suite; capture actual command output/status.
3. Update `IMPLEMENTATION_STATUS.md` with requirement IDs, proof and known limitations.
4. If tests cannot run, mark **Blocked/Unverified** rather than Passed; offer exact setup requirements.
5. Make progress autonomously; only ask user for truly necessary data/reference/permission decisions.
