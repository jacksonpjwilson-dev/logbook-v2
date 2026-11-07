# LOGBOOK — AUTHORITATIVE MASTER PRODUCT AND IMPLEMENTATION SPECIFICATION
**Version:** 1.2 — Decision 88 baseline plus subsequently requested authentication, Help and Coaching extension, November 6, 2026  
**Status:** Approved product requirements; implementation status **NOT VERIFIED**  
**Audience:** Codex, native iOS / watchOS implementers, reviewers and QA  
**Directive:** Implement and audit the existing app against this specification without redesigning previously approved features. The explicitly requested post-review authentication, Help and Coaching extension in §15 supersedes the original no-account rule and applies in addition to the 88 settled decisions.

## 0. Reading this document, evidence and authority

This spec consolidates the approved requirements recoverable from the design history, including Decisions 75–88 and the surviving descriptions of earlier approvals. **Do not interpret the fact that a requirement is documented as evidence that the current code implements it.** Do not claim an 88-item original verbatim decision transcript or original pixel-perfect design tokens were retrieved: earlier conversation recovery is incomplete. Maintain a traceability matrix (requirement -> file/symbol -> proof/test -> screenshot -> status).

**Evidence classes**:
- **APPROVED, RECOVERED:** An explicitly stated user approval or reliably preserved earlier decision; treat as binding.
- **VISUAL REFERENCE REQUIRED:** Original screenshot/assets or design tokens must be located in the repository, prior assets, or user-approved visual exports. Preserve the original; never generate a substitute and call it approved.
- **IMPLEMENTATION OPEN:** User requires a capability, but actual entitlement/API/device support must be established empirically. Report constraints honestly; do not silently substitute a web UI for a native feature.
- **IMPLEMENTATION DETAIL:** Choose robust engineering semantics consistent with approved intent, without turning them into new product decisions.

If earlier source art contradicts an approximation in this text (e.g., exact icon stroke, theme names/colors, font, radius, relative placement), the **approved original visual reference takes priority**. If two original approvals conflict, record the contradiction in the audit rather than arbitrarily choosing. No new design decisions; use a narrow implementation assumption only where essential and explicitly log it.

## 1. Product identity and architecture

Logbook is a **native iPhone-first food/nutrition, training, sleep, weight, supplement and progress tracking app**. It is **not** an aviation flight logbook. Native integrations extend to watchOS, HealthKit, widgets, Live Activities, Dynamic Island, Apple Watch complications and iCloud where platform supports them.

**Nonnegotiables:** polished Apple-like UI faithful to approved design; offline-first functioning local database after initial account activation; secure Logbook accounts and role-based sharing per §15; explicit sync safeguards; the current user-selected 20 theme placements (19 unique designs) described in the visual addendum; no vertical scrolling on the four Home pages; four horizontally swipable Home pages; the exact persistent five-icon athlete dock (with role-gated Coaching access described in §15); no fabricated data, dummy interactions or presentational mockups passed off as working features. Configuration can scroll in full-screen detail screens when appropriate; Home cannot.

After initial account sign-in/activation, the app must remain fully usable without network for existing authorized local data, custom entries, exercise and food log creation/editing, workout sessions, calculations and History. Initial sign-in/account linking and cross-account coaching actions require network access. Cloud and online nutrition lookup enhance the offline core.

## 2. Home design: mandatory exact layout contracts

### 2.1 Universal Home navigation
- Four horizontally swipable pages in order **Daily**, **Training**, **Food**, **Progress & History**; visible page indicators/dots.
- Fixed, floating five-icon **athlete** dock: **Training**, **Food**, **History**, **Sleep & Check-ins**, **Settings**. The dock is never a sixth Home page, and does not obstruct Home widgets. Icons, dimensions, labels, alignment, drop shadows, surface treatment and active states must match approved source art; do not choose new icons on convenience grounds.
- Strict **2 columns × 4 rows** of square small-grid cells, **8 cells/page**, with consistent grid gap. Supported widgets: **small = 1×1 square**, **medium = 2×1 wide rectangle with same height as small**, **large = 2×2 square in grid coordinates**. Design illustrative dimensions recorded earlier: small ~176×176, medium ~360×176, large ~360×360 with ~8 unit gap. Treat these as **reference proportions**, not unconditional device-independent point sizes; derive actual sizes from safe width/height, respect dock/safe areas and match screenshot at target iPhones.
- No overlaps, clipped content or vertically scrollable Home. Empty areas are intentional where widget geometry leaves gaps.
- Each widget is independently functional, with verified navigation and tappable subregions where specifically approved. No giant invisible outer tap target hiding the separate controls.

### 2.2 Default Daily Home (top to bottom)
1. **Large 2×2 — Calories & Macros Remaining**, occupies first two rows. Actual calorie ring, separately colored protein progress **bar**, separate carb and fat progress bars, accurate goal/consumed/remaining semantics, and footer **“View Food >”** deep linking to Food. Never swap protein bar for ring, omit carbs/fats, or substitute the generic Nutrition Today widget.
2. **Medium 2×1 — Next Workout**, third row. Workout title, target muscles, exercise count, approximate duration, most recent completion, working **Start** action and **“View Workout >”** footer. Use the active named program and correct next-rotation item.
3. **Small 1×1 — Habits**, fourth row left. Flame and consecutive perfect-day streak; three separate Sleep, Weight, scheduled Supplements status regions (green complete / neutral incomplete), and completed/eligible count. EACH of the three distinct regions navigates into its own full check-in control. The streak and count obey the rules in §7.
4. **Small 1×1 — Detailed Daily Check-in**, fourth row right. Larger side-by-side moon/Sleep and scale/Weight values, supplement completion below with pill icon, clipboard/checklist top-right. THREE separately tappable Sleep/Weight/Supplements zones to full detail. This is distinct from the Habits small widget, not a duplicate.

