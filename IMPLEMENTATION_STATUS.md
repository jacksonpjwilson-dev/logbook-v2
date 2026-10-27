# Implementation status

Updated 2026-10-27. Authorized branch: **logbook-v2-upgrade only**. No main changes, deployment, production Firebase, real account login or real personal records.

## Current result

Stage 1 storage/legacy integration, Stage 2 Training and Stage 3 Food/Nutrition now have isolated development implementations. They are **not a production release or authorization for real-data migration**. Stage 1/2 CI is green and reviewed. Stage 3 local checks pass; its combined CI is pending. Following the newly authorized next phase, Stage 3 is the current development milestone; Stages 4–6 remain upcoming.

- Existing application integration: `/stage1/dev/` (build with `node stage1/build-dev.cjs`). Lossless raw legacy projection, per-entity batches, verified separate seed archive, visible conflict/restore/Undo and offline reopening.
- New Training implementation: `/stage2/`. Stable identities, template/session snapshots, rotation/events, timers, substitutions, supersets, complete plan history, PRs, corrections, recoverable versions and real-data-only exercise charts.
- Original `preview-widget/index.html`, `app.js`, `data.js`, `sync.js`, `styles.css`, `sw.js`, root entry points and main are unchanged. New workers/cache names are scoped to their development paths and never delete production caches.
- Nutrition implementation: `/stage3/`. Quantity-confirmed food logging, immutable snapshots, safe conversions, saved/copy meals, effective targets/adherence, water events/Undo, corrections and demo sync.
- The supplied Markdown handoff is preserved in `docs/handoff/`. All nine new archives were reviewed: three original sheets plus 19 supporting images. See `docs/handoff/VISUAL_REVIEW.md` and the SHA-256 asset manifest. Stage 3 applies the Food hierarchy with frosted surfaces; final 16-theme/Home appearance remains Stage 5, with no exact-fidelity claim.

## Evidence

- Stage 3 local aggregate: **116 Node checks passed, seven emulator-only checks skipped** in ordinary execution. All seven emulator integration checks passed in the combined run; the new Nutrition browser + emulator test also passed after correcting its script dependency. The ordinary Nutrition Chromium workflow passed; external API responses are synthetic mocked fixtures. Combined GitHub CI is pending.

