# Implementation status

Updated 2026-10-27. Authorized branch: **logbook-v2-upgrade only**. No main changes, deployment, production Firebase, real account login or real personal records.

## Current result

Stage 1 storage/legacy integration, Stage 2 Training, Stage 3 Food/Nutrition, Stage 4 Sleep/Check-ins and Stage 5 Home/Appearance now have isolated development implementations. They are **not a production release or authorization for real-data migration**. Stage 1–4 CI is green and reviewed. Stage 5 functionality and local checks are implemented; combined CI is pending. Exact visual approval and physical iPhone acceptance remain open. Stage 6 is upcoming.

- Home development shell: `/stage5/`. Four stable pages, five-app dock, 38 canonical widget IDs plus explicit approved display variants, long-press/cross-page drag, gallery, Tidy/Undo, 16 named theme candidates, Settings and verified synthetic restore. Embedded modules share a new opt-in synthetic store; no standalone fixture is migrated.
- Existing application integration: `/stage1/dev/` (build with `node stage1/build-dev.cjs`). Lossless raw legacy projection, per-entity batches, verified separate seed archive, visible conflict/restore/Undo and offline reopening.
- New Training implementation: `/stage2/`. Stable identities, template/session snapshots, rotation/events, timers, substitutions, supersets, complete plan history, PRs, corrections, recoverable versions and real-data-only exercise charts.
- Original `preview-widget/index.html`, `app.js`, `data.js`, `sync.js`, `styles.css`, `sw.js`, root entry points and main are unchanged. New workers/cache names are scoped to their development paths and never delete production caches.
- Sleep/check-in implementation: `/stage4/`. Wake-date sleep/offsets/override, forward-only goals, official weight/trends, versioned supplement schedules/doses, daily overlay/follow-up and optional reminder fallback. Same-fixture Training records are shared for actual completed-workout-day eligibility.
- Nutrition implementation: `/stage3/`. Quantity-confirmed food logging, immutable snapshots, safe conversions, saved/copy meals, effective targets/adherence, water events/Undo, corrections and demo sync.
- The supplied Markdown handoff is preserved in `docs/handoff/`. All nine new archives were reviewed: three original sheets plus 19 supporting images. See `docs/handoff/VISUAL_REVIEW.md` and the SHA-256 asset manifest. Stage 5 implements all 16 names and a reconstructed wallpaper atlas from those references. Automated screenshots cover every theme/section. Exact scenic artwork and human visual acceptance are not claimed complete; see `stage5/assets/PROVENANCE.md`.

## Evidence

- Stage 5 local aggregate: **149 Node checks passed, nine emulator-only checks skipped** in ordinary execution. Focused actual emulator domain/browser checks passed for independent theme/layout sync, explicit conflicting layouts, preserved typed drafts, immutable Food snapshots and offline rejoin. The functional Chromium suite and visual suite passed: **96 theme/section screenshots**, native swipe, long-press/cross-page pointer movement, **126 widget variants** (38 canonical + four explicit display modes × S/M/L) at 320/390/430px, cold-session splash, reduced motion, and standalone module compatibility is included in the forthcoming combined CI.

- Stage 4 code commit: `a64d5ced0754e173793cf2def90607371b3df503`. Reviewed combined CI: https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/40443987506 — all three jobs passed, including all ten browser scripts and eight actual emulator checks.
- Updated synthetic screenshots: https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/40443987506/artifacts/12707468655 (14-day GitHub retention; includes all five Stage 4 previews).
- Stage 4 local/CI aggregate: **132 Node checks passed, eight emulator-only checks skipped** in ordinary execution. Focused actual emulator domain and browser checks passed for concurrent weights, recovery, schedule snapshots, preserved open drafts and offline rejoin. The new Chromium suite passed for sleep/weight/supplements/daily reminders and actual Training integration. Combined Stage 1–4 CI passed; all three job logs reviewed.