### 2.3 Default Training Home
1. **Large 2×2 — Workout Split**, one full-width large square occupying two rows of the approved two-column Home grid. Entire ordinary rotation of 7 or 8 workouts is presented as **2 columns × 4 numbered tiles**, next workout highlighted and marked with play icon, each tile displays number/name/compact last completion; tap a tile for that workout’s details; **Edit Split** footer. For fewer than 8 items, leave room rather than fabricating tiles. **Decision 75:** Rotation length is flexible, including >8; keep this exact fixed footprint and two-column internal organization, show the upcoming portion without clipping, and provide access to the **full split** in a separate screen. Rotation highlights must reflect the correct program and may not be changed merely by viewing a non-next tile. A “rest” entry never counts as a numbered workout.
2. **Large 2×2 — Workout Calendar**, occupies the other two rows, full current calendar month with real numbered dates, abbreviated workout labels, current date outline, current week highlight, completed-this-month count, previous/next month controls, tappable days and real history. If multiple sessions on a date, date detail shows each separately (§5.10). Do not simplify to a weekly strip or substitute an activity heatmap.

### 2.4 Default Food Home
1. **Large 2×2 — 7-Day Nutrition Trends**, first two rows; switch metrics Calories/Protein/Carbs/Fats, with 7-day meaningful chart and average calories/protein, contextual historical targets. Compact **hydration footer** with today’s water progress, goal, quick-add + action and link to full water log. This replaces an earlier redundant Nutrition Today ring; no default standalone Water widget.
2. **Medium 2×1 — Today's Meals**, third row; compact numbered meal rows (initially Meal 1/2/3, names customizable); kcal, protein, chevrons, +Add in header; each meal row directly opens correct meal; overflow managed in full Food screen without clipping.
3. **Small 1×1 — Nutrition Streak**, fourth row left; flame, seven weekday states, consecutive nutrition-on-target streak, link to adherence history, distinguishing insufficient/unlogged days from failures.
4. **Small 1×1 — Easy Next**, fourth row right; one dynamic contextual suggestion, reason and working action. Smart logic considers unlogged meals/macros/hydration/time; must suppress already completed or inapplicable actions. No generic placeholder CTA.

### 2.5 Default Progress & History Home
1. **Large 2×2 — 30-day chart**, first two rows, FIVE tabs **Weight / Strength / Sleep / Calories / Protein**, with current value, trend, graph and **View History** footer. Strength supports individual exercise selection and estimated 1RM; don't insert extra tabs or hide existing ones.
2. **Medium 2×1 — Monthly Activity Heatmap**, third row; numbered days, tappable, intensity reflects **balanced** logged activity across Training, Food, Sleep, Weight and **scheduled** Supplements. Avoid biased scoring solely because food has many entries; empty/no-required categories must be handled correctly.
3. **Small 1×1 — PRs This Month**, fourth row left; trophy at upper right, monthly PR count, one featured PR, month context, chevron/footer into PR history. See baseline/PR definition §6.
4. **Small 1×1 — Nutrition Adherence**, fourth row right; 30-day percentage ring, target indicated upper right, footer/chevron into adherence details. Same math and dated goals as the Food streak.

### 2.6 Home customization
- Long-press edit mode; drag/drop across four Home pages, snapping to supported sizes only; resize within allowed small/medium/large variants where appropriate. No overlap, no overflow, no vertical Home scrolling.
- **Decision 85:** When dragging/resizing into occupied cells, **automatically reflow** other widgets with predictable feedback. Commit only if a valid eight-cell arrangement exists; otherwise cancel or offer valid destination page without silently deleting anything.
- Widget Library can add/remove **existing approved widget types**; removing a widget never deletes its underlying data. Restore all four approved **default page layouts**. No new data widgets invented from this spec.

## 3. Visual fidelity, themes and typography

The **current user-approved catalogue has 20 category placements representing 19 unique theme IDs**, organized under Defaults, Glass and Featured as specified in §16. The old 16-theme catalogue is **superseded** (retain its files only as historical evidence). The newer user-supplied screenshot and bundled generated references establish visual directions, but exact source palettes, typography metrics, blur strengths, radii and compositing values are **not fully recoverable**. Use screenshots and source art to validate proposed tokens; mark unverified details `REFERENCE_LIMITED`, never claim pixel-exact approval from a concept image or generated background.

Preserve original Apple-like visual style: light-touch surfaces, rounded edges, deliberate alignment, correct iconography, readable density, exact larger/smaller text hierarchy, widget internal geometry and every approved tap region. Build on live layout constraints, not a scaled screenshot masquerading as UI. Retain original specific microcopy when supported; a replacement generic label is an audit defect. Respect Dynamic Type/accessibility without silently changing the default approved aesthetic.

## 4. Training programs, rotation and templates

### 4.1 Named programs and independent rotations
- **Decision 76:** Multiple named saved workout programs, **exactly one active**. Each program has its own mutable rotation and ordered workout templates; program switching never modifies prior workout history or resets the saved rotation of inactive programs.
- Rotation can have any practical length (§2.3). Numbered workouts only; rest days are not rotation steps. Full management/edit screen; individual tile taps show details, not implicitly select them as next.
- Scheduled next workout is highlighted in Training Home/Next Workout. An explicitly **Skip Workout** action advances that program's next item **without** creating completed history, sets, volume or PRs; rest days do not advance.
- Manually start/complete **non-next** workout without advancing/replacing the highlighted scheduled next. Completing the **scheduled next** workout through Finish & Save advances its rotation, **even if incomplete**; Discard does not. Do not advance for browsing templates or accidentally tapping Start.
- **Decision 87:** Switching active program while a session is unfinished is allowed after clear confirmation. The unfinished session retains its **originating program ID, exercise snapshots and original rotation semantics**. Finish/Discard later affects only the original program according to the scheduled/non-next rule; current active other program stays intact.