- Final code commit: `ccfa5e38f8165c624219e59f1d3a106c3d665bcb`. Reviewed final CI: https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/40393997855 — all three jobs passed (104 ordinary Node checks, six actual emulator checks, all six browser scripts).
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
| N01 | `stage3/nutrition-core.js`, `nutrition-records.js`, `app.js` | `stage3-nutrition.test.cjs`, Nutrition Chromium and demo emulator tests | Implemented in isolated development; local tests pass | Fresh combined CI and physical-device acceptance pending. |
| N02 | `stage3/nutrition-core.js`, `nutrition-records.js`, `app.js` | `stage3-nutrition.test.cjs`, Nutrition Chromium and demo emulator tests | Implemented in isolated development; local tests pass | Fresh combined CI and physical-device acceptance pending. |
| N03 | `stage3/nutrition-core.js`, `nutrition-records.js`, `app.js` | `stage3-nutrition.test.cjs`, Nutrition Chromium and demo emulator tests | Implemented in isolated development; local tests pass | Fresh combined CI and physical-device acceptance pending. |
| N04 | `stage3/nutrition-core.js`, `nutrition-records.js`, `app.js` | `stage3-nutrition.test.cjs`, Nutrition Chromium and demo emulator tests | Implemented in isolated development; local tests pass | Fresh combined CI and physical-device acceptance pending. |
| N05 | `stage3/nutrition-core.js`, `nutrition-records.js`, `app.js` | `stage3-nutrition.test.cjs`, Nutrition Chromium and demo emulator tests | Implemented in isolated development; local tests pass | Fresh combined CI and physical-device acceptance pending. |
| N06 | `stage3/nutrition-core.js`, `nutrition-records.js`, `app.js` | `stage3-nutrition.test.cjs`, Nutrition Chromium and demo emulator tests | Implemented in isolated development; local tests pass | Fresh combined CI and physical-device acceptance pending. |
| N07 | `stage3/nutrition-core.js`, `nutrition-records.js`, `app.js` | `stage3-nutrition.test.cjs`, Nutrition Chromium and demo emulator tests | Implemented in isolated development; local tests pass | Fresh combined CI and physical-device acceptance pending. |
| N08 | `stage3/nutrition-core.js`, `nutrition-records.js`, `app.js` | `stage3-nutrition.test.cjs`, Nutrition Chromium and demo emulator tests | Implemented in isolated development; local tests pass | Fresh combined CI and physical-device acceptance pending. |
| N09 | `stage3/nutrition-core.js`, `nutrition-records.js`, `app.js` | `stage3-nutrition.test.cjs`, Nutrition Chromium and demo emulator tests | Implemented in isolated development; local tests pass | Fresh combined CI and physical-device acceptance pending. |
| N10 | `stage3/nutrition-core.js`, `nutrition-records.js`, `app.js` | `stage3-nutrition.test.cjs`, Nutrition Chromium and demo emulator tests | Implemented in isolated development; local tests pass | Fresh combined CI and physical-device acceptance pending. |
| N11 | `stage3/nutrition-core.js`, `nutrition-records.js`, `app.js` | `stage3-nutrition.test.cjs`, Nutrition Chromium and demo emulator tests | Implemented in isolated development; local tests pass | Fresh combined CI and physical-device acceptance pending. |
| N12 | `stage3/nutrition-core.js`, `nutrition-records.js`, `app.js` | `stage3-nutrition.test.cjs`, Nutrition Chromium and demo emulator tests | Implemented in isolated development; local tests pass | Fresh combined CI and physical-device acceptance pending. |
| S01 | Existing legacy application remains intact | Approved replacement behavior not yet fully validated | Pending later phase | No completion claim. |
| S02 | Existing legacy application remains intact | Approved replacement behavior not yet fully validated | Pending later phase | No completion claim. |
| S03 | Existing legacy application remains intact | Approved replacement behavior not yet fully validated | Pending later phase | No completion claim. |
| S04 | Existing legacy application remains intact | Approved replacement behavior not yet fully validated | Pending later phase | No completion claim. |
| W01 | Existing legacy application remains intact | Approved replacement behavior not yet fully validated | Pending later phase | No completion claim. |
| W02 | Existing legacy application remains intact | Approved replacement behavior not yet fully validated | Pending later phase | No completion claim. |
| W03 | Existing legacy application remains intact | Approved replacement behavior not yet fully validated | Pending later phase | No completion claim. |
| U01 | Existing legacy application remains intact | Approved replacement behavior not yet fully validated | Pending later phase | No completion claim. |
| U02 | Existing legacy application remains intact | Approved replacement behavior not yet fully validated | Pending later phase | No completion claim. |
| U03 | Existing legacy application remains intact | Approved replacement behavior not yet fully validated | Pending later phase | No completion claim. |
| U04 | Existing legacy application remains intact | Approved replacement behavior not yet fully validated | Pending later phase | No completion claim. |
| H01 | Existing legacy application remains intact | Approved replacement behavior not yet fully validated | Pending later phase | No completion claim. |
| H02 | Existing legacy application remains intact | Approved replacement behavior not yet fully validated | Pending later phase | No completion claim. |
| H03 | Existing legacy application remains intact | Approved replacement behavior not yet fully validated | Pending later phase | No completion claim. |
| H04 | Existing legacy application remains intact | Approved replacement behavior not yet fully validated | Pending later phase | No completion claim. |
| X01 | `preview-widget/safety-core.js`, `stage1-*.js`, `stage1/dev/`, `stage1/firestore.rules`, `stage2/` | Stage 1/2 Node, Chromium and demo emulator suites | Development coverage; final acceptance partial | Capacity, physical-device and real-data/production gates remain. |
| X02 | Existing legacy application remains intact | Approved replacement behavior not yet fully validated | Pending later phase | No completion claim. |
| X03 | `preview-widget/safety-core.js`, `stage1-*.js`, `stage1/dev/`, `stage1/firestore.rules`, `stage2/` | Stage 1/2 Node, Chromium and demo emulator suites | Development coverage; final acceptance partial | Capacity, physical-device and real-data/production gates remain. |
| X04 | Existing legacy application remains intact | Approved replacement behavior not yet fully validated | Pending later phase | No completion claim. |

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

## Visual and later-phase tracking

Brand/icon/splash, exact 16 themes, four Home pages/dock, 38-widget inventory/gallery/editing, Sleep/Weight/Supplements, full cross-feature History and final iPhone/visual matrices remain later-phase work. No approved requirement was removed or narrowed to an MVP.


## Verified final hardening

Content-addressed record/history staging uses SHA-256 verification and one root-manifest CAS. Interrupted staging never publishes partial state. Actual emulator tests verify >1 MiB snapshots, lost post-commit acknowledgment/no duplicate revision, immutable reuse, chunk ownership and corruption rejection. Canonical equality/order avoids redundant writes/history duplication. Literal prototype-named unknown fields remain data; definition edits retain unknown metadata/equipment. Demo sync failures show context and retain local queues.

No production deployment, real account access, merge or real-data migration occurred. Physical iPhone and formal migration/release gates remain open; later theme/visual phases are not claimed complete.