- Stage 3 code commit: `873acc6988fe5fe225f38fab79eed019f0d0732d`. Reviewed combined CI: https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/40440107824 — all three jobs passed, including all eight browser scripts.
- Updated synthetic screenshots: https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/40440107824/artifacts/12705937662 (14-day GitHub retention; includes Nutrition).
- Stage 3 local/CI aggregate: **116 Node checks passed, seven emulator-only checks skipped** in ordinary execution. All seven emulator integration checks passed in the combined run; the new Nutrition browser + emulator test also passed after correcting its script dependency. The ordinary Nutrition Chromium workflow passed; external API responses are synthetic mocked fixtures. Combined GitHub CI passed and all job logs were reviewed.

- Previous Stage 1/2 code commit: `ccfa5e38f8165c624219e59f1d3a106c3d665bcb`. Reviewed final CI: https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/40393997855 — all three jobs passed (104 ordinary Node checks, six actual emulator checks, all six browser scripts).
- Downloadable synthetic previews: https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/40393997855/artifacts/12685531689 (GitHub artifact retention: 14 days).

- Reviewed Stage 1 integration CI: https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/40375539711 — all three jobs passed; logs reviewed.
- Reviewed chunk/retry CI: https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/40385066550 — all three jobs passed; logs reviewed.
- Reviewed Stage 2 CI: https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/40382327475 — all jobs passed; logs reviewed.
- Previous Stage 1/2 local/CI aggregate: **104 Node checks passed, 6 emulator-only checks skipped** in the ordinary offline invocation. The separate real emulator run executes all **6 integration checks successfully**.
- Chromium suites passed locally: storage/workbench; visible legacy integration/offline reopen; Training session/substitution/correction/recovery; Training template/superset/units/picker/charts/reduced-motion.
- Actual browser + local Auth/Firestore suites passed: legacy automatic sync/offline rejoin; Training background-sync typing preservation, explicit conflict choice and resolution persistence.
- Final local regressions also cover merge restore with preserved indexes, rejected conflict-version recovery, immutable account binding, concurrent first connection, fixed built-in exercise identities, workout deletion/Undo, invalid measurement completion clearing, and HTML injection resistance.
- Browser screenshots are generated under ignored `stage1/artifacts/` (legacy integration, Training active/history). No synthetic screenshot values are treated as user records.
- iPhone Safari and installed-PWA device testing: **not run**. No Safari parity or release-readiness claim.

## Material remaining acceptance work

1. Physical iPhone/Safari/PWA background/install/update behavior and final visual matching.
2. Formal migration identity mapping/review for ambiguous legacy arrays and real independent backup verification before any authorized future cutover. Opaque arrays remain lossless and flagged, never guessed.
3. Long-running load/operational coverage and production chunk cleanup. The one-document limit is fixed with immutable chunks and a CAS manifest. Actual emulator tests verify >1 MiB snapshots, interrupted staging, lost acknowledgments and integrity rejection. Explicit item/manifest limits fail closed with local data retained.
4. Production authentication/rules/token lifecycle and deployment require separate work/authorization. Emulator rules must never be deployed.

## Requirement traceability

