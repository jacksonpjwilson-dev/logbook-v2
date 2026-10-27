# Stage 5 — Home, widgets, Appearance and Settings

Serve the repository on loopback and open `http://127.0.0.1:8765/stage5/?fixture=review`. This is an **isolated synthetic development workspace**, not a production replacement. Main/original root/preview entry points, production Firebase and real records remain untouched.

## One development source of truth

Home uses `logbook-v2-stage1-home-development` with a validated `synthetic-<fixture>-*` key. It initializes an empty Training split/history, an exercise-definition library, empty Nutrition and empty Check-ins. Opening the existing development screens with the opt-in `workspace=home` query connects them to this same guarded store. Standalone Stage 2/3/4 fixtures retain their original stores and behavior; nothing is automatically copied or migrated from them. The parent owns demo cloud sync and daily prompts, while existing module mutations, immutable histories and conflict handling remain in use.

All widgets derive from recorded Training, Nutrition and Check-in entities. Finished sessions count as workouts; only completed valid working sets contribute volume/PR observations. Strength charts hold one permanent exercise ID. Food snapshots and effective targets drive totals/adherence; today's adherence is provisional. Missing measurements have no chart points. Sleep overlaps remain flagged/excluded, weight trends require three distinct actual trailing-week dates, and zero scheduled supplement doses satisfy the habit.

## Home interaction

- Four exact defaults: Daily, Training, Food, Progress & History; fixed Training/Food/History/Sleep & Check-ins/Settings dock. Two equally prominent large Training widgets. No vertical Home scrolling at tested 320×568, 390×844 and 430×932 sizes. Detail screens scroll inside their own area.
- Four-row/two-column stable layout. Intentional spaces persist until explicit Smart Tidy. Pages can be added, renamed and reordered. Widget identities survive placement changes; adding to a full page creates an explicit overflow page rather than moving existing items.
- Long press enters glass wiggle editing; pointer dragging supports page-edge dwell and cross-page movement. Placement/size dialogs offer the keyboard-accessible alternative. Invalid/occupied drops fail without discarding the old placement. Gallery supports categories, search, live recorded previews and Small/Medium/Large selection.
- Smart Tidy previews its count, requires Apply, stores Undo, and refuses to erase a layout changed since its action. Widget/page deletion also has exact layout Undo.
- Home layout is one atomic record because placements constrain each other. Theme, preferences and timer are separate records. Independent other-module/theme edits still merge; competing layouts preserve both sides for explicit review.

## Widget inventory and source limits

`legacy-widget-inventory.json` records all 38 original IDs/names/legacy sizes. `docs/handoff/WIDGET_INVENTORY_STAGE5.md` maps each to current data and source gaps. Families remain Food10/Training10/Body9/History8/Home1. All 38 offer S/M/L layouts. Four approved display variants reuse IDs without inventing additional widget types: Fibre → Nutrition Streak; Meal timing → Nutrition Adherence; Measurements → Habits Streak; Steps & resting HR → Detailed Daily Check-in. They are explicit options in the gallery and configured on the approved default pages.

Canonical source limits remain visible: Fibre requires explicit immutable label fibre for every logged item and verified quantity conversion; it never estimates unknown grams. Meal timing has no inferred clocks. No circumference or HealthKit source is connected, so those canonical views say Not recorded/Not connected instead of inventing measurements. These legacy source gaps are documented, not presented as working data acquisition. The approved manual Sleep/Weight/Supplement check-ins remain fully available.

## Appearance and PWA

All 16 exact approved names are implemented, Premium Glass default. `themes.js` has per-theme text/material/dock/accent/input tokens and atlas positions. The gallery previews globally without writing; Apply persists, Cancel returns to the current saved theme, including after background updates. Modules inherit the selected theme through an origin/source-checked bridge. Text and muted labels pass tested 4.5:1 contrast over worst-case composited card surfaces; buttons pass the same threshold. Reduced motion disables optional parallax/wiggle/splash/haptics.

The clean atlas is an **AI reconstruction from the three supplied original sheets**, with no baked-in UI/share overlays. It is not the unavailable original wallpaper source files and is not a lossless extraction. `assets/PROVENANCE.md` records source and output hashes. Matching original scenic artwork exactly and human visual approval remain open; generated reconstructions are not an exact-fidelity signoff. Automated QA captures 96 screenshots (16 themes × six app sections) for review.

The SVG/PNG app mark follows the approved black rounded square/angular white L. Manifest, 180px touch icon, 192/512px app icons and scoped offline workers are provided. The blended three-second splash runs once per cold tab session, not on reload or visibility resumes, and is skipped for reduced motion. Browser lifecycle signals do not prove every iOS cold-launch/install behavior; physical iPhone/PWA testing remains Stage 6.

## Settings and backup

Searchable groups: Appearance, Home Screen, Fitness & Nutrition, Tracking Preferences, Data & Backup. Deep links open actual target/library/training/sleep/reminder controls. Optional water goal, planned bedtime and supported haptics are explicit preferences; planned values never become observations. A standalone timestamp rest timer is separate from workout analytics.

Synthetic backup export includes a SHA-256-verified snapshot plus archived version/conflict metadata, excluding account/session tokens. Restore accepts only the explicit synthetic archive format, verifies it, previews category/add/update/delete/resurrection counts, offers merge or explicit replacement, and requires confirmation against the reviewed current records. Persistent Stage 1 Undo preserves unrelated later edits. **Snapshot restoration retains the current store's version history; exported version/conflict metadata remains in the independent archive and is not automatically imported.** An archive with unresolved conflicts must be reviewed first. No real-data migration/import is authorized.

## Verification

```sh
node --test --experimental-test-isolation=none tests/*.test.cjs
NODE_PATH=/workspace/logbook-tools/node_modules node tests/stage5-browser.cjs
NODE_PATH=/workspace/logbook-tools/node_modules node tests/stage5-visual-browser.cjs
firebase emulators:exec --project demo-logbook-stage1 --config stage1/firebase.json --only firestore,auth "LOGBOOK_REQUIRE_EMULATORS=1 node --test --experimental-test-isolation=none tests/*firestore-emulator.test.cjs && node tests/stage5-emulator-browser.cjs"
```

Use the same Chromium/Playwright 1.64.1/Java 21/Firebase CLI 14.27.0 as combined CI. HTTP must be on loopback port 8765. `build-icons.cjs` renders committed PNGs from the SVG when needed. The visual suite renders **126 variants** (38 canonical types plus four approved display modes × three sizes) at three iPhone viewport sizes, tests native touch swipes, and captures 96 theme/section previews. Functional tests use actual embedded entry flows, cross-page pointer drag, long press, safe snapshot logging, preview/apply/cancel, Settings, restore/Undo and offline first opening of prepared module workers. Actual emulator tests preserve typed drafts and competing layouts.

Stage 6 still covers complete cross-feature History/calendar, broader release acceptance, exact visual approval, physical iPhone/install/update behavior, production auth/rules/token lifecycle and separately authorized real-data migration/deployment. The History dock already opens useful actual-data summaries and ranges, without claiming the entire Stage 6 calendar/report matrix complete.
