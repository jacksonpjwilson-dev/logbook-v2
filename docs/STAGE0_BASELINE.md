# Logbook v2 — Stage 0 baseline and preservation plan

Status: Stage 0 repository preparation only; no migration or production deployment authorized.
Baseline (main at audit): `278f0936b8a8f8f4b39bd6fbbe2dc72c961b3f32`
Development branch: `logbook-v2-upgrade` (created from baseline).
Current preview asset version: `preview-widget/version.json` = `w19`.
Current preview URL: https://jacksonpjwilson-dev.github.io/logbook-v2/preview-widget/
Older root entry point: `index.html` (separate from `preview-widget/index.html`).

## Known application surface

- `preview-widget/index.html`: standalone PWA entry; loads `lib.js`, `data.js`, `sync.js`, and `app.js`.
- `preview-widget/app.js`: UI, training, food, history, widgets, settings, interaction logic.
- `preview-widget/lib.js`: built-in exercise library.
- `preview-widget/data.js`: local backend, seed, mutation API.
- `preview-widget/sync.js`: Firebase Auth + Firestore sync; current last-write-wins merge must be replaced in Stage 1.
- `preview-widget/sw.js`: preview-scoped network-first service worker; cache name `lb2w-preview-w19`.
- `preview-widget/styles.css`: current legacy colorways.
- `preview-widget/manifest.json`: PWA installation settings.

## Identified persistence surfaces (inspect before migrations)

- `lb2w:data9`: local application JSON data.
- `lb2w:session`: local session designation.
- `lb2w:sync`: local synchronization hashes/timestamps.
- `lb2w:water`: separate local hydration data.
- `lb2w:theme`: theme configuration.
- `lb2w:pages6`: Home Screen page/widget layouts.
- `lb2w:signedin`: local sign-in bootstrap indicator.
- `lb2w:layout`: referenced constant; confirm whether still used.
- `lb2w:vr`: session-scoped preview version reload flag.
- Firestore: client code targets collection `logbookV2`, document `{uid}`, field `r` for flattened records.

**These are code-derived storage addresses, not evidence that particular personal records exist.** No real user localStorage or Firestore documents were accessed, exported, copied, or modified during Stage 0.

## Non-negotiable migration safeguards

1. Record the source commit, schema version, and effective deployment before any migration.
2. Inventory every local storage key and cloud record type, including data outside the main DB object.
3. Create durable, verified backups before modifying live data; never rely solely on an in-place same-origin localStorage copy.
4. Use synthetic fixtures first and exercise idempotent migration, deletion/tombstones, version-conflict handling, and rollback.
5. Preserve old legacy identifiers/raw payload and original template/exercise names if identity mapping is ambiguous.
6. Validate counts, identifiers, record hashes, set completion flags, nutritional snapshots, and date attribution before any cutover.
7. Do not overwrite live data, trigger migration, or deploy without subsequent separate authorization.
8. Stage 1 must implement Smart Conflict Detection and 30-day recoverable version history before replacing last-write-wins in production.

## Stage 0 validation matrix (pending execution)

| Test | Expected result | Status |
|---|---|---|
| Baseline branch reference | Development branch starts at immutable recorded main SHA | Created; reverify |
| App entry and dependencies | Preview references all required source files | Source inspected |
| Legacy key inventory | All known storage keys documented; dynamic writes inspected | Preliminary only |
| Local persistence across reload | No record loss or reset | Not runtime tested |
| Workouts, food, sleep, weight baseline | Existing features render and persist | Not runtime tested |
| Offline assets | Preview service worker serves cached assets | Not runtime tested |
| Login & multi-device sync | Sign-in and Firestore rules work as intended | Not runtime tested |
| Cloud security | User isolation and rules validated | Not tested; client source insufficient |
| Production deployment | Main and live app are unchanged | Must reverify; no deployment triggered |
| Migration rehearsal | Synthetic fixture conversion and restoration | Pending Stage 1 implementation |
| iPhone installed PWA | Launch, restore, safe area, cache behavior | Pending device tests |

## Known blockers before Stage 1 production work

- No verified durable export of *real* user data; only source-level inventory exists.
- Firestore security rules and actual cloud data contents have not been inspected.
- No real iPhone installed-PWA runtime validation has been conducted.
- The exact 16 approved theme reference assets must be available for the later visual stage.
- Baseline source includes an older root-level app and newer preview; deployment route should be verified before release changes.
- Avoid committing secrets or personal user exports. Existing Firebase web configuration is public client configuration; actual authorization rests on backend rules.

## Permission boundary

Stage 0 authorizes preparation on `logbook-v2-upgrade`. It does not authorize edits to `main`, deployment, reading private user accounts, production data migration, or Stage 1 implementation.