| ID | Code path | Tests/evidence | Status | Notes |
| --- | --- | --- | --- | --- |
| G01 | Existing legacy application remains intact | Approved replacement behavior not yet fully validated | Pending later phase | No completion claim. |
| G02 | `preview-widget/safety-core.js`, `stage1-*.js`, `stage1/dev/`, `stage1/firestore.rules`, `stage2/` | Stage 1/2 Node, Chromium and demo emulator suites | Development coverage; final acceptance partial | Capacity, physical-device and real-data/production gates remain. |
| G03 | `preview-widget/safety-core.js`, `stage1-*.js`, `stage1/dev/`, `stage1/firestore.rules`, `stage2/` | Stage 1/2 Node, Chromium and demo emulator suites | Development coverage; final acceptance partial | Capacity, physical-device and real-data/production gates remain. |
| G04 | `preview-widget/safety-core.js`, `stage1-*.js`, `stage1/dev/`, `stage1/firestore.rules`, `stage2/` | Stage 1/2 Node, Chromium and demo emulator suites | Development coverage; final acceptance partial | Capacity, physical-device and real-data/production gates remain. |
| G05 | `preview-widget/safety-core.js`, `stage1-*.js`, `stage1/dev/`, `stage1/firestore.rules`, `stage2/` | Stage 1/2 Node, Chromium and demo emulator suites | Development coverage; final acceptance partial | Capacity, physical-device and real-data/production gates remain. |
| G06 | `preview-widget/safety-core.js`, `stage1-*.js`, `stage1/dev/`, `stage1/firestore.rules`, `stage2/` | Stage 1/2 Node, Chromium and demo emulator suites | Development coverage; final acceptance partial | Capacity, physical-device and real-data/production gates remain. |
| G07 | `preview-widget/safety-core.js`, `stage1-*.js`, `stage1/dev/`, `stage1/firestore.rules`, `stage2/` | Stage 1/2 Node, Chromium and demo emulator suites | Development coverage; final acceptance partial | Capacity, physical-device and real-data/production gates remain. |
| G08 | Existing legacy application remains intact | Approved replacement behavior not yet fully validated | Pending later phase | No completion claim. |
| G09 | `preview-widget/safety-core.js`, `stage1-*.js`, `stage1/dev/`, `stage1/firestore.rules`, `stage2/` | Stage 1/2 Node, Chromium and demo emulator suites | Development coverage; final acceptance partial | Capacity, physical-device and real-data/production gates remain. |
| T01 | `stage2/training-core.js`, `training-records.js`, `app.js` | `tests/stage2-training.test.cjs`, `stage2-records.test.cjs`, Stage 2 Chromium/emulator suites | Implemented in development; local tests pass | CI passed/logs reviewed; physical-device acceptance pending. |
| T02 | `stage2/training-core.js`, `training-records.js`, `app.js` | `tests/stage2-training.test.cjs`, `stage2-records.test.cjs`, Stage 2 Chromium/emulator suites | Implemented in development; local tests pass | CI passed/logs reviewed; physical-device acceptance pending. |
| T03 | `stage2/training-core.js`, `training-records.js`, `app.js` | `tests/stage2-training.test.cjs`, `stage2-records.test.cjs`, Stage 2 Chromium/emulator suites | Implemented in development; local tests pass | CI passed/logs reviewed; physical-device acceptance pending. |
| T04 | `stage2/training-core.js`, `training-records.js`, `app.js` | `tests/stage2-training.test.cjs`, `stage2-records.test.cjs`, Stage 2 Chromium/emulator suites | Implemented in development; local tests pass | CI passed/logs reviewed; physical-device acceptance pending. |
| T05 | `stage2/training-core.js`, `training-records.js`, `app.js` | `tests/stage2-training.test.cjs`, `stage2-records.test.cjs`, Stage 2 Chromium/emulator suites | Implemented in development; local tests pass | CI passed/logs reviewed; physical-device acceptance pending. |
| T06 | `stage2/training-core.js`, `training-records.js`, `app.js` | `tests/stage2-training.test.cjs`, `stage2-records.test.cjs`, Stage 2 Chromium/emulator suites | Implemented in development; local tests pass | CI passed/logs reviewed; physical-device acceptance pending. |
| T07 | `stage2/training-core.js`, `training-records.js`, `app.js` | `tests/stage2-training.test.cjs`, `stage2-records.test.cjs`, Stage 2 Chromium/emulator suites | Implemented in development; local tests pass | CI passed/logs reviewed; physical-device acceptance pending. |
| T08 | `stage2/training-core.js`, `training-records.js`, `app.js` | `tests/stage2-training.test.cjs`, `stage2-records.test.cjs`, Stage 2 Chromium/emulator suites | Implemented in development; local tests pass | CI passed/logs reviewed; physical-device acceptance pending. |
| T09 | `stage2/training-core.js`, `training-records.js`, `app.js` | `tests/stage2-training.test.cjs`, `stage2-records.test.cjs`, Stage 2 Chromium/emulator suites | Implemented in development; local tests pass | CI passed/logs reviewed; physical-device acceptance pending. |
| T10 | `stage2/training-core.js`, `training-records.js`, `app.js` | `tests/stage2-training.test.cjs`, `stage2-records.test.cjs`, Stage 2 Chromium/emulator suites | Implemented in development; local tests pass | CI passed/logs reviewed; physical-device acceptance pending. |
| T11 | `stage2/training-core.js`, `training-records.js`, `app.js` | `tests/stage2-training.test.cjs`, `stage2-records.test.cjs`, Stage 2 Chromium/emulator suites | Implemented in development; local tests pass | CI passed/logs reviewed; physical-device acceptance pending. |
| T12 | `stage2/training-core.js`, `training-records.js`, `app.js` | `tests/stage2-training.test.cjs`, `stage2-records.test.cjs`, Stage 2 Chromium/emulator suites | Implemented in development; local tests pass | CI passed/logs reviewed; physical-device acceptance pending. |
| T13 | `stage2/training-core.js`, `training-records.js`, `app.js` | `tests/stage2-training.test.cjs`, `stage2-records.test.cjs`, Stage 2 Chromium/emulator suites | Implemented in development; local tests pass | CI passed/logs reviewed; physical-device acceptance pending. |
| T14 | `stage2/training-core.js`, `training-records.js`, `app.js` | `tests/stage2-training.test.cjs`, `stage2-records.test.cjs`, Stage 2 Chromium/emulator suites | Implemented in development; local tests pass | CI passed/logs reviewed; physical-device acceptance pending. |
| T15 | `stage2/training-core.js`, `training-records.js`, `app.js` | `tests/stage2-training.test.cjs`, `stage2-records.test.cjs`, Stage 2 Chromium/emulator suites | Implemented in development; local tests pass | CI passed/logs reviewed; physical-device acceptance pending. |
| T16 | `stage2/training-core.js`, `training-records.js`, `app.js` | `tests/stage2-training.test.cjs`, `stage2-records.test.cjs`, Stage 2 Chromium/emulator suites | Implemented in development; local tests pass | CI passed/logs reviewed; physical-device acceptance pending. |
| T17 | `stage2/training-core.js`, `training-records.js`, `app.js` | `tests/stage2-training.test.cjs`, `stage2-records.test.cjs`, Stage 2 Chromium/emulator suites | Implemented in development; local tests pass | CI passed/logs reviewed; physical-device acceptance pending. |
| T18 | `stage2/training-core.js`, `training-records.js`, `app.js` | `tests/stage2-training.test.cjs`, `stage2-records.test.cjs`, Stage 2 Chromium/emulator suites | Implemented in development; local tests pass | CI passed/logs reviewed; physical-device acceptance pending. |
| T19 | `stage2/training-core.js`, `training-records.js`, `app.js` | `tests/stage2-training.test.cjs`, `stage2-records.test.cjs`, Stage 2 Chromium/emulator suites | Implemented in development; local tests pass | CI passed/logs reviewed; physical-device acceptance pending. |
| N01 | `stage3/nutrition-core.js`, `nutrition-records.js`, `app.js` | `stage3-nutrition.test.cjs`, Nutrition Chromium and demo emulator tests | Implemented in isolated development; local tests pass | Combined CI passed/logs reviewed; physical-device acceptance pending. |
| N02 | `stage3/nutrition-core.js`, `nutrition-records.js`, `app.js` | `stage3-nutrition.test.cjs`, Nutrition Chromium and demo emulator tests | Implemented in isolated development; local tests pass | Combined CI passed/logs reviewed; physical-device acceptance pending. |
| N03 | `stage3/nutrition-core.js`, `nutrition-records.js`, `app.js` | `stage3-nutrition.test.cjs`, Nutrition Chromium and demo emulator tests | Implemented in isolated development; local tests pass | Combined CI passed/logs reviewed; physical-device acceptance pending. |
| N04 | `stage3/nutrition-core.js`, `nutrition-records.js`, `app.js` | `stage3-nutrition.test.cjs`, Nutrition Chromium and demo emulator tests | Implemented in isolated development; local tests pass | Combined CI passed/logs reviewed; physical-device acceptance pending. |
| N05 | `stage3/nutrition-core.js`, `nutrition-records.js`, `app.js` | `stage3-nutrition.test.cjs`, Nutrition Chromium and demo emulator tests | Implemented in isolated development; local tests pass | Combined CI passed/logs reviewed; physical-device acceptance pending. |
| N06 | `stage3/nutrition-core.js`, `nutrition-records.js`, `app.js` | `stage3-nutrition.test.cjs`, Nutrition Chromium and demo emulator tests | Implemented in isolated development; local tests pass | Combined CI passed/logs reviewed; physical-device acceptance pending. |
| N07 | `stage3/nutrition-core.js`, `nutrition-records.js`, `app.js` | `stage3-nutrition.test.cjs`, Nutrition Chromium and demo emulator tests | Implemented in isolated development; local tests pass | Combined CI passed/logs reviewed; physical-device acceptance pending. |
| N08 | `stage3/nutrition-core.js`, `nutrition-records.js`, `app.js` | `stage3-nutrition.test.cjs`, Nutrition Chromium and demo emulator tests | Implemented in isolated development; local tests pass | Combined CI passed/logs reviewed; physical-device acceptance pending. |
| N09 | `stage3/nutrition-core.js`, `nutrition-records.js`, `app.js` | `stage3-nutrition.test.cjs`, Nutrition Chromium and demo emulator tests | Implemented in isolated development; local tests pass | Combined CI passed/logs reviewed; physical-device acceptance pending. |
| N10 | `stage3/nutrition-core.js`, `nutrition-records.js`, `app.js` | `stage3-nutrition.test.cjs`, Nutrition Chromium and demo emulator tests | Implemented in isolated development; local tests pass | Combined CI passed/logs reviewed; physical-device acceptance pending. |
| N11 | `stage3/nutrition-core.js`, `nutrition-records.js`, `app.js` | `stage3-nutrition.test.cjs`, Nutrition Chromium and demo emulator tests | Implemented in isolated development; local tests pass | Combined CI passed/logs reviewed; physical-device acceptance pending. |
| N12 | `stage3/nutrition-core.js`, `nutrition-records.js`, `app.js` | `stage3-nutrition.test.cjs`, Nutrition Chromium and demo emulator tests | Implemented in isolated development; local tests pass | Combined CI passed/logs reviewed; physical-device acceptance pending. |
| S01 | `stage4/checkins-core.js`, `checkins-records.js`, `app.js`, `sw.js` | `stage4-checkins.test.cjs`, Stage 4 Chromium/demo emulator suites | Implemented in isolated development; local checks pass | Combined CI passed/logs reviewed; physical-device acceptance pending. |
| S02 | `stage4/checkins-core.js`, `checkins-records.js`, `app.js`, `sw.js` | `stage4-checkins.test.cjs`, Stage 4 Chromium/demo emulator suites | Implemented in isolated development; local checks pass | Combined CI passed/logs reviewed; physical-device acceptance pending. |
| S03 | `stage4/checkins-core.js`, `checkins-records.js`, `app.js`, `sw.js` | `stage4-checkins.test.cjs`, Stage 4 Chromium/demo emulator suites | Implemented in isolated development; local checks pass | Combined CI passed/logs reviewed; physical-device acceptance pending. |
| S04 | `stage4/checkins-core.js`, `checkins-records.js`, `app.js`, `sw.js` | `stage4-checkins.test.cjs`, Stage 4 Chromium/demo emulator suites | Implemented in isolated development; local checks pass | Combined CI passed/logs reviewed; physical-device acceptance pending. |
| W01 | `stage4/checkins-core.js`, `checkins-records.js`, `app.js`, `sw.js` | `stage4-checkins.test.cjs`, Stage 4 Chromium/demo emulator suites | Implemented in isolated development; local checks pass | Combined CI passed/logs reviewed; physical-device acceptance pending. |
| W02 | `stage4/checkins-core.js`, `checkins-records.js`, `app.js`, `sw.js` | `stage4-checkins.test.cjs`, Stage 4 Chromium/demo emulator suites | Implemented in isolated development; local checks pass | Combined CI passed/logs reviewed; physical-device acceptance pending. |
| W03 | `stage4/checkins-core.js`, `checkins-records.js`, `app.js`, `sw.js` | `stage4-checkins.test.cjs`, Stage 4 Chromium/demo emulator suites | Implemented in isolated development; local checks pass | Combined CI passed/logs reviewed; physical-device acceptance pending. |
| U01 | `stage4/checkins-core.js`, `checkins-records.js`, `app.js`, `sw.js` | `stage4-checkins.test.cjs`, Stage 4 Chromium/demo emulator suites | Implemented in isolated development; local checks pass | Combined CI passed/logs reviewed; physical-device acceptance pending. |
| U02 | `stage4/checkins-core.js`, `checkins-records.js`, `app.js`, `sw.js` | `stage4-checkins.test.cjs`, Stage 4 Chromium/demo emulator suites | Implemented in isolated development; local checks pass | Combined CI passed/logs reviewed; physical-device acceptance pending. |
| U03 | `stage4/checkins-core.js`, `checkins-records.js`, `app.js`, `sw.js` | `stage4-checkins.test.cjs`, Stage 4 Chromium/demo emulator suites | Implemented in isolated development; local checks pass | Combined CI passed/logs reviewed; physical-device acceptance pending. |
| U04 | `stage4/checkins-core.js`, `checkins-records.js`, `app.js`, `sw.js` | `stage4-checkins.test.cjs`, Stage 4 Chromium/demo emulator suites | Implemented in isolated development; local checks pass | Combined CI passed/logs reviewed; physical-device acceptance pending. |
| H01 | Existing legacy application remains intact | Approved replacement behavior not yet fully validated | Pending later phase | No completion claim. |
| H02 | Existing legacy application remains intact | Approved replacement behavior not yet fully validated | Pending later phase | No completion claim. |
| H03 | Existing legacy application remains intact | Approved replacement behavior not yet fully validated | Pending later phase | No completion claim. |
| H04 | Existing legacy application remains intact | Approved replacement behavior not yet fully validated | Pending later phase | No completion claim. |
| X01 | `preview-widget/safety-core.js`, `stage1-*.js`, `stage1/dev/`, `stage1/firestore.rules`, `stage2/` | Stage 1/2 Node, Chromium and demo emulator suites | Development coverage; final acceptance partial | Capacity, physical-device and real-data/production gates remain. |
| X02 | Existing legacy application remains intact | Approved replacement behavior not yet fully validated | Pending later phase | No completion claim. |
| X03 | `preview-widget/safety-core.js`, `stage1-*.js`, `stage1/dev/`, `stage1/firestore.rules`, `stage2/` | Stage 1/2 Node, Chromium and demo emulator suites | Development coverage; final acceptance partial | Capacity, physical-device and real-data/production gates remain. |
| X04 | `stage5/app.js`, Settings and module bridge | Stage 5 UI search/deep navigation plus standalone regression suites | Implemented in development | Data & Backup snapshot restore retains current recovery history; archived metadata is preserved independently. |

