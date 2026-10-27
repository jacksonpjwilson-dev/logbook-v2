# Development candidate and release gates

## Recommendation

Continue isolated synthetic acceptance. **Do not merge or deploy this candidate to production.** Functional History development is implemented; physical iPhone acceptance, exact wallpaper approval, production authentication/rules and real-data migration review remain open. The 16 wallpapers are documented reconstructions, not recovered original background assets.

## Automated evidence

Focused History domain checks cover inclusive and custom ranges, leap dates, water-only All bounds, equal-period comparisons, stable exercise IDs with duplicate names, explicit rotation skips, false dose states, and historical Training/Food/Weight corrections without unrelated mutations. Browser checks cover the five categories, three calendar modes, selected-date links, accessible value table/focus, corrections in the shared store, 320/390/430px layouts, all 16 themes and offline reopening. Combined CI evidence and commit references are recorded in `IMPLEMENTATION_STATUS.md` after log review.

The existing suites remain required: storage integrity and recovery, immutable module snapshots, offline/rejoin, concurrent conflicts, all actual emulator integration checks and the full theme/section screenshot matrix. Only `demo-logbook-stage1` on loopback Auth/Firestore is used. Automated browser screenshots contain synthetic records.

## Device and user acceptance still open

- Physical iPhone Safari and installed PWA: install/icon/safe area, keyboard and VoiceOver, reduced motion, cold-open splash, lock/background/close/reopen with active workout and timers, offline source-screen access, notification permission/fallback, and OS storage eviction behavior.
- Physical iPhone update: existing installed build → new scoped worker → offline restart, draft/session retention and shared records unchanged. Chromium evidence cannot establish iOS behavior.
- Human approval of all named themes against supplied original images, including reconstructed scenic wallpaper details.
- Real-data backup independently verified; ambiguous legacy identity mapping reviewed; migration rollback rehearsed before any real cutover. No real records have been opened or migrated.
- Production authentication/token lifecycle, security rules and longer-running operational load/cleanup coverage. Demo emulator rules must never be deployed.

## Review and rollback

All work is confined to `logbook-v2-upgrade`. Original root and deployed `preview-widget` application entry points remain intact. Stage 6 changes add `stage6/`, its tests and documentation, and update only the isolated Stage 5 shell plus the synthetic CI workflow. No production workflow runs.

The Stage 5 functional code baseline is `2aab713baa457ba5c94ac0916d7c00cc668a402d`; its reviewed status update is `4d1901ac0f96f65fe21f0947f89142330d46c372`. A future development rollback can revert Stage 6 commits on the authorized branch after review. Reporting adds no schema or writes, so its removal needs no record migration. Do not clear IndexedDB or unregister production workers as a rollback step. Retain independently exported synthetic backups and recovery metadata. No rollback command is run automatically.

Scoped Stage 5 cache v2 includes History scripts. Existing caches are retained; no production cache is removed. Real production packaging, cache lifecycle and deployment remain separate acceptance work.

## Authorization boundary

No automatic merge, production deployment, authentication setup or real-data migration. Request explicit authorization only after producing a reviewed release candidate and resolving applicable release gates. This development increment does not request release approval while those gates remain open.
