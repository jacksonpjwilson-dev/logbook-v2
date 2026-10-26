# Isolated Stage 1 Firebase emulator tests

Only a **demo-** project ID is permitted. Do not insert production Firebase credentials.

The existing preview app, `preview-widget/index.html`, does **not** load the Stage 1 modules.

From the repository root, with Node 22 and Firebase CLI installed:

```sh
node --test tests/stage1-*.test.cjs
firebase emulators:exec --project demo-logbook-stage1 --config stage1/firebase.json --only firestore,auth "node --test tests/stage1-firestore-emulator.test.cjs"
```

The Firestore emulator test checks revision-precondition failure on stale writes using HTTP REST.
The in-memory and disk tests check the app's three-way merge, persisted synthetic queue, version history, and rollback primitives. The emulator transport is experimental and not yet attached to an application sign-in flow. Emulator rules allow synthetic data for local testing **only**; do not deploy them.

## Local browser persistence smoke test

Serve the repository on loopback only, for example:

```sh
python3 -m http.server 8765 --bind 127.0.0.1
```

Open `http://127.0.0.1:8765/stage1/harness.html` and run the IndexedDB persistence test. It creates synthetic-only keys in the isolated `logbook-v2-stage1-browser-smoke` database; it never loads existing application data, Firebase scripts, or real accounts.

## Acceptance limits

These are **experimental modules**, not yet wired into the existing `preview-widget/index.html`. Do not migrate real browser data using this build. No production service worker, Firestore project, or live deployment was modified. The emulators:exec CI result and iPhone PWA behavior must be validated before Stage 1 signoff.

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

`stage1-migration.js` accepts only explicitly supplied fixtures; it does not discover/read user browser storage. It writes a separate full-source backup and verifies SHA-256 plus exact readback before migration. Duplicate identities remain blocked for review. Local rollback histories are durable, but cloud-wide recovery history and full migration mapping/integration still need acceptance work. See `IMPLEMENTATION_STATUS.md` before proceeding to Training or any cutover.