## Stage 1 acceptance

| Gate | Evidence/status |
| --- | --- |
| TST01 | Native Node suite executed, verified exit 0. |
| TST02 | Final Stage 1/2 CI green; all job logs reviewed; run 40393997855. |
| TST03 | Demo-only loopback Auth/Firestore integration passed. |
| TST04 | Chromium reload/offline/IDB/concurrent tabs/quota/abort passed; physical iPhone pending. |
| TST05 | Independent local/cloud record edits merge in Node, Chromium and actual emulators. |
| TST06 | Visible side-by-side choice and no repeated conflict after resolution pass. |
| TST07 | Tombstone/edit stale rejoin preserves explicit conflict; fresh-device deletion recovery passes. |
| TST08 | Durable queue/restart/failed writes/CAS/offline rejoin covered; interrupted staging and lost post-commit acknowledgment tested; extended long-running load remains pending. |
| TST09 | Actual legacy seed/unknown fields/order/sidecars roundtrip; duplicate/missing IDs preserved and flagged/blocked as appropriate. Formal real mapping pending. |
| TST10 | SHA-256/readback backup, rollback, failed target transaction and stale in-flight restore coverage pass for synthetic data. |
| TST11 | Inclusive 30-day recovery boundary and indefinite ordinary records tested; >1 MiB chunked snapshots verified; long-running operational capacity/cleanup remains pending. |
| TST12 | Restore preview/confirmation/targeted Undo preserves unrelated records; device-scale restore stress pending. |
| TST13 | Actual emulator ownership/revision/anonymous/other-user/production-collection denial pass; production security not changed. |
| TST14 | Main and original app entry points/sync/workers untouched; no deployment workflow invoked. |
| TST15 | Visible legacy app integration, demo sync, pending, conflicts, restore/Undo, offline reopening pass. |

