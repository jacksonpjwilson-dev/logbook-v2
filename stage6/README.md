# Stage 6 — History and development release validation

The existing loopback-only `/stage5/` Home workspace now loads this read-only History implementation. Open its History dock destination. It uses the same synthetic IndexedDB records as Training, Food and Check-ins, without a second analytics database or migration.

- Five categories: Overview, Training, Body, Nutrition, Sleep. Overview includes four summaries, metric chart, selectable activity heatmap and PR summaries.
- Inclusive 7D/30D/90D/All/custom ranges. Invalid custom ranges show an error rather than silently swapping dates. All begins with the earliest recorded observation, including water-only or dose-only dates; future records are excluded from a report ending today.
- Weight, single-exercise estimated strength, sleep, calories, protein and completed-working-set volume. Missing dates never become zero-valued observations. Weight/strength/volume graph units follow the recorded body-unit preference. Source snapshot names and permanent exercise IDs are retained.
- Optional dashed comparison uses the immediately preceding equal-length period, one exercise ID, and at least three actual dates in both periods. Recorded-date means disclose differing observation counts. A comparison does not assert statistical significance or equal coverage.
- Month calendar with Training/Food/Check-in modes, accessible date buttons, selected-date detail and dated source-screen navigation. Skipped rotation positions have separate S labels and never add completed activity. Empty, out-of-report and future dates remain browsable; source modules reject future logging as before.
- Calendar detail includes immutable food quantities, water events, official weights, wake-date sleep and explicit Taken/Not taken doses. Overlapping sleep is flagged and excluded from the graph using the existing domain rule.
- Historical edits, tombstones and sync changes are read from the shared source on refresh or return to History. Background refresh preserves range/date/exercise state and avoids replacing controls when records have not changed. All reporting functions are read-only.

The Overview activity heatmap shows at most the last 90 dates of the selected report; the caption states the displayed interval. The full report and month calendar still cover All/custom dates. This avoids rendering years of daily buttons. Graph values are available in an expandable keyboard-accessible table; selecting a date opens its calendar detail.

Run `node --test --experimental-test-isolation=none tests/*.test.cjs` for unit/domain regression. Serve the repository on `127.0.0.1:8765` and run `NODE_PATH=<tools>/node_modules node tests/stage6-browser.cjs` with Chromium for the actual interface. The combined CI also runs the prior stages, theme screenshot matrix and isolated Auth/Firestore suites.

This is a development validation candidate, not a production release. See [release validation](RELEASE_VALIDATION.md). Physical iPhone/Safari/installed-PWA and exact scenic reference approval remain open. No real-data migration, production authentication, merge or deployment is authorized by this implementation.
