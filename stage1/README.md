# Isolated Stage 1 Firebase emulator tests

Only a **demo-** project ID is permitted. Do not insert production Firebase credentials.

The existing preview app, `preview-widget/index.html`, does **not** load the Stage 1 modules.

From the repository root, with Node 22 and Firebase CLI installed:

```sh
node --test tests/stage1-*.test.cjs
firebase emulators:exec --project demo-logbook-stage1 --config stage1/firebase.json --only firestore,auth "node --test tests/stage1-firestore-emulator.test.cjs"
```

The Firestore emulator test checks revision-precondition failure on stale writes using HTTP REST.
The in-memory and disk tests check the app's three-way merge, persisted synthetic queue, version history, and rollback primitives. The isolated development UI connects to local demo authentication; production sign-in is outside this build. Emulator rules allow synthetic data for local testing **only**; do not deploy them.

## Local browser persistence smoke test

Serve the repository on loopback only, for example:

```sh
python3 -m http.server 8765 --bind 127.0.0.1
```

Open `http://127.0.0.1:8765/stage1/harness.html` and run the IndexedDB persistence test. It creates synthetic-only keys in the isolated `logbook-v2-stage1-browser-smoke` database; it never loads existing application data, Firebase scripts, or real accounts.

## Acceptance limits

These are **experimental modules**, not yet wired into the existing `preview-widget/index.html`. Do not migrate real browser data using this build. No production service worker, Firestore project, or live deployment was modified. Reviewed emulator CI is recorded in IMPLEMENTATION_STATUS.md; physical iPhone PWA behavior still needs validation.

## Hardening milestone (2026-10-26)

Use `node --test --experimental-test-isolation=none tests/stage1-*.test.cjs` to see individual test results on Node 22+.

Actual browser regression:

```sh
npm install --prefix /tmp/logbook-tools playwright-core@1.64.1
# In a separate terminal, serve this repository:
python3 -m http.server 8765 --bind 127.0.0.1
NODE_PATH=/tmp/logbook-tools/node_modules CHROMIUM_PATH=/usr/bin/chromium node tests/stage1-browser.cjs
```

`stage1/workbench.html` is an isolated, loopback-only synthetic storage UI. It uses real IndexedDB but a clearly labeled local cloud simulation, not Firebase or production data. It covers explicit side-by-side conflict review, backup, restore preview/confirmation and Undo. CSP denies all outgoing connections. It does not replace the legacy app or satisfy full legacy-app integration acceptance.

Emulator tests now create fictional anonymous users in the **local Auth emulator**, and check authenticated ownership, other-account/anonymous denial, revision rules, stale write preconditions and denial of the production collection. The rules remain **emulator only and must never be deployed**. To require execution rather than allow a skip:

```sh
firebase emulators:exec --project demo-logbook-stage1 --config stage1/firebase.json --only firestore,auth "LOGBOOK_REQUIRE_EMULATORS=1 node --test --experimental-test-isolation=none tests/stage1-firestore-emulator.test.cjs"
```

The emulator REST test uses a JSON `documents:commit` write precondition. The earlier query-string PATCH test failed against the actual emulator and was replaced; the passing result covers the exercised commit API.

`stage1-migration.js` accepts only explicitly supplied fixtures; it does not discover/read user browser storage. It writes a separate full-source backup and verifies SHA-256 plus exact readback before migration. Duplicate identities remain blocked for review. Local rollback histories are durable, and recoverable versions now synchronize atomically with records. Full migration mapping/integration and broader interruption/retention stress coverage still need acceptance work. See `IMPLEMENTATION_STATUS.md` for current Training progress and remaining cutover gates.


## Demo-only authenticated REST transport

`preview-widget/stage1-rest-transport.js` creates anonymous users only against the explicitly selected loopback Auth emulator. It uses no Firebase SDK or production config, rejects non-demo projects and non-loopback endpoints before any request, and rejects redirects. Devices can explicitly share the returned synthetic session in emulator tests. Do not log the session token. The isolated UI persists its synthetic demo session in its own namespace; production authentication is unsupported.

Records and recovery history use immutable verified chunks with an update-time/existence precondition on the manifest publication. The integration test runs two independent local stores against this real emulator transport, resolves a same-record conflict, deletes a record, and checks that a fresh third store recovers its prior versions.

## Isolated integration with the existing application

Build with `node stage1/build-dev.cjs`, serve on loopback, and open `http://127.0.0.1:8765/stage1/dev/?fixture=example`. The query selects a synthetic namespace. The build extracts the actual legacy seed using an in-memory storage stub, strips original worker/update code, rewrites storage to a synthetic facade, awaits durable app mutations, and disables imports/resets. Markers fail closed when source changes unexpectedly. Generated files are ignored and rebuilt by CI. Production source files are unchanged.

The bridge projects unambiguous IDs into individual versioned records. Missing/duplicate identities stay intact and flagged; IDs are never guessed from names. Ordering, unknown fields and raw snapshots are preserved. Independent edits merge atomically and competing edits require visible review. The seed has a separate SHA-256 archive. Synthetic backups have restore previews, confirmation and targeted Undo; in-flight writes invalidate stale choices.

The development worker scope is `/stage1/dev/`, cache `logbook-stage1-synthetic-dev-v1`. It never unregisters production workers or reads/deletes their caches. Chromium offline reopen and unfinished-set recovery pass; iPhone/installed-PWA behavior remains unverified.

The banner can explicitly connect to local demo Auth/Firestore. CSP permits same-origin assets and loopback ports 8080/9099 only. Real accounts/imports are disabled. Browser+emulator tests cover automatic sync, offline edit/rejoin, reload and deleted-version recovery. Production authentication/token refresh and final migration/device acceptance remain outside this milestone.

Run the visible integration with `NODE_PATH=/tmp/logbook-tools/node_modules node tests/stage1-legacy-browser.cjs`. Run `tests/stage1-legacy-emulator-browser.cjs` inside the documented demo-only `emulators:exec` command, with the same NODE_PATH and HTTP server running. CI builds and runs both.

## Chunked demo snapshots and retry safety

The REST transport stages immutable, SHA-256-verified record/history chunks and publishes a small revision-controlled manifest. Default chunks target 192 KiB; a single JSON item over 768 KiB is rejected before staging with local data retained. The manifest is capped at 6,000 references. Limits fail closed; no records/history are truncated. The older injected-SDK transport refuses chunked roots rather than treating an empty inline map as deletion.

Actual emulator tests cover >1 MiB records plus history, interrupted staging/reuse, loss of the root acknowledgment after server commit, unchanged revision on acknowledgment retry, anonymous/other-account chunk denial, and tampering rejection. Root CAS is the publication boundary. Canonical ordering prevents redundant writes/history duplication. Initial mirrored records do not manufacture arrival-history entries.

Unused chunks are deliberately not deleted by this client. Production cleanup/quota/load operation and authentication lifecycle remain release work. Recovery availability uses the tested 30-day filter; ordinary records persist indefinitely. Browser/memory adapters support CAS; plain read/write fallback adapters are single-instance test fixtures, not a concurrent production backend.

## Final restore and account safeguards

The workbench defaults to merge restore and offers explicit replacement; the legacy integration always merges. Preview shows restored/resurrected records, preserves omitted records and legacy indexes, and checks the preview is current before applying. Undo preserves unrelated later edits. Conflict choices retain both rejected preimages and advance the record version. Linked demo datasets reject account switching; simultaneous first connections use one atomically saved synthetic session.