## Stage 2 acceptance

| Gate | Evidence/status |
| --- | --- |
| TRA01 | Rest/discard/finish/skip/history correction/explicit adjustment covered in core and UI tests. |
| TRA02 | Permanent template versions and active/completed snapshot isolation covered, including real emulator rename. |
| TRA03 | All planned/unfinished/omitted sets retained; completed working sets alone drive volume/PR. |
| TRA04 | Linked original/replacement cards preserve separate exercise IDs and volume/PR attribution. |
| TRA05 | Timestamp rest, manual pause/active/elapsed, offline Home/Resume and clock reversal covered; physical iPhone pending. |
| TRA06 | 1-rep actual / 1–15 Epley / 16+ actual-rep records, consolidated celebration and corrected downstream PRs covered. |
| TRA07 | Unified superset/round rest, 320/390/430px five-column entry and uncompleted prefills covered. |
| TRA08 | Conservative equivalent-session comparison and separate active/elapsed/paused duration covered. |

All Stage 2 gates above have development test evidence; they are not a blanket release signoff.

## Stage 3 acceptance

| Gate | Evidence/status |
| --- | --- |
| NUT01 | All picker routes open explicit quantity review. Saved/copy meals require each ingredient; cancellation is atomic. Chromium covers recent/favorites/manual/saved/copy/external/barcode paths. |
| NUT02 | Exact mass/volume families only; cross-family/count needs explicit food factors. Missing external macros and unreviewed per-100 basis rejected. |
| NUT03 | Catalog/saved-meal edits preserve old snapshots; explicit corrections recalculate totals. Unit, UI and actual emulator evidence. |
| NUT04 | Exact bulk/cut/maintenance boundaries, effective dates, missing/provisional days and corrected streaks covered. Target identities are deterministic by effective date to retain concurrent conflict choices. |
| NUT05 | Water uses permanent mL events/local dates, duplicate guard, deletion/restore and no nutrition streak contribution. UI/offline/emulator coverage. |

