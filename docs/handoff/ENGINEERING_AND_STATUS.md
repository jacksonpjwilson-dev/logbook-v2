# Engineering Baseline, Status and Constraints

## Verified repo configuration at handoff
- Repo: `jacksonpjwilson-dev/logbook-v2`, default `main`.
- Development branch: `logbook-v2-upgrade`.
- Main baseline SHA: `278f0936b8a8f8f4b39bd6fbbe2dc72c961b3f32`.
- GitHub compare during handoff: development was 33 commits ahead of main, zero changed/deleted existing paths; all branch changes were additions of Stage 0/1 files and tests. Recheck for newer commits before beginning.
- `preview-widget/index.html` originally loads `lib.js`, `data.js`, `sync.js`, `app.js` and `styles.css`, service worker `sw.js` and manifest. The experimental Stage 1 files are **not loaded by that existing entry point**.
- Existing main app is a large single-file JS architecture (`app.js` ~189k chars), with `data.js` ~3.2k, `sync.js` ~9.2k, `styles.css` ~46k and `lib.js` containing ~158 built-in exercises. Actual code may evolve.

## Existing storage and cloud sync
- `data.js` LocalBackend main user key `lb2w:data9`; session key `lb2w:session`.
- Existing cloud file `sync.js` Firebase Auth/Firestore at collection `logbookV2`, document `{uid}`; record blob field `r`.
- Separate browser keys seen in source: `lb2w:sync`, `lb2w:water`, `lb2w:theme`, `lb2w:pages6`, `lb2w:signedin`, `lb2w:layout`, `lb2w:vr`. Do a fresh exact inventory before implementing migrations.
- Existing sync uses record-timestamp last-write-wins; first sync has special food union behavior. DO NOT rely on it for approved Smart Conflict Detection.
- Service worker uses preview-specific network-first caching, currently w19 in preview sources at baseline.
- Existing preview and an older root-level app co-exist; do not inadvertently deploy or overwrite either.

## Known legacy defects from read-only audit
- Finishing a workout discards unfinished set details from saved session (`app.js` finish flow filters sets to completed with entered weight). Must preserve complete plan snapshot including incomplete sets, with analytics counting only completed working sets.
- Exercise history/prefill often identified by display name rather than permanent stable ID. Rename collisions need careful identity migration.
- Legacy saved meal add flow inserts food entries without mandatory per-item quantity confirmation.
- Historical food logs may reference mutable catalog food definitions and lack immutable nutrition snapshots.
- Rest timer uses an in-memory countdown and is not timestamp-persistent.
- Existing cloud sync may silently overwrite same-record concurrent edits.
- Current widget/theme system does not match finalized default four pages and 16 reference themes.
- Sleep/weight/supplement current implementation is more basic than approved version.
- Direct Apple Health/HealthKit access from a normal browser is not available; treat optional native bridge/import as feasibility-dependent.

## Stage 0 — completed repository prep
- `docs/STAGE0_BASELINE.md`: baseline, storage inventory, safeguards, pending tests.
- `tests/fixtures/legacy-preview.synthetic.json`: fictional synthetic legacy-like records.
- No real data or real Firebase accessed or migrated.

## Stage 1 — partially implemented, NOT signed off
New files on development branch:
- `preview-widget/safety-core.js`: pure record model, three-way conflict detection, snapshots, recovery history, migration plan guards, preservations of unknown legacy fields and explicitly supplied `lb2w:water`, `lb2w:pages6`, `lb2w:theme` sidecars.
- `preview-widget/stage1-store.js`: experimental offline queue and store, conflict review, idempotent edits, serialized async mutations, rollback snapshots; NOT currently integrated into the live UI.
- `preview-widget/stage1-indexeddb.js`: guarded test-only IndexedDB adapter.
- `preview-widget/stage1-emulator.js`: localhost-only synthetic Firestore emulator transport.
- `preview-widget/stage1-sync-controller.js`: experimental emulator-only sync coordinator with optimistic CAS retry.
- `stage1/firebase.json`, `stage1/firestore.rules`: **local emulator only**. Never deploy permissive synthetic emulator rules.
- `stage1/harness.html`: localhost-only IndexedDB smoke test page.
- `.github/workflows/stage1-synthetic.yml`: Node synthetic and Firestore emulator GitHub Actions jobs.
- `tests/stage1-*.test.cjs`, support and fixture files.

**Honest test status:** Previous session ran 27 synthetic test cases in a custom isolated JS execution environment with simulated timers: all 27 passed at that moment. It had NOT confirmed a full native Node test runner, GitHub Actions successful run, headless browser IndexedDB execution, real Firebase emulator run, or iPhone installed PWA. Treat full suite as **UNVERIFIED** until independently executed. Some fixes after that result may be present; rerun everything. Do not convert this note into a claim that Stage 1 is fully validated.

## Stage 1 critical remaining work
1. Run `node --test tests/stage1-*.test.cjs` and inspect CI workflow behavior; fix failures honestly.
2. Run Firebase emulator integration as documented in `stage1/README.md`. Enforce `demo-` project and loopback checks; do not let any test point to `logbook-e784a` production project.
3. Run actual browser IndexedDB test at loopback, including reload, offline, interrupted write, concurrent tabs and storage failures; do not claim Chromium/Safari completion without execution.
4. Audit three-way merge and local store for conflict resurrection, tombstone resurrection, stale acknowledgments, lost updates, compare-and-swap with concurrent edits, race between backup/restore and mutation; improve transaction rules.
5. **Lossless migration**: cover every legacy model field + sidecars and preserve unknown structures without overwrites. Protect ambiguous duplicate IDs; create review mapping. Verify full snapshots, versions, identities, referential integrity, and rollback. Never assign a plausible ID without evidence.
6. Add truly durable version history/backups appropriate for failures and 30-day retention, including deleted records and interrupted restores; validate restoration and undo.
7. Integrate *only in an isolated development test context* with the legacy app, then test visible workflows with synthetic data.
8. Create realistic migration fixtures that reproduce the real legacy schema rather than a guessed approximation; ensure safe handling for null/undefined, dates/timezones, duplicate meals, units, active workout timers and supplement schedules.
9. Establish a real passing CI signal, then document acceptance evidence before proceeding to Stage 2.

## Rollout stages
- Stage 0: repository safety/preparation (done).
- Stage 1: storage, migration, sync, recovery (in progress).
- Stage 2: Training.
- Stage 3: Food/Nutrition.
- Stage 4: Sleep/Weight/Supplements & Check-ins.
- Stage 5: Home/Widgets/Appearance/Settings.
- Stage 6: History, cross-feature consistency, end-to-end testing and release candidate.

## Development authority
User authorizes ordinary implementation across stages **on the development branch** without repeated approval requests, within the approved requirements. Do not use this as authority to merge, deploy, read/migrate real data, or connect development to production Firebase. A release candidate is not a release. Final production deployment requires separate explicit user authorization.