### 4.2 Split editor and exercise catalog
- Drag-and-drop reorder workout templates and their exercises; edit planned sets, rep targets and rests. Can create, reorder and ungroup optional **supersets**. When finishing a set within a superset, start rest after the final group exercise rather than at every intermediate leg.
- Searchable built-in exercise library. Create custom exercise with name, primary muscle group, equipment and optional instructions; support tracking modes **weight+reps, reps-only, duration, weight+distance**. Measurements must adapt appropriately to exercise mode; PR estimates only for meaningful compatible weighted sets.
- Template edits apply to **future sessions**; never retroactively alter completed session snapshots or personal records.
- Session-only exercise replacement via library **before beginning the exercise**; does not overwrite saved program template. Do not invent mid-exercise replacement or transfer partially entered sets; user explicitly rejected that.
- Primary-muscle-only volume attribution preserved from earlier approval where aggregate per-muscle statistics are shown; do not double-credit secondary muscles. Session physical lifting volume computed from suitable completed weighted sets only, with units accurately normalized.

### 4.3 Optional progression
- **Decision 82:** Previous performance visibly displayed. Optional weight/repetition progression suggestions based on **completed** previous performance. User must **explicitly accept** before any suggested field changes. Dismissal leaves values unchanged. No background auto-progressions or template mutations. Recommendations must be appropriate to the exercise's measurement mode and available evidence, not fabricated for first-ever data.

## 5. Active workout and completed workout experience

### 5.1 Layout contract
- Expandable exercise cards; **current exercise expanded**, others collapsed one-line. Current expanded standard weighted set table is EXACTLY **Set | Previous | Weight | Reps | Done** five columns. For alternate measurement types, use corresponding units/inputs without faking weight or PR support. One standard set type; **no separate warm-up classification**.
- On completion of last planned set for an exercise, auto-collapse it and expand next exercise, respecting the superset sequencing. Manual expansion remains possible.
- **BLUE FLOATING REST TIMER CARD at TOP**, immediately below active workout header and ABOVE scrollable exercise list, NEVER bottom. Countdown with **pause/resume, skip, +15 seconds**. Global default **90 seconds**, adjustable with optional exercise overrides. A changed rest duration persists through the rest of that active session unless changed again. Rest automatically starts after a completed set (or final exercise in a superset), runs down, then becomes **Ready** at zero and does not restart until another qualifying completed set.
- **BOTTOM-PINNED** live statistics area: elapsed duration, completed/planned set count, lifted volume, **Finish & Save** action. Must never obscure exercise inputs or keyboard and remain reachable. Confirm on physical screen, landscape/keyboard conditions as applicable.
- **Decision 77:** Optional per-exercise **session notes** and optional overall **workout notes**; preserve with session History, no clutter to five-column table.

### 5.2 Lifecycle, recovery and interruption
- Crash/force-close/relaunch-safe local autosave of draft exercises, set values, completion state, session notes, elapsed time and timer anchor; resume without advancing rotation.
- **Decision 80:** A non-intrusive **Resume Workout banner** appears when an unfinished session exists; use Food/History/check-ins freely while maintaining recoverable state. It must not block app re-entry with an obligatory resume/discard dialog.
- Finish & Save allowed for incomplete sessions: persist actual completed sets only, associate program, handle scheduled rotation advance, show **Workout Completion Summary** with duration, sets, volume and earned PRs; Done returns to Training. Discard terminates draft without completed workout record or rotation advance.
- If another program becomes active, the unfinished session and its independent source rotation remain intact (§4.1). Preserve Watch session synchronization as supported.

### 5.3 Completed-workout History
- Calendar date tap opens actual completed sessions, workout detail including completed sets/weights/reps/durations, notes, session metrics and PRs; edit historical set weight/reps/completion and relevant session content. Record date and program association do not change from routine editing. Recompute volume, strength/1RM progression, and PRs on edits. Never overwrite the template or other sessions.
- **Decision 78:** Multiple independently saved and editable workout sessions on **one calendar date**; day detail lists each and aggregates daily statistics appropriately. Preserve distinct session identities/times.

## 6. Strength calculations and PR rules

- For compatible completed weighted sets, calculate estimated 1RM using the approved Epley-style example where appropriate: `estimated_1RM = weight × (1 + reps/30)`, with defensible treatment for invalid/zero/missing reps and unsupported exercise modes. **Formula selection, reps constraints and precise rounding need implementation evidence; do not invent PRs for duration/reps-only sets.** Store the source set, input unit and calculated value so recalculation is deterministic.
- Historical best per **individual exercise**, based on actual completed qualifying sets, not planned loads. PR is only **strict improvement** over an established historical estimated-1RM best, **not** a rep-at-weight record.
- **Decision 74:** First recorded completed workout for an exercise establishes its **baseline** and does **not** count as PR. Later improvements do.
- **Decision 73:** At most **one** estimated-1RM PR for each exercise **per completed workout**, determined by the highest qualifying set. A workout featuring multiple exercises may award a PR in each. PRs This Month and Completion Summary use same authoritative derivation.
- When historical sessions/sets are edited, deleted, restored or brought in through backup, recompute PR status in chronological sequence so one changed past record can remove or establish later PRs. Avoid duplicate PR counters and stale denormalized badges.
- Strength chart supports individual exercise selection (§2.5).

## 7. Sleep, weight, supplements and Habits

### 7.1 Check-in screen
- Full **Sleep & Check-ins** screen with three separately expandable sections/cards for Sleep, Weight, Supplements, edit and history controls. Home Habits and Detailed Daily Check-in widgets must deep-link to the relevant card/entry, not merely open general Home.
- **Sleep**: bedtime, wake time, calculated sleep duration, optional manual duration override, optional **1–5-star quality**. Main overnight session is assigned to its **wake-up calendar date** while retaining actual start/end timestamps. Optional separate daytime naps contribute to daily total sleep-hours history but **only valid main sleep** satisfies daily Habits sleep requirement; duration or subjective quality goal is not necessary for Habits completion.
- **Weight**: daily measurement only, **lb/kg unit selection**, display latest measurement and change from previous actual measurement, dated edit/history and 30-day chart. Do not insert body-fat or waist fields.
- **Supplements**: each named with optional dose, schedule every day or selected weekdays; one-tap Taken/Undo. Only scheduled/due supplements count toward today's Habits status. A day with no due supplements treats the category as not required (neutral), so successful Sleep+Weight = **2/2** and perfect-day streak can continue.

