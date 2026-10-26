# Stage 2 — isolated Training development

Serve the repository on loopback, then open `http://127.0.0.1:8765/stage2/?fixture=review`.

This is a **synthetic development path**, not a deployed replacement. The namespace is isolated from the original application and from the Stage 1 legacy fixture. Built-in exercise definitions come from the existing library; templates are explicitly fictional and workout history starts empty. No original health data, Firebase account or production configuration is read.

## Implemented functional surface

- Numbered rotation (up to eight workouts), rest/discard semantics, explicit Finish & Save, separate skipped-position events, independent manual rotation correction.
- Permanent exercise/template/session identities, permanent template versions and immutable active/completed template snapshots. Previous values come from real completed sets and are never premarked done.
- Search/recent/favorite/muscle/equipment exercise picker, custom exercises, session-only additions and linked replacement previews. Original performed sets and unfinished plans remain under their original IDs.
- Superset containers and round-based rest, five-column entry at tested 320/390/430px widths, jump menu, notes, warm-up flags and completion feedback.
- Timestamp-based rest with ±15/pause/skip and session-only base duration; explicit workout pause/resume; separate active/elapsed/paused durations. Reopening starts on Home with a persistent Resume banner.
- Incomplete-save confirmation preserving every planned set; only valid completed working sets count for volume and PRs.
- Exact single-rep/Epley 1–15 rules, 16+ rep exclusion only for estimated 1RM, heaviest/rep-specific records, one consolidated pill per set, and chronological recalculation after corrections. PR recomputation uses a single running-best pass.
- Deleting a saved workout requires confirmation and offers history-based Undo; rotation stays unchanged. Resaving a session completed on another device updates the same workout and never advances rotation twice.
- Completed summaries with conservative comparable-session matching, explicit Save Changes, 30-day recoverable versions, separate Update Rotation, and real-observation exercise charts/ranges.
- Per-entity Stage 1 persistence, atomic local batches, demo-only authenticated sync, visible conflict review, offline service worker scoped to `/stage2/`, and protection for partially typed values during sync.

## Files and verification

`builtin-ids.js` is the permanent built-in identity registry; do not regenerate IDs from library array positions. `training-core.js` is pure domain logic. `training-records.js` projects entities and permanent rotation events into versioned records. `app.js`/`index.html`/`styles.css` implement the development UI; `sw.js` touches only its own cache/scope.

```sh
node --test --experimental-test-isolation=none tests/*.test.cjs
NODE_PATH=/tmp/logbook-tools/node_modules node tests/stage2-browser.cjs
NODE_PATH=/tmp/logbook-tools/node_modules node tests/stage2-editing-browser.cjs
```

Install `playwright-core@1.64.1` in the selected tool prefix and set `CHROMIUM_PATH` if needed. The HTTP server must be running on 127.0.0.1:8765. For the emulator tests, use the Stage 1 demo-only Firebase config:

```sh
firebase emulators:exec --project demo-logbook-stage1 --config stage1/firebase.json --only firestore,auth "LOGBOOK_REQUIRE_EMULATORS=1 node --test --experimental-test-isolation=none tests/*firestore-emulator.test.cjs && node tests/stage2-emulator-browser.cjs"
```

The UI's Demo sync button creates local emulator users only. Saved demo sessions reconnect on reopen; dataset/account binding and atomic session selection prevent silent account switching across tabs; production authentication/token-refresh support is excluded. Verified chunks plus a CAS manifest cover >1 MiB snapshots, interruption and retry. Long-running operation/cleanup and physical iPhone Safari/PWA acceptance still need release verification. Ambiguous real legacy identity mapping and any real-data migration require their separate safeguards and authorization.

These screens validate functionality and accessibility. They do **not** claim the final visual reference match or implement the later 16-theme/Home-widget phase. Original root/preview entry points, styles, sync and workers remain untouched.
