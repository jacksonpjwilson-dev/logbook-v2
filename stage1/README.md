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