### 7.2 Perfect-day streak
- A day is perfect if it has a valid main sleep entry, a weight entry and **every scheduled due supplement** marked taken. On no-due-supplement days it is determined by Sleep+Weight. Missing required categories break the appropriate streak; neutral categories never count as incomplete. Show current consecutive perfect-day flame count, eligible/completed denominator and independently tappable state regions.

### 7.3 Daily reminders
- Independently configurable reminders for Supplements, Weight, Sleep, Food. Editable time, **all OFF by default**, suppress already completed and respect each supplement's due-day schedule. Notifications require appropriate permission and work correctly with local time/day boundaries.

## 8. Food, nutrient data and water

### 8.1 Food Log screen
- Expandable meal cards; collapsed totals, expanded food entries and **Add to Meal** button; editable meal labels (Meal 1/2/3 etc). Per-food correction/edit and direct row navigation.
- One prominent **Add Food** button opens EXACTLY FOUR bottom-sheet options: **Search Foods | Scan Barcode | Manual Entry | Recent Foods**. No fifth Favourites option. Favourites is a separate star toggle and filter within food search (any food or recipe), independent of Recent Foods.
- Suggest destination meal based on time, editable before logging; when initiated from a meal card that meal is preselected.
- Food entries support servings, grams and ounces when supported by **verified food-specific serving sizes**, recalculating calories, protein, carbs and fat in real time. If portion definition unverified, grams-based entry is fallback; no invented grams/serving.
- Allow manually correcting a logged food's nutritional values, optionally saving an individual corrected **personal food** without changing shared/canonical upstream database items.
- **Decision 81:** On full Food Log, **horizontal swipe day-to-day**, previous/next arrows and calendar date picker; gesture recognizers must not conflict with meal expansion/edit, scrolling, or child controls. Historical edits work on the selected date and apply that date's targets, not today's.

### 8.2 Sources, search and offline
- Hybrid online + cached local recent/saved/custom entries. **Canadian Nutrient File** (generic foods) and **Open Food Facts** (packaged/barcode) are selected candidate providers. Verify live access, usable endpoints, nutritional fields, serving provenance, attribution and terms/licensing rather than assuming API viability. Preserve field source and confidence. Handle network loss gracefully; maintain existing personal entries offline.
- Unknown/unsupported barcode opens **Manual Entry**, with **no automatic barcode association**.

### 8.3 Recipes and copying
- Custom reusable recipe builder: ingredients with quantities, total yield in servings or grams, calculated nutrient total and per-portion results. Log a chosen serving amount. Editing recipe affects **future** logs only; historical meals preserve immutable nutrient/quantity snapshots but allow intentional manual correction.
- Copy an existing meal or complete past day's meals to a chosen destination date, snapshotting individual items/quantities/macros independently. If destination has entries, prompt **Add** or **Replace matching meals**; do not delete unrelated meals. Past source never mutates.

### 8.4 Targets, adherence, water
- Configurable calorie, protein, carb and fat goals with **date-specific overrides**; compare each past day to the goal effective on that date, without retroactive rewrites.
- Nutrition adherence shared consistently between Food Home streak and History 30-day ring: calorie tolerance configurable, default **±5%**, and protein minimum met; missing/unlogged days distinct from logged days that fail targets. Chart denominator/status semantics must remain consistent everywhere.
- Water log: **250 / 500 / 750 mL quick-add**, custom amount, editable dated history and daily water goal. Trend-widget hydration footer holds quick action and full log link. No default Water widget.
- Food Home 7-day chart switches Calories/Protein/Carbs/Fats, shows average calories/protein and accurate day/date data. Easy Next suggestion must be grounded in missing/incomplete actions and suppress nonactionable completions.

## 9. Full History and analytics

- Full **History** destination separate from four Home pages; categories **Training / Nutrition / Weight / Sleep / Habits**, meaningful period selection, correct graph/detail navigation and all original record values.
- Training calendar with month navigation, day taps, multiple sessions, session edit and notes, workout-associated PRs. History chart for strength must be exercise-selectable.
- Monthly Activity Heatmap with *numbered* tappable days and balanced-category scoring (Training, Food, Sleep, Weight, due Supplements) rather than counting meal frequency as dominant activity; use one consistent algorithm and document it.
- PRs This Month and Nutrition Adherence use common derivation engines; ensure charts update upon historical edits, deletions, reverts, restored backups and cloud merges.
- Support data empty/loading/error cases explicitly; do not fabricate test stats in production.

## 10. iOS, watchOS, HealthKit, Live Activities and notifications

**IMPLEMENTATION OPEN: inspect actual Apple capability / entitlements and on-device APIs; do not mark complete because a Swift type or mocked preview exists.**

- **HealthKit**, with independent user permissions: bidirectional supported data handling for sleep and weight; export supported food nutrition and completed workouts where platform permits. Record source IDs and provenance, deterministic deduplication and loop prevention. When real Health measurement and manual Logbook entry genuinely conflict, user-entered Logbook record is preferred for daily display and History; no assumption that same-day observations are identical. Imported vs user-entered labels retained.
- **Dynamic Island + Live Activity** for the current workout: prioritize live rest countdown, including expanded workout state, elapsed duration, completed/planned sets and rest status; enforce actual OS authorization and device support. Do not pretend all iPhones have Dynamic Island.
- **Native Apple Watch companion**, interactive active session, exercise/set logging, rest pause/resume/skip/+15, synchronized to iPhone with conflict-safe handling. Independent settings for rest-complete audio alert, iPhone vibration, Apple Watch haptics and notifications. Verify background behavior, Watch connectivity and disconnect/reconnect; no unsupported promise of perfect real-time delivery.
- **Native iOS Home Screen widgets** separately selectable in supported sizes: Nutrition, Next Workout, Habits, Daily Check-in. **Lock Screen widgets**: Habits, Calories Remaining, Next Workout, Check-in Status, alongside workout Live Activity. **Apple Watch face complications**: Habits streak, Calories Remaining, Next Workout, Check-in Status. Deep link to relevant functionality; render actual shared-app data, not screenshots of the four in-app Home pages.
- **iCloud sync** for personal Apple-device data when possible, now alongside the mandatory Logbook account and secure app backend required for coach/client sharing (§15). Do not assume iCloud/CloudKit data can be accessed cross-account by a coach or Google-signed-in athlete. **Decision 84:** merge nonconflicting edits automatically, preserve both incompatible concurrent versions of the *same field* until user resolves; no silent last-write-wins overwrites. Work offline and retry; make conflicts visible and resolvable. Sync source identity, deletion tombstones, recipes and session snapshots correctly.

