# Stage 4 — isolated Sleep & Check-ins

Serve the repository on loopback and open `http://127.0.0.1:8765/stage4/?fixture=review`. This is development-only, synthetic and local-first. No production config/account/backend or real records are read. History begins empty; supplements are entirely user-defined. Final Home/dock/theme work remains Stage 5.

## Source of truth

The same `fixture` query **shares Stage 2's guarded synthetic Training IndexedDB store and demo session**. The Training link preserves it. `checkins-records.js` writes only `checkins.*` entities and preserves Training/Nutrition records. `completedWorkoutDates` reads only nondeleted `training.workout:*` entries with an explicit completion timestamp; active workouts, rest days and skipped rotation events never schedule doses. Different fixtures intentionally remain separate. No legacy or Stage 3 database migration occurs here.

- Sleep records store original local bed/wake strings, explicit minutes east of UTC for each endpoint, absolute timestamps, wake-date attribution, derived duration and optional explicit override. Browser timezone at entry is provenance, not an assertion that user-selected travel offsets belong to that zone. UTC offsets default from the browser but remain editable for travel/ambiguous times. Correcting a record keeps its ID and creates a recoverable version. Overlapping local entries are rejected; independently synchronized overlaps remain visible and are excluded from aggregates pending explicit correction/deletion.
- Goal versions are permanent by effective date, forward-only, and cannot change already recorded sleep goals. Graphs show actual observations only, with real 7/30/90/All/custom ranges. Goal consistency explicitly means measured wake dates meeting their effective goal; missing dates do not count as zero or as measured failures.
- Exactly one official weight record uses a deterministic date ID. kg/lb entry retains original amount/unit and exact kg conversion. Replacements require confirmation; stale concurrent entries become explicit Stage 1 conflicts. Prior comparisons use actual earlier measurements. The seven-day trend requires at least three distinct dates within the inclusive trailing window. Delete/Undo use the 30-day recovery history.
- Supplement and dose identities are permanent. Each schedule has its own effective-date ID, name/slot snapshots and version. Changes/stopping are forward-only and cannot rewrite already recorded dose-state dates. Modes are daily, ISO weekdays, or actual completed workout dates. Only explicit Taken/Not taken actions create dose states. Adherence uses scheduled doses, and zero scheduled is satisfied. If a workout correction removes eligibility, existing Taken history stays visible outside the current schedule and is excluded from its current denominator.
- The first-open daily overlay is claimed atomically once per fixture/local date across tabs, with durable shown/dismissed records. Optional Sleep/Weight actions preserve the choice to skip. Explicit dismissal suppresses the midday follow-up. A morning interaction leaving sleep missing can generate one nonmodal follow-up at/after noon; late-day first opens do not generate another. Local claims prevent repeated display while synchronized daily records preserve choices across the demo dataset.
- Optional reminders use a chosen local time, quiet mode and a once-per-date durable claim. They are checked while open or on resume, only when scheduled doses remain. Permission requests happen only on the explicit permission button. Supported service-worker notifications respect platform permission and OS Do Not Disturb behavior; denied/unavailable notifications fall back to one in-app reminder. No guaranteed background scheduling, delivery or ability to override system restrictions is claimed.

## Verification

```sh
node --test --experimental-test-isolation=none tests/*.test.cjs
NODE_PATH=/workspace/logbook-tools/node_modules node tests/stage4-browser.cjs
firebase emulators:exec --project demo-logbook-stage1 --config stage1/firebase.json --only firestore,auth "LOGBOOK_REQUIRE_EMULATORS=1 node --test --experimental-test-isolation=none tests/*firestore-emulator.test.cjs && node tests/stage4-emulator-browser.cjs"
```

Use Chromium plus `playwright-core@1.64.1`, Java 21 and Firebase CLI 14.27.0 as in combined CI. Browser tests require loopback HTTP on port 8765. `CHROMIUM_PATH` can select the browser. The browser suite completes a real synthetic Stage 2 workout to test schedule eligibility, checks 320/390/430px layouts, keyboard chart selection, offline recovery, notification-denied fallback and daily prompt behavior. Emulator browser tests preserve an open typed form while remote weight changes arrive, require an explicit choice, and verify offline rejoin. No system notification is sent by tests.

Screenshots are generated under ignored `stage1/artifacts/stage4-*.png` and uploaded by CI. Physical iPhone Safari/installed-PWA testing, exact 16-theme appearance, production authentication and formal migration/release gates remain open. This build authorizes no merge/deployment or real-data operation.