The development Food screen includes calorie/macro summary, shortcuts, meal disclosures, top/meal/floating Add, search, live previews and source detail. Its screenshot is `stage1/artifacts/stage3-food.png` (synthetic). No live external product lookup, physical iPhone or real-data migration was used for testing.

## Stage 4 acceptance

| Gate | Evidence/status |
| --- | --- |
| SWS01 | Explicit bed/wake UTC offsets, DST fall/spring and travel, wake-date attribution, elapsed versus explicit override, correction/recovery, actual-only chart and permanent forward goals tested. Synced overlapping episodes are retained/flagged and excluded until reviewed. |
| SWS02 | Date-based official identity, exact lb/kg conversion and original unit retention, explicit replacement, stale conflicting values preserved, deletion/Undo, >=3 actual trailing-week trend, keyboard chart and offline entry tested. |
| SWS03 | Permanent effective schedule IDs and original label/slot snapshots; real Stage 2 completion enables workout-day doses, rest/skip does not. Explicit Taken only, dose denominator, historical correction and zero-scheduled satisfaction tested. |
| SWS04 | Atomic initial overlay claim across tabs, persisted dismissal, one nonmodal midday follow-up, optional local-time/quiet/once reminder, explicit permission request and denied-notification in-app fallback tested. Physical OS/iPhone delivery remains unverified; no background guarantee. |