## 11. Settings, onboarding and data safety

### 11.1 Settings
- Settings dock opens grouped full Settings screen with the **six originally approved dedicated sections** (**Decision 79**): **Training; Food & Nutrition; Sleep & Habits; Appearance & Home; Apple Integrations; Data & Backup**. All already approved individual settings must exist in the appropriate section. Add clearly discoverable **Help & Support** and **Coach & Sharing** (and Account, where needed) entry points without removing or silently renaming the six approved sections. Do not insert a huge single settings scrolling list as root navigation.
- Appearance & Home exposes the **20 theme placements (19 distinct designs; see visual addendum)**, widget customization and restore defaults; do not substitute generated colorways for exact approved palette definitions.

### 11.2 First launch (Decision 88)
- **OPTIONAL guided setup**, skippable steps for **Nutrition Goals**, **Workout Program**, **Units**, **optional Apple Health permissions**. Immediate access to the main app **after successful account authentication** if guided setup is skipped; all setup values editable later. **Account authentication is now required by §15**, overriding the prior no-account statement. HealthKit permission remains optional. Preserve first-launch defaults consistently, never use fake populated records.

### 11.3 Data exports / backup
- Portable **complete app backup and restore**, plus per-category CSV exports. Export must include stable identifiers, user-entered and custom data, relationships, program/split definitions, routine notes, dated goals, history and app-specific settings needed to reconstruct Logbook consistently. Robust migration version and validation.
- **Decision 83:** When restoring over existing data choose **duplicate-aware Merge** or **explicitly confirmed Replace**. Validate backup integrity and create a **safety backup first**. Merge detects duplicate identities and genuinely conflicting edits instead of appending duplicates. Replace warns about replacing all current data/settings. Restoration must preserve accuracy of linked references and recompute derived metrics.
- **Decision 86:** User-created records deleted into **Recently Deleted for 30 days**, with Restore, explicit early permanent Delete and automatic expiry. Remove from active totals, PRs, streaks, charts immediately. Restore recomputes. Deletion and restore must synchronize safely; avoid reappearing deleted entries via old cloud state. Handle user intent and restore policies consistently with backup imports.

## 12. Critical acceptance tests (mandatory, not illustrative)

1. **Home geometry screenshot tests:** four default pages on actual target iPhone sizes; validate 2×4 small-cell grid, 1×1 squares, 2×1 wide same height, 2×2 square, no Home scrolling, dock visible, exact relative spacing, text hierarchy and icons. Screenshot comparisons against original *approved* images, including all 20 theme placements (19 distinct designs; see visual addendum); mark missing reference **BLOCKER**.
2. **Home functional map:** tap every outer and nested region (including three areas in both Habits and Check-in); links navigate to correct real screen. Training split numbered tile vs next rotation; day calendar month navigation, day tap and multiple sessions; trends tabs; hydration quick add; Easy Next contextual correctness.
3. **Widget editor:** drag across pages and onto occupied cell, reflow while preserving all widgets; each size snaps; capacity/overlap impossible; restore each original default; close/reopen persistent layout.
4. **Rotation matrix:** multiple programs, flexible >8 workouts, next highlight, scheduled Finish & Save of partial workout advances exactly once, Discard doesn't, Skip advances without record, out-of-order completion doesn't advance, switch programs during draft preserves original program rotation.
5. **Active workout:** five columns and alternate measurement modes, auto-collapse/expand, superset rest after group, adjustable timer, +15/pause/resume/skip/Ready, top blue rest card and bottom pinned stats never overlap keyboard; force-close resume preserves all data and timing.
6. **Training History:** multiple sessions same calendar date, individual notes/sets edit and correct aggregates; exercise replacement pre-start only; template edits future only.
7. **PR math:** first session is baseline, no PR; higher estimated 1RM later gives one PR per exercise per workout; multiple qualifying sets same session still one; weaker same exercise no PR; history edit/delete/restore recomputes later PRs and monthly feature count, compatible exercises only.
8. **Food input:** four sheet actions exactly; scan known and unknown barcode; source provenance; online/offline fallback; verified serving recalc and grams fallback; favourites versus recents; meal suggested, override and origin; nutrition correction personalized; food log date swipe/arrows/calendar; meal/day copy Add vs Replace matching, unrelated meals untouched; recipe revisions don't rewrite history.
9. **Targets and habits:** historical goal overrides preserved, calorie ±5% + protein min criteria match both displays, unlogged vs failed distinct; hydration quick add/edit; sleep wake-day assignment across midnight; naps count daily totals not Habits; no due supplements produces 2/2 and retains perfect streak; reminders off by default, scheduled suppression tested.
10. **Native features:** install real iPhone build and Watch app; HealthKit permissions import/export/dedup; simulate actual Live Activity / supported Dynamic Island / background behavior, widget timelines, Lock Screen, complications, haptics; test disabled permissions and unsupported hardware gracefully.
11. **Sync & backups:** device offline concurrent edits separate fields merge, same field conflict is preserved with resolution; restore older backup Merge vs Replace, validation and safety backup; duplicate IDs, relationships, export/import round-trip, CSV encoding, data surviving reinstall; no false 'synced' status.
12. **Recently Deleted:** delete and restore across every record class, recalc, 30-day expiry under controlled clock, cross-device tombstones, avoid unwanted changes to active rotation.
13. **First launch/settings:** 3-second splash -> sign-in/sign-up gate for signed-out users -> optional setup complete/skip -> Home; returning signed-in users can resume without repeated sign-in. Accurate settings in six original categories plus Help/Coach entry points; 20 theme placements (19 distinct designs; see visual addendum) present and screenshot-verified.
14. **Accessibility/reliability:** VoiceOver labels on distinct tap targets, supported fonts and contrast, locale/time zones, DST and cross-midnight sleep, unit conversion, race/double-tap session save, deterministic calculation and no mock content in release.

