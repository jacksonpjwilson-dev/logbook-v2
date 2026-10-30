# Existing web-app data migration

The native app currently creates a fresh local store. It does not read a browser's storage, connect to Firebase, or import a web export. No existing records were copied or modified.

The legacy `preview-widget` stores its data in browser `localStorage` (including keys such as `lb2w:data9`, `lb2w:water`, `lb2w:theme`, and `lb2w:pages6`). A browser export may contain the primary database while sidecar keys hold additional state. An export must be inspected and reconciled before import; importing only the primary database could omit water logs, layout, or other settings. Stage 5/6 may use a different schema, so do not assume that legacy keys describe the newest web app data.

Before implementing migration:

1. Export from the exact web-app build and browser profile that contains the records to retain.
2. Preserve an untouched copy of that export. Do not point a migration tool at production Firebase.
3. Document the export's schema and include all required sidecar state; test parsing against synthetic data first.
4. Map dates, food portions/macros, workout sets/exercises, and identifiers explicitly. Report unsupported records instead of silently dropping them.
5. Import once into a new native store and compare record counts and totals before continuing to use it.

The app's Settings screen currently offers a native JSON backup export only. A safe legacy import workflow is still outstanding.
