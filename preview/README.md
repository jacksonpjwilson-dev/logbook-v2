# Isolated iPhone review preview

Owner-private hosted preview: https://logbook-v2-isolated-preview.jacksonpjwilson.chatgpt.site

This is a separate Sites project and origin, not the production Logbook deployment. Private hosting requires the owner's ChatGPT sign-in. Each browser/device gets its own fictional sample workspace; edits stay in that device's IndexedDB. This is not a cloud-sync preview. Do not enter real personal records.

## Review on iPhone

1. Open the link in Safari and sign in with the account that owns this Site if asked.
2. Use fictional data to try all four Home pages, widget editing/gallery, Settings → Theme Gallery, Training, Food, Check-ins and History/calendar. The Preview guide explains the boundaries inside the app.
3. Share → Add to Home Screen, then open the installed preview once online. Its name is **Logbook Preview**, separate from the current app.
4. Try Airplane Mode, close/reopen, and background/resume with a sample workout/timer. Return online afterward. Report the screen, theme and steps for any issue. Private sign-in renewal, iOS worker updates and OS storage behavior still need physical-device acceptance.

The initial sample records are fictional: three workout templates, six completed sessions, 14 days of sleep/food, sample water events, seven weights and a sample supplement schedule. Dates are relative to first opening. Initialization runs once; reload never overwrites edits. Separate devices do not share changes. Safari and an installed PWA may also use separate local storage depending on iOS behavior.

## Reproducible package

From this repository:

```sh
node preview/build.cjs /absolute/new-empty-output https://logbook-v2-isolated-preview.jacksonpjwilson.chatgpt.site
```

The output must be separate from the repository and new/empty. The builder copies an explicit development asset whitelist, leaving all original files intact. Hosted copies allow only the exact preview origin plus loopback QA, use `logbook-v2-stage1-isolated-preview-v1`, disable cloud entrypoints, exclude emulator/auth/Firestore transport scripts, remove cloud-connect controls, and apply `connect-src 'none'`. Live external food lookup returns a clear unavailable message. No Firebase project, credentials, server-side data storage or integration is configured. The package includes source hashes and a baseline commit manifest.

The original Stage 2–5 loopback guards remain intact in GitHub. Production/root and deployed `preview-widget` files are not copied. Only shared safety/storage/library dependencies from `preview-widget` are included.

The separate Sites repository contains the exact static `dist/` and `.openai/hosting.json`. Its own `main` is the preview artifact source, not `jacksonpjwilson-dev/logbook-v2`'s protected `main`. Publish through the native Sites owner-private operation, preserving this Site identity and access. Current private Site ID: `appgprj_6ae11a9bd6a88191a524a378c0d708dd`. No production merge or deployment is authorized.

## Verification

- `node --test --experimental-test-isolation=none tests/preview-seed.test.cjs` checks fictional seed/domain validity and input preservation.
- `NODE_PATH=<tools>/node_modules node tests/preview-browser.cjs` builds a fresh artifact, serves it only on loopback, and checks shared modules, History, no cloud/external requests, local database isolation, theme persistence, offline reopening and 320/390/430px layout in Chromium.
- Physical iPhone/PWA, hosted private-auth renewal and exact wallpaper approval remain unverified until owner review. Local Chromium checks do not establish iOS parity.