## 13. Codex execution contract: audit first, then fix

1. **Inventory** repo, Xcode workspace/project, app targets, Watch target, extensions, minimum OS, entitlements, resources, design tokens, source visual reference files and configured dependencies. Do not presume existing SwiftUI/native functionality.
2. Produce `requirements_traceability.csv`: `ID, Requirement, Evidence, Source/File/Symbol, Status [PASS/PARTIAL/MISSING/BLOCKED/UNVERIFIED], FunctionalTest, Screenshot, Notes` for every requirement in this spec. Zero claims of PASS without evidence.
3. First run baseline builds/tests and capture actual UI state with sim and device. Separate “compiles” from “works”, “preview exists” from “widget target installed”, and “API wired” from “real entitlement succeeds”. Report incomplete requirements.
4. Compare all four Home layouts and all 20 theme placements (19 distinct designs; see visual addendum) to **original approved references**. Seek exact screenshot assets inside repository or accessible project material. If unavailable, request the original artifacts as an **evidence blocker**, not a new design decision. Never substitute invented values silently.
5. Form a prioritized fix plan: **P0 integrity/rotation/data loss**, **P1 exact Home geometry/interaction**, **P2 training/food/history functionality**, **P3 Watch, widgets, Live Activities, HealthKit and iCloud with actual hardware/platform constraints**, **P4 polish**. Dependency sequencing can differ if justified.
6. Implement production code with real persistence, testable business rules, robust provenance, reconciliation and migrations. Build automated tests for calculations and state transitions, UI tests for critical flows, native integration checks where possible.
7. Run actual test evidence, store screenshot diffs, list verified features and outstanding blockers. No statement such as “everything is done” until all acceptance tests and missing design references are resolved.
8. Maintain one clear change log and audit; do not re-open the 88 settled design decisions. Implement the specifically requested §15 extension without inventing further feature requirements.

## 14. Known missing authoritative evidence (not new decisions)

- Exact **16 approved theme names/palettes** and complete original typography/icon/shadow/layout token inventory are not reliably evidenced in the recovered decision transcript. Recover from original references / existing project assets and verify; do not invent.
- Original visual imagery and complete verbatim Decisions **1–74** were not all accessible in consolidated context. Reconcile with archived project and approved source artifacts before asserting pixel-perfect fidelity.
- Actual working Codex/Xcode repository state, targets, dependencies and device tests have **not been inspected in this preparation**; every implementation status begins **UNVERIFIED**.
- Third-party food database access/licensing and precise Apple native platform constraints require implementation-time verification; these are engineering integration checks, not requests for fresh design choices.


## 15. Post-review approved extension — accounts, help, coach and athlete collaboration

**Authority and precedence:** The user explicitly requested these additions after concluding the 88-decision review. The earlier prohibition on a separate account and the earlier instruction to skip straight to Home are superseded **only where necessary** by this section. Do not reinterpret this as permission to redesign the original four Home screens, change the original five athlete-dock controls, replace any of the 16 approved themes, change training/food calculations, or alter the optional nature of guided setup. Implementation must be verified against actual source and runtime as for every previous requirement.

### 15.1 Launch sequence, account roles and authentication
1. Launch displays the **existing approved Logbook opening/splash screen for approximately 3 seconds**, then routes to authentication **if the user is signed out or has never activated an account**. Do not replace the splash artwork or previously approved visual style.
2. Authentication screen includes **Sign in with Apple** and **Sign in with Google** as real supported identity-provider flows (not inert branded buttons). Offer an email-based account/sign-in route as the practical mechanism for coaches and athletes to identify clients by email, with verified address ownership. Support both **sign in** and **sign up**. Provider-specific capability, Apple review obligations and OAuth redirect configuration require real verification.
3. Signed-in returning users retain an authenticated session using secure credential/keychain storage and normally continue into the app after splash; do **not** force interactive sign-in every launch unless the session is expired/revoked, user signs out or security requires reauthentication. On signing out, wipe or lock sensitive cached account data on shared devices and prevent accidental exposure when another account logs in.
4. At first account creation, choose **Coach** or **Athlete**. An athlete sees the previously approved standard experience. A coach has access to the coaching workspace; coaches may also use their personal training/food log where applicable, without conflating coach data with client data. Role assignment and coach permissions must be **validated server-side**, never inferred just from a local toggle or a visible icon.
5. After authentication/role selection, show the **approved optional, fully skippable guided setup** (nutrition goals, training program, units, optional Apple Health permissions). Skipping setup must be possible; signing in is a separate prerequisite, not a required onboarding step. Account recovery, provider-linking and email changes must maintain unique person/account identifiers independent of changeable email addresses.
6. Personal health data stays locally usable while offline **after first sign-in**, with queued personal changes and conflict resolution under existing rules. Secure coach invitations, cross-account sharing, remote coach edits, first sign-in and cloud reconciliation require network. Clearly label pending changes and do not promise real-time updates offline.

### 15.2 In-app Help & Support
1. Add a prominent **Help & Support** entry in Settings without removing the six already approved Settings sections; the help detail screen can scroll. Offer a short **guided walkthrough/tutorial** through app fundamentals: four Home pages and their widgets, custom layouts, Food Log and barcode/manual entry, workout programs and starting/completing workouts, rest timer, History/PRs, Sleep/Weight/Supplements, settings, native integrations, and (contextually) coaching.
2. Provide a searchable **FAQ / knowledge base** covering common questions, errors and permissions, with concise step-by-step answers and links to the relevant real app screen. Organize help into sensible topics, include coaching-specific how-tos for athletes and coaches, and allow users to restart/revisit walkthroughs at any time.
3. Help content must match the **actual shipped UI and supported behavior**. Make bundled core help available offline; additional online support content may load when connected. Explain permission denials, sync conflicts and data restore honestly. No fictional support responses or nonfunctional navigation.
4. Provide contextual Help links from relevant Settings areas or complex workflows when practical; ensure Dynamic Type, accessibility labels and correct deep linking.