The combined overview has a large Sleep section and side-by-side Weight/Supplements cards with dedicated dashboards. Synthetic screenshots: `stage1/artifacts/stage4-overview.png`, `stage4-sleep.png`, `stage4-sleep-timeline.png`, `stage4-weight.png`, `stage4-supplements.png`. Runtime notifications are optional; tests send none.

## Stage 5 acceptance

| Gate | Code / evidence | Status / limits |
| --- | --- | --- |
| UI01 | `stage5/home-core.js`, `app.js`, `styles.css`; four exact pages, five dock destinations, native touch swipe, page editing and no Home overflow at 320×568/390×844/430×932 | Local automated checks pass; physical iPhone pending. |
| UI02 | `stage5/widgets.js`, `legacy-widget-inventory.json`, `docs/handoff/WIDGET_INVENTORY_STAGE5.md`; all 38 original IDs and 10/10/9/8/1 families, 126 size/display variants rendered | Canonical absent fibre/clocks/circumference/HealthKit sources remain explicitly unknown/unconnected; approved default variants use actual data. No fake substitutes. |
| UI03 | Long press, wiggle, pointer edge-dwell/cross-page move; keyboard placement dialog; searchable categorized gallery, size picker, Tidy preview/Apply and guarded exact Undo | Local Node/Chromium/emulator checks pass; fresh combined CI pending. |
| UI04 | `stage5/themes.js`, generated reference wallpaper atlas; exact 16 names, Premium Glass default, Preview/Cancel/Apply, propagation to embedded apps, contrast checks, 96 screenshots | Runtime implementation tested. Atlas is a reconstruction, not original wallpaper files; exact reference matching/human visual approval remains **open**. |
| UI05 | SVG/180/192/512 icons, manifest/scoped workers, prepared offline module opening; 3-second cold tab-session splash, no reload replay, reduced-motion suppression | Chromium tested. Physical iPhone install/update/cold-process signals, full OS accessibility and device acceptance remain **unverified**. |

