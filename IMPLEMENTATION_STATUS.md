# Implementation status

Updated 2026-10-26. Work is restricted to `logbook-v2-upgrade`; no main edits, deployment, production Firebase, real accounts or personal records.

## Current milestone

Stage 1 is **in progress**, not signed off. Stage 2 Training is queued behind the Stage 1 acceptance gate. Baseline head: `39e494fe26fa4db4c8b4053d6651a215790241d5`.

The handoff has been preserved in `docs/handoff/`. Three original visual sheets were supplied in the separate ZIP and are available in the session; full visual work is deferred as requested. The ZIP guide supersedes the earlier note claiming these images were unavailable.

## Evidence

- Baseline: native Node 24, 31 individual checks passed, 1 emulator check skipped. `--test-isolation=none` exposes individual test results in this environment; the default subprocess reporter only reports files.
- Current Node: **50 individual checks passed, 2 emulator-only checks skipped**, exit 0, using `node --test --experimental-test-isolation=none tests/stage1-*.test.cjs`.
- Chromium: actual IndexedDB reload, pending queue recovery, concurrent tabs, same-record conflict preservation, offline edit, aborted transaction, quota failure passed via `tests/stage1-browser.cjs`.
- Firebase Auth/Firestore emulator: **2 integration checks passed**, exit 0, using Firebase CLI 14.27.0, Java 21, `demo-logbook-stage1`, Auth/Firestore bound to loopback. Includes stale write rejection, anonymous/other-account denial, invalid revisions, and production collection denial.
- Workbench UI: visible synthetic add, backup, side-by-side conflict resolution, restore preview/confirmation, Undo all passed; screenshot generated at `stage1/artifacts/workbench.png` (local artifact, not committed).
- iPhone Safari/installed PWA: not run; requires a physical device. No Safari parity claim.
- GitHub Actions: [first hardening run](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/40356870895) passed all three jobs; individual Node, Chromium/workbench and emulator logs reviewed. Latest [run 40359721786](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/40359721786) also passed all three jobs after the concurrency correction; all job logs reviewed.

## Changes under validation

- Atomic compare-and-swap in a single IndexedDB transaction prevents cross-tab overwrites; store retries independent mutations and preserves competing same-record intentions.
- Successful upload advances its baseline while keeping newer local edits queued; unrelated records continue syncing during conflict review.
- Restore creates versioned tombstones rather than physically removing records. Migration preserves raw originals, malformed shapes and approved sidecars; separate durable SHA-256 backup readback precedes synthetic migration. Duplicate identities remain blocked.
- Emulator rules now require authenticated ownership and sequential revisions; all production collections denied. Browser adapter has no production bypass option.

## Stage 1 outstanding gates

Full legacy-app integration, complete migration/reference mapping and validation, broader browser interruption coverage, extended recovery/retention stress tests, and iPhone validation remain open. Do not use these experimental modules with real data.

## Requirement traceability