### 15.3 Coach workspace, navigation and client list
1. After signing up as Coach, display a distinct **Coaching** icon/action in the **bottom floating dock** that opens the coaching workspace. The original five athlete dock icons remain intact and in their previously approved order. Coaching is a **role-gated extra dock action**, not a fifth Home page and not an excuse to change the exact four Home page grids; verify functional fit, touch targets and visual fidelity on small iPhone screens. Do not silently remove an original icon to make space. If the original design cannot accommodate six without violating touch targets, flag an engineering/visual conflict explicitly for review instead of inventing a replacement dock.
2. Coaching workspace contains a **client roster**, searchable by name/email where authorized, with invitation and onboarding statuses (e.g. pending, active, paused, revoked). Each client opens a concise **mini-dashboard** summarizing current food intake vs goals, macro adherence, hydration, workout completion and recent activity, strength/progression, sleep, weight, supplements/habits, and useful trends where the athlete has shared that category. Distinguish missing entries from failed targets; never display fabricated metrics.
3. From a client's view, an authorized coach can **view and edit** the athlete's workout programs, exercises/sets/targets and nutrition/meal parameters, food planning or logs as supported by the existing data model, and relevant other settings normally configured during the athlete's onboarding. Client-specific changes must be reflected in the athlete account with original historical nutrition snapshots, completed workouts and PRs preserved unless explicitly editing historical entries under existing rules. Honor workout draft/template versioning, rotation ownership and conflict resolution.
4. Every coach action must operate on a clearly identified **selected client context**; a prominent client indicator prevents accidentally editing the coach's own log or another client's. Provide edit attribution, timestamps, and an audit trail visible to relevant parties (including the athlete). Permission checks must be enforced on every client read and write on the backend, not only by hiding UI.

### 15.4 Invite an existing athlete by Logbook email
1. A coach can search/invite by an athlete's **verified Logbook email address**. Send a connection invitation associated with stable account IDs; never expose another account's sensitive data merely because the coach knows an email. Use rate-limited, enumeration-resistant invitation flows.
2. Athletes can go to **Settings > Coach & Sharing** to enter their coach's email, view pending requests and **accept or decline** a coach invitation. A coach must accept an athlete-initiated request if needed to establish a mutual relationship. The connection is **not active until the athlete knowingly authorizes it**; pending invitations grant no access.
3. Show coach identity, scope of sharing/editing and active/revoked state in athlete Settings. Sharing is limited to the authenticated athlete's own account and the authorized connected coach; unrelated users must have no visibility.

### 15.5 Coach enrolls a new athlete and preconfigures Logbook
1. A coach can **create a pending client enrollment on the client's behalf** using the intended client's email, then preconfigure the client's nutrition goals/meal parameters, planned meals when supported, workout programs and rotation, exercise targets, measurement preferences, supplement schedules, and other first-launch settings that are coach-editable. Treat this as a **pending client profile/template**, not ownership of the client's personal login credentials.
2. The system sends a secure invitation/activation link to the intended client. The client independently verifies the email and signs up using Apple/Google/email where supported, **accepts the coach relationship and explicitly consents to sharing**, then claims the preconfigured setup. The coach cannot silently sign consent, choose a permanent password, take over the account, obtain an athlete's Apple/Google credentials, or bypass HealthKit permissions on the athlete's behalf.
3. Preconfigured data must transfer exactly once, be previewable/editable by the athlete, survive invitation retries, avoid duplicate accounts, and preserve correct ownership and data-provenance identities. Unclaimed pending profiles must not be treated as fully activated accounts.
4. When client setup and onboarding are accepted, the athlete retains the right to modify their own personal data and controls, independently of the coach; imported coach-created plans should be distinguishable from athlete-generated logs.

### 15.6 Athlete-controlled Coach Mode / sharing
1. In athlete Settings add a discoverable **Coach & Sharing** screen where the athlete can **turn coach access ON/OFF**, add a coach by email, review/accept/decline invitations, inspect connected coach identity and permissions, and disconnect a coach. The default sharing state is **OFF until an explicit accepted invitation/consent**.
2. **OFF** means access to the athlete's data through the coaching service is revoked server-side, including new reads and edits; an already logged-in coach must lose remote access when revocation reaches the server. The athlete continues to use their own Logbook uninterrupted. **ON** resumes sharing only for an existing still-authorized relationship; if disconnected, require a new authorized invitation. Make this distinction clear in UI.
3. Do not claim revocation can retroactively erase information the coach already saw or independently exported. Protect cached client data: invalidate cached authorization, prevent subsequent reads and clear device caches of revoked athlete data at next secure sync/auth check; use short-lived scoped authorization and do not expose raw Apple Health permissions/data beyond explicitly shared Logbook records.
4. Coach-edited data must have safe reconciliation and visible attribution. When access is OFF, queued coach edits must not later apply after revocation. Athletes should be able to review coach changes and use existing audit/backup/recently-deleted safeguards.

