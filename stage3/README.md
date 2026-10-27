# Stage 3 — isolated Food/Nutrition development

Serve the repository on loopback and open `http://127.0.0.1:8765/stage3/?fixture=review`. This path is synthetic, uses its own IndexedDB namespace/worker scope, and never loads production configuration, real accounts, personal records, or the legacy data backend. Fictional catalog definitions are labeled and history starts empty. Stage 1 storage/versioning and demo-only Auth/Firestore transport are reused.

Implemented: Summary First calories/macros, numbered named meals, top/meal/floating Add, recent/favorite/personal search, manual food definitions, explicit Open Food Facts text/barcode lookup with package-basis review, live quantity preview, compatible conversions with explicit food-specific factors, immutable log snapshots, per-ingredient atomic saved-meal/copy review, versioned definition/saved-meal edits, effective-dated targets, exact adherence rules and provisional today, truthful habitual suggestions, historical correction, bulk deletion confirmation/recovery, separate water events and Undo.

Every log route opens quantity review. Multi-ingredient additions commit only after every ingredient is confirmed; cancel adds nothing. Nutrition targets require a new effective date (today or future); one immutable version per date, with deterministic identities so concurrent targets conflict. Existing past targets cannot be silently replaced. Date attribution is stored explicitly; external per-100 g/mL units require user review rather than guessed liquid density. OFF is community data, not a verified medical/product authority; incomplete labels are rejected. External queries send only the typed query/barcode and omit credentials; no automatic camera permission or background product lookups.

`nutrition-core.js` contains immutable domain operations; `nutrition-records.js` maps per-entity records while preserving other module records; `app.js` is the functional UI. Dialog drafts survive background sync. A stale edit becomes a visible Stage 1 conflict instead of silently overwriting a competing version. Production authentication and final theme fidelity are outside this build. See `docs/handoff/VISUAL_REVIEW.md` and `IMPLEMENTATION_STATUS.md`.

```sh
node --test --experimental-test-isolation=none tests/*.test.cjs
NODE_PATH=/workspace/logbook-tools/node_modules node tests/stage3-browser.cjs
firebase emulators:exec --project demo-logbook-stage1 --config stage1/firebase.json --only firestore,auth "LOGBOOK_REQUIRE_EMULATORS=1 node --test --experimental-test-isolation=none tests/*firestore-emulator.test.cjs && node tests/stage3-emulator-browser.cjs"
```

Install the same `playwright-core@1.64.1`, Chromium, Java 21 and Firebase CLI 14.27.0 used by CI. Browser scripts require a loopback server on 8765; `CHROMIUM_PATH` can select its binary. External products are mocked in tests, never fetched as personal data. Stage 1/2 regressions remain in the combined CI; screenshots are uploaded as synthetic previews.

Physical iPhone Safari/PWA validation, production auth/release and formal migration remain open. No deployment, main merge or real-data migration is authorized by this development work.