### Settings and data boundaries

Appearance / Home Screen / Fitness & Nutrition / Tracking Preferences / Data & Backup have search and meaningful deep actions. All Home data comes from a new opt-in shared synthetic store; existing standalone Stage 2/3/4 fixtures keep their separate data. No automatic migration occurs. The original root/preview production entry points are unchanged.

Verified backup archives include record snapshots plus independent archived recovery/conflict metadata, never session/account tokens. Snapshot restore previews merge/replace category changes and resurrection counts, validates against current records, requires confirmation and provides persistent targeted Undo. It retains the current store's recovery history; it does **not** automatically import archived history/conflict metadata. This limitation is shown in the restore UI and README.

The 96 `stage5-theme-<theme>-<section>.png` screenshots cover Home / Training / Food / Check-ins / History / Settings. They contain explicitly synthetic QA records created through the same domain operations, not user data or invented analytics points. Detailed source/asset provenance and widget source gaps are documented. Human reference approval is still required before claiming exact visual fidelity.

## Visual and later-phase tracking

Complete cross-feature History/calendar, release validation, final exact visual acceptance and physical iPhone testing remain Stage 6. Home/icon/splash/theme runtime, widget inventory/gallery/editing and the automated screenshot matrix are implemented; none is a production release or exact-fidelity certificate. No approved requirement was removed or narrowed to an MVP.


## Verified final hardening

Content-addressed record/history staging uses SHA-256 verification and one root-manifest CAS. Interrupted staging never publishes partial state. Actual emulator tests verify >1 MiB snapshots, lost post-commit acknowledgment/no duplicate revision, immutable reuse, chunk ownership and corruption rejection. Canonical equality/order avoids redundant writes/history duplication. Literal prototype-named unknown fields remain data; definition edits retain unknown metadata/equipment. Demo sync failures show context and retain local queues.

No production deployment, real account access, merge or real-data migration occurred. Physical iPhone and formal migration/release gates remain open; later theme/visual phases are not claimed complete.