### 15.7 Backend, privacy, schema and release dependencies
1. Introducing authenticated cross-account coaching **requires a secure backend identity + permissions + sync/sharing service**. The old local/iCloud-only model cannot by itself authenticate Google users and expose selectively shared data to a coach. Preserve offline-first local storage and existing personal iCloud conflict semantics where suitable, but define one authoritative ownership and reconciliation model for synchronized cross-account records. Do not make blanket claims that CloudKit alone supplies arbitrary coach-to-client access.
2. Minimum entities include `Account`, `VerifiedEmail`, `IdentityProviderLink`, `Role`, `CoachAthleteRelationship`, `Invitation`, `PendingClientEnrollment`, `ClientConfiguration`, `Permission/ConsentGrant`, `AuditEvent`, and stable identifiers for existing nutrition/training records. Data authorization must be scoped by record owner and active consent, with explicit read vs write capability and revocation enforcement.
3. Protect access tokens and sensitive client data in transit/at rest, prevent cross-tenant ID guessing/access, apply least privilege, implement server-side row/record access checks, and avoid embedding secret API keys in the iOS app. Store minimum personally identifying information. Include account deletion/export and comply with applicable privacy law and app-store requirements after concrete legal/platform review.
4. Where the athlete's HealthKit-derived information is displayed to a coach, obtain clear opt-in for sharing the resulting Logbook data. HealthKit permissions stay with the athlete and are never grantable by the coach. Validate Apple's rules for health-data use/storage/sharing prior to shipping; do not build unlawful/unsupported provider integration.
5. Sync must handle conflicting coach edits and athlete edits without last-write-wins data loss; preserve original manual-entry preference, offline queued changes, historical snapshots, pending invitations and revocation tombstones. Account migration for pre-existing anonymous/local Logbook data must preserve records and not create duplicate identities or delete history.

### 15.8 Required new acceptance tests
- **Splash/auth flow:** original ~3-second splash -> sign in/sign up screen for first launch/signed-out state; real Apple and Google provider sign-in, verified email path, role selection, subsequent signed-in launch, sign-out and session expiry. Confirm optional setup can be skipped *after* authentication.
- **Role-specific dock:** original five athlete icons and four Home pages unchanged; Coach shows Coaching action, opens real roster; test smallest supported iPhone sizes, safe areas, VoiceOver touch targets and all 20 theme placements (19 distinct designs; see visual addendum). No overlap or icon omission.
- **Help:** Settings opens Help, walkthrough works/restarts, FAQ search finds relevant answers, deep links target actual screens, core help works offline, content corresponds to shipped UI.
- **Invitations:** coach -> athlete existing-email invite; athlete -> coach email invite; correct identities; accept/decline, expired/duplicate/cancelled invites; no client data before explicit acceptance; email enumeration/rate-limiting checks.
- **Coach-created client:** preconfigured plans/nutrition/units -> invitation -> independently verified athlete account -> athlete consent and setup claim -> visible data on both sides; duplicate/retry/decline cases; no coach-owned passwords or silent account takeovers.
- **Client dashboard/edits:** correct selected client, accurate category summaries with missing-data states, edits persisted to athlete app, attribution and conflict handling, workouts/history snapshots/PR calculations stable, one client cannot see another.
- **Coach Mode OFF/ON:** OFF blocks further server-side reads and writes, revoked tokens do not work, offline queued coach writes are rejected, coach cached data cleared on reconnect, athlete keeps their data; ON re-enables only an authorized still-connected coach. Disconnection requires renewed consent to reconnect.
- **Security:** cross-account authorization negative tests on every API, invite guessing, role spoofing, stale access, provider identity linking, credential storage, secure backend sync, account migration and local offline recovery.

**End of binding consolidated product specification, including the post-review user-requested extension.**


## 16. USER-APPROVED THEME TAXONOMY — NOVEMBER 6 VISUAL ADDENDUM (SUPERCEDES OLD 16-THEME ROSTER)

The final user-specified category memberships are **Defaults (9):** Default; Classic White; Classic Dark; Classic Blue; Classic Green; Soft Slate; Soft Ivory; Graphite Linen; Pearl Mist. **Glass (6):** Black Glass; White Glass; Blue Glass; Grey Glass; Champagne Glass; Alpine Glass. **Featured (5):** Soft Ivory; Ember Dusk; Forest Studio; Aurora Pulse; Sandstone Minimal. “Classic” is the approved handoff renaming of the four Default colour variants to avoid confusing them with dedicated Glass assets. Soft Ivory intentionally appears in two categories, referencing the same theme ID and data, resulting in 20 placements and 19 distinct visual implementations. Do NOT create a second divergent Soft Ivory. Do not substitute the prior older 16-theme gallery; preserve that gallery only as archival reference.

### Theme appearance and asset authority

- The **LATEST_APPROVED_GLASS_SCREENSHOT.png** supplied by the user defines the named five designed Glass concepts; its thumbnails are only low resolution except for the featured Black Glass panel. Source proofs for the remaining four have a low-resolution limitation, not manufactured 'exact' assets.
- The bundled specialty / neutral posters and Apple-style five-color composite are earlier concept references. No rendered mockup authorizes changing widget geometry, Home content, icon semantics or dock navigation.
- Backgrounds should be abstract, softly blurred versions of theme motifs/colours rather than literal sharp mountain/dune/forest landscapes. The bundled generated `*_PROVISIONAL_BLUR.jpg` files are editable starter artwork, **not user-approved pixel-perfect replacements**.
- Theme consistency is global: themed app background, cards, header typography, icons within widgets, dock icons, rings, progress bars, action buttons, checkmarks and states. Avoid arbitrary multicolour/rainbow dock icons. Keep accessible distinction among macro metrics without introducing unrelated neon primary colours.
- The JSON tokens (`themes/tokens/theme_manifest.PROVISIONAL.json`) include starting colour/material values only. Every value is labelled **PROVISIONAL**; verify by native iPhone Simulator screenshot review before promotion to approved production design tokens. Missing true original colour sampling, source fonts/gradients or sharp assets cannot be treated as approved.
- THE FIXED HOME GRID CONTRACT IS UNCHANGED: four horizontally swipable pages; each 2 columns × 4 equal-square rows; small 1×1 square; medium 2×1 wide; large 2×2 square; example reference dimensions small 176×176, medium 360×176, large 360×360, gap 8; device-safe scaling preserves geometry; no vertical Home scrolling and original five-icon athlete dock. The generated promotional screenshots shown with wrong widget geometry or wording are *theme inspiration only*, not required screen layouts.
- Default is the standard app appearance; it must first pass the real, geometry-correct Daily Home implementation and acceptance review before applying the remaining themes.
- See `docs/CODEX_EXECUTION_PROMPT.md`, `audit/VISUAL_ACCEPTANCE_MATRIX.md`, and `themes/REFERENCE_INDEX.md` for exact workflow, traceability and review gating.