| ID | Code path | Verification | Status | Notes |
| --- | --- | --- | --- | --- |
| G01 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Later stage; no completion claim. |
| G02 | `preview-widget/stage1-*.js`, `safety-core.js`, `stage1/firestore.rules` | Stage 1 Node/browser tests; emulator test passed | Partial | Experimental and isolated; outstanding gates above apply. |
| G03 | `preview-widget/stage1-*.js`, `safety-core.js`, `stage1/firestore.rules` | Stage 1 Node/browser tests; emulator test passed | Partial | Experimental and isolated; outstanding gates above apply. |
| G04 | `preview-widget/stage1-*.js`, `safety-core.js`, `stage1/firestore.rules` | Stage 1 Node/browser tests; emulator test passed | Partial | Experimental and isolated; outstanding gates above apply. |
| G05 | `preview-widget/stage1-*.js`, `safety-core.js`, `stage1/firestore.rules` | Stage 1 Node/browser tests; emulator test passed | Partial | Experimental and isolated; outstanding gates above apply. |
| G06 | `preview-widget/stage1-*.js`, `safety-core.js`, `stage1/firestore.rules` | Stage 1 Node/browser tests; emulator test passed | Partial | Experimental and isolated; outstanding gates above apply. |
| G07 | `preview-widget/stage1-*.js`, `safety-core.js`, `stage1/firestore.rules` | Stage 1 Node/browser tests; emulator test passed | Partial | Experimental and isolated; outstanding gates above apply. |
| G08 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Later stage; no completion claim. |
| G09 | `preview-widget/stage1-*.js`, `safety-core.js`, `stage1/firestore.rules` | Stage 1 Node/browser tests; emulator test passed | Partial | Experimental and isolated; outstanding gates above apply. |
| T01 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Stage 2 Training gate. |
| T02 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Stage 2 Training gate. |
| T03 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Stage 2 Training gate. |
| T04 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Stage 2 Training gate. |
| T05 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Stage 2 Training gate. |
| T06 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Stage 2 Training gate. |
| T07 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Stage 2 Training gate. |
| T08 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Stage 2 Training gate. |
| T09 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Stage 2 Training gate. |
| T10 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Stage 2 Training gate. |
| T11 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Stage 2 Training gate. |
| T12 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Stage 2 Training gate. |
| T13 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Stage 2 Training gate. |
| T14 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Stage 2 Training gate. |
| T15 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Stage 2 Training gate. |
| T16 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Stage 2 Training gate. |
| T17 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Stage 2 Training gate. |
| T18 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Stage 2 Training gate. |
| T19 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Stage 2 Training gate. |
| N01 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Later stage; no completion claim. |
| N02 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Later stage; no completion claim. |
| N03 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Later stage; no completion claim. |
| N04 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Later stage; no completion claim. |
| N05 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Later stage; no completion claim. |
| N06 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Later stage; no completion claim. |
| N07 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Later stage; no completion claim. |
| N08 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Later stage; no completion claim. |
| N09 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Later stage; no completion claim. |
| N10 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Later stage; no completion claim. |
| N11 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Later stage; no completion claim. |
| N12 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Later stage; no completion claim. |
| S01 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Later stage; no completion claim. |
| S02 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Later stage; no completion claim. |
| S03 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Later stage; no completion claim. |
| S04 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Later stage; no completion claim. |
| W01 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Later stage; no completion claim. |
| W02 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Later stage; no completion claim. |
| W03 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Later stage; no completion claim. |
| U01 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Later stage; no completion claim. |
| U02 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Later stage; no completion claim. |
| U03 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Later stage; no completion claim. |
| U04 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Later stage; no completion claim. |
| H01 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Later stage; no completion claim. |
| H02 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Later stage; no completion claim. |
| H03 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Later stage; no completion claim. |
| H04 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Later stage; no completion claim. |
| X01 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Later stage; no completion claim. |
| X02 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Later stage; no completion claim. |
| X03 | `preview-widget/stage1-*.js`, `safety-core.js`, `stage1/firestore.rules` | Stage 1 Node/browser tests; emulator test passed | Partial | Experimental and isolated; outstanding gates above apply. |
| X04 | Existing legacy app; replacement pending | Not verified against approved requirements | Pending | Later stage; no completion claim. |

## Acceptance checklist

- [x] TST01 — native Node suite executed; emulator skipped only in ordinary offline invocation.
- [x] TST02 — first hardening run green and logs reviewed; latest correction run also green with logs reviewed.
- [x] TST03 — local demo Auth/Firestore run passed, exit 0.
- [ ] TST04 — pending full acceptance evidence.
- [x] TST05 — independent-record concurrency passes in Node and Chromium.
- [ ] TST06 — pending full acceptance evidence.
- [ ] TST07 — pending full acceptance evidence.
- [ ] TST08 — pending full acceptance evidence.
- [ ] TST09 — pending full acceptance evidence.
- [ ] TST10 — pending full acceptance evidence.
- [ ] TST11 — pending full acceptance evidence.
- [ ] TST12 — pending full acceptance evidence.
- [x] TST13 — authenticated demo REST transport, owner isolation, other-account/anonymous/production denial tests passed on local emulators; production rules are neither accessed nor changed.
- [ ] TST14 — pending full acceptance evidence.
- [ ] TST15 — pending full acceptance evidence.
- [ ] TRA01 — pending full acceptance evidence.
- [ ] TRA02 — pending full acceptance evidence.
- [ ] TRA03 — pending full acceptance evidence.
- [ ] TRA04 — pending full acceptance evidence.
- [ ] TRA05 — pending full acceptance evidence.
- [ ] TRA06 — pending full acceptance evidence.
- [ ] TRA07 — pending full acceptance evidence.
- [ ] TRA08 — pending full acceptance evidence.
- [ ] NUT01 — pending full acceptance evidence.
- [ ] NUT02 — pending full acceptance evidence.
- [ ] NUT03 — pending full acceptance evidence.
- [ ] NUT04 — pending full acceptance evidence.
- [ ] NUT05 — pending full acceptance evidence.
- [ ] SWS01 — pending full acceptance evidence.
- [ ] SWS02 — pending full acceptance evidence.
- [ ] SWS03 — pending full acceptance evidence.
- [ ] SWS04 — pending full acceptance evidence.
- [ ] UI01 — pending full acceptance evidence.
- [ ] UI02 — pending full acceptance evidence.
- [ ] UI03 — pending full acceptance evidence.
- [ ] UI04 — pending full acceptance evidence.
- [ ] UI05 — pending full acceptance evidence.
- [ ] HIS01 — pending full acceptance evidence.
- [ ] HIS02 — pending full acceptance evidence.

## Visual requirement tracking

Brand/icon/splash, 16 named themes, four pages/navigation, 38-widget registry, Training, Food, Check-ins, History and accessibility screenshot matrices are pending. No exact visual fidelity claim.

## Next work, in order

1. Review all three GitHub Actions jobs for this milestone; do not equate local tests with CI.
2. Complete safe legacy data/UI integration in an isolated development path, with every entity and sidecar accounted for and ambiguous mappings reviewed.
3. Extend interrupted migration/restore and crash scenarios and recovery history stress coverage. Cross-device history and authenticated REST transport now pass both synthetic and actual emulator tests.
4. Recheck all Stage 1 acceptance items before Stage 2 Training implementation. Physical iPhone checks remain explicitly unverified where unavailable.

No further visual assets are needed for the current storage milestone. Exact theme-panel matching is reserved for the later visual phase.

## Follow-up: cross-device recovery history

Recovery entries now merge and travel in the same cloud compare-and-swap as records. A fresh isolated device can recover prior edits and deletions. Added `preview-widget/stage1-rest-transport.js`: explicit loopback endpoints, demo-only project IDs, local anonymous Auth sessions, redirects denied, JSON commit preconditions, authenticated owner document paths. Actual emulator test covers independent-device edits, conflicts, resolution, deletion and fresh-device recovery. No SDK/production configuration is loaded.

`main` rechecked at `278f0936b8a8f8f4b39bd6fbbe2dc72c961b3f32`. Production entry points, legacy app scripts/styles, service workers and Firebase config are unchanged by both milestones.


## CI concurrency correction

Follow-up run [40359360769](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/40359360769) passed Node and browser jobs but failed the real-emulator concurrent-device check. The test had not asserted every intermediate sync result, so a failed request surfaced later as a missing record. Intermediate results are now asserted. The transport now handles the case where revision security rules reject a concurrent stale commit before its precondition: only an authenticated read proving revision advancement permits a retry. Genuine unchanged-revision permission failures still surface. Two deterministic regressions and the actual emulator suite pass locally and in [CI run 40359721786](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/40359721786).


## Verified milestone handoff

Code commit: `635620cfd70f7726de40c2207eb5f083fd5dcbb5` (on development branch only).

Latest reviewed CI: https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/40359721786

- Synthetic job: 50 passed, 2 emulator-only checks skipped in this job, zero failures.
- Emulator job: both integration checks executed and passed, zero skips/failures.
- Browser job: Chromium persistence/concurrency/storage-failure checks and workbench recovery UI passed.
- Working source and branch match; main remains unchanged; no deployment was triggered.

**Stage 1 is still incomplete. Stage 2 has not started.** The remaining work includes full isolated integration with the legacy application, full legacy identity mapping/validation, wider interrupted-network/migration/restore tests and iPhone validation. These results validate this storage milestone, not the complete handoff or release readiness. No approval is needed for routine follow-on development within the authorized branch.

