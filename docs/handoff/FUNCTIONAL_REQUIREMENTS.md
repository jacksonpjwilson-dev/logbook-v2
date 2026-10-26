# Authoritative Functional Specification — Logbook v2

All requirements below are approved project decisions, not necessarily implemented. Each ID should be mapped to code, tests, verification status and screenshots by Codex. Do not silently drop features.

## Global product and data guarantees
- **G01** Mobile-first premium iPhone PWA for gym/training, nutrition, hydration, sleep, weight, supplements and longitudinal history. Preserve existing useful features, migrate safely.
- **G02** Local-first data persistence, offline edit queues and automatic cloud sync where configured; contextual offline/pending/synced/conflicted status.
- **G03** Smart three-way conflict detection: auto-merge independent edits, preserve BOTH sides of incompatible edits to the same record and offer side-by-side comparison with explicit user choice; do not block unrelated record sync.
- **G04** Versioned records with 30-day recoverability for modifications/deletions; ordinary historical logs persist indefinitely unless intentionally deleted. Undo appropriate individual deletions and restoration actions.
- **G05** Automatic but protected and reversible schema migrations: durable verified pre-migration backups, independent validation/counts/hashes, rollback on failure; ambiguous legacy identities preserved exactly and flagged for review rather than guessed. No production migration without separate approval and verified recoverable real-data backups.
- **G06** Restore Summary Dashboard previews category counts and changes; explicit restore confirmation, persistent rollback snapshot and Undo; avoid reintroducing tombstoned/deleted records unexpectedly.
- **G07** Permanent stable IDs and explicit version/snapshot separation across entities: exercise, template, workout, food definition, food log, sleep, weight, supplement schedule/dose. Display-name renames or definition changes never retroactively alter completed histories.
- **G08** No fabricated analytics observations: missing date != zero measurement; only actual completed sets/logged quantities/recorded sleep/weight count. Date and timezone attribution must be stable across travel/day boundaries.
- **G09** Responsive UX, reduced-motion support, accessible controls, suitable iOS PWA offline and session recovery; security/Firestore rules user-isolation and explicit test/production separation.

## Training — rotation and templates
- **T01** Numbered up-to-7/8 workout rotation as configured; rest days do not advance. Only explicit **Finish & Save** advances. Discard does not. One active session at a time.
- **T02** If a later workout is explicitly completed (e.g., #4 when #2 was next), intermediate positions are recorded as *skipped rotation positions*, never completed workouts. Next becomes position immediately after completed workout, wrapping to 1.
- **T03** Editing historical workout dates/sets never silently changes current rotation. If correction would affect rotation, show impact and offer a separate **Update Rotation** action; preserve event-based completion/skip history.
- **T04** Templates permanently versioned, reorderable exercise cards and superset group support. In-session edits do not mutate permanent templates; subsequent template edits do not mutate active sessions or historical snapshots.
- **T05** Starting a session snapshots template identity/version, exercise IDs, ordered plan, all sets, superset groups, and necessary names. Permanent exercise IDs make renamed exercises and deletion-safe graphs/history possible; preserve original display names as historical snapshots. Legacy ambiguous mappings reviewed rather than guessed.
- **T06** Workout management screen: Workout First, prominent **Featured Up Next** card, expandable Workout Split cards, Monday–Sunday (configurable target) weekly activity strip based on **actual completed workouts**, Expandable Recent Session Cards, dashboard section shortcuts, collapsible stats for workout count/completed sets/volume.

## Training — active session UI/behavior
- **T07** Expandable visual exercise cards with thumbnail where available and fallback. Five columns without horizontal scrolling: **Set | Previous | Weight | Reps | Complete**; previous sets prefills from real equivalent historical exercises, but never premarked done.
- **T08** Exercise Picker hybrid search/recent/favorites/muscle/equipment filtering, direct session add. Optional progression suggestions use appropriate increments and are never forced.
- **T09** Linked substitution cards: keep completed sets of original exercise under original ID, retain unfinished plans, add replacement as separate exercise with its own ID and sets. Show **Substituted with** linkage and **Replacement Preview**; do not change template. Correct independent volume/PR attribution.
- **T10** Unified Superset Container groups 2+ exercises; round indicators and independent sets. Rest timing starts after completing a full superset round.
- **T11** Sticky progress/elapsed header, expandable rest timer bar with ±15 sec, pause/skip, session-only base rest-duration customization; compact action bar Add Exercise / Finish & Save / More; Exercise Jump Menu. Smart collapse/navigation for long workouts without losing context.
- **T12** Persistent Resume Workout Banner appears on Home when unfinished session exists; Home opens normally. Resume restores exact exercises, completed/incomplete sets, notes, substitutions, superset and timer state; banner persists until Finish or Discard. Timer uses absolute timestamps, not stale intervals.
- **T13** Explicit **Manual Pause & Resume**: track total wall-clock elapsed from start to Finish and active duration excluding explicitly paused periods; backgrounding/locking does not auto-pause. Workout pause also pauses rest countdown; both persist through closure.
- **T14** Completion policy: fully complete -> Workout Summary immediately. Incomplete -> confirm showing completed/incomplete counts and Return / Finish & Save. Saved session retains **all** planned unfinished sets and completed flags; only completed valid working sets count in volume/PR. Explicit Finish & Save advances rotation.
- **T15** Workout Summary: duration (active+elapsed), completed sets, volume, achievements, and comparison to a legitimately comparable prior session; no misleading comparison when templates/conditions unsuitable.
- **T16** Correctable completed workouts with explicit Save Changes confirmation, same historical session identity, 30-day recovery version, analytics/volume/PR recalculated from corrected data, original template snapshot preserved and conflicts reviewed.

## Training — progress/PR/history
- **T17** PR categories: actual heaviest weight, rep-specific PRs, Epley estimated 1RM using completed sets **1–15 reps**; exactly 1 rep equals actual lifted weight. Sets of 16+ excluded ONLY from estimated 1RM, not volume/actual PRs. High-rep estimates visibly labeled as estimates; preserve formula/rep-limit version used for historical PR achievements.
- **T18** One subtle consolidated premium PR celebration **per qualifying completed set**, listing all PR categories achieved. Avoid multiple overlapping celebrations. PR heaviest/rep-specific attribution per permanent exercise ID; muscle volume uses accurate primary muscle mapping, not display name matching.
- **T19** Exercise detail analytics with actual weight/estimated 1RM/reps/volume chart switching, interactive ranges and expandable real session history.

## Nutrition — daily dashboard and logger
- **N01** Nutrition Summary First: calories remaining/progress plus three macro cards and daily progress; collapsible nutrition summary and custom numbered meal cards with expandable individual food rows.
- **N02** Hybrid Add Food Controls: prominent top Add, meal-scoped mini Add, compact floating + while scrolling; section shortcuts Nutrition/Water/Meals.
- **N03** Hybrid Food Logger: compact quick picker for recent/favorites/search; expandable full search including personal foods, verified external search/Open Food Facts barcode, and manual entry. Respect missing/offline external data.
- **N04** Detailed Food Rows kcal/protein/carbs/fat/serving/source; live nutrition preview for each editable quantity.
- **N05** **Mandatory explicit quantity confirmation on EVERY food addition**, including favorites, recent, meal copy, saved meals, and external/barcode/manual choices. Saved meal add must allow individual ingredient quantity confirmations; no silent auto-add based on default quantity.
- **N06** Only mathematically verified unit conversions within compatible families (mass, volume, serving or count when food-specific factors exist); never infer density or grams-per-piece without evidence. Support user correction and full unit context.
- **N07** Every logged food has an immutable nutrition snapshot and quantity/unit at time of logging. Edits to personal food definition or saved meal do not retroactively alter old log entries; explicit historical corrections do recalculate summaries.
- **N08** Custom calorie/protein/carbs/fat targets with effective dates; future goal edits do not rewrite past targets.
- **N09** Adherence and nutrition streak: bulking = at least **90%** calorie AND at least **90%** protein target; cutting and maintenance = calorie within **90–110%** and protein at least **90%**. Green qualified day, red logged-but-not-qualified, gray missing. Today provisional. Historical corrections retroactively recalculate legitimate streaks.
- **N10** Hydration separate from streak: +250/+500/+750 mL/custom amounts; log mL by local date, avoid double counting, Undo supported, collapsible hydration UI.
- **N11** Easy Next suggestions based on observed habitual foods and remaining calorie/protein, never auto-add or bypass quantity confirmation.
- **N12** Historical food logs editable with confirmation as needed, deletion Undo and safe handling of bulk actions; no retroactive changing immutable original snapshots unless explicitly editing an entry.

## Sleep and daily check-ins
- **S01** Combined **Sleep & Check-ins** dock app overview: large Sleep section and side-by-side Weight/Supplements check-ins, each opening dedicated detailed dashboards.
- **S02** Sleep logging with bedtime and wake time, wake-date anchoring, derived duration, optional explicit manual duration override; visual timeline bottom sheet.
- **S03** Forward-only sleep goal (hours+minutes) and real sleep consistency/graphs over 7/30 existing records only. Never insert missing sleep as zero.
- **S04** First-open Daily Check-in Card Overlay once per local day with optional Sleep/Weight; skip/dismiss persists. Midday missing-sleep follow-up without repeated harassment.

## Weight
- **W01** Exactly one official weight measurement per local date, lb/kg entry and display, versioned edits, confirmation on replace; deletion Undo.
- **W02** Hybrid Quick Entry numeric field and stepper, prior measurement comparisons, dedicated analytics chart; no artificial measurements.
- **W03** 7-day rolling trend only when **at least 3 distinct actual measurements within the trailing 7 days**; otherwise show insufficient-data state.

## Supplements
- **U01** Supplement list, daily/weekday/**completed workout day** schedules, each schedule versioned forward-only (do not rewrite history).
- **U02** A dose is Taken **only if user explicitly marks it**. Zero scheduled doses counts as satisfied for day-habit status (do not show an error).
- **U03** Adherence denominator is actual scheduled doses, not mere calendar days; historical taken-state corrections supported.
- **U04** One optional chosen-local-time end-of-day reminder when scheduled doses incomplete; honor available platform notification/Do Not Disturb constraints. No unsupported promise of guaranteed background execution.

## History and calendar
- **H01** Five History categories: Overview, Training, Body, Nutrition, Sleep. Balanced Overview with four cards, metric graph, heatmap, PR summaries.
- **H02** Interactive accurate 7D/30D/90D/All/custom ranges; optional previous equivalent period overlays only if meaningful. No invented zero observations.
- **H03** Shared activity calendar with modes Training/Food/Check-in and expandable selected-date details; distinguish skipped workout rotation positions from actual activity.
- **H04** Cross-feature reports use the same source of truth and stable local-date attribution; historical corrections propagate into analytics without silently rewriting unrelated records.

## Notifications, integrations and UX
- **X01** Contextual sync/offline/error messaging without blocking logging; optional haptics only when supported and accessibility respected.
- **X02** Apple Health import is optional/feasibility-dependent. Manual functionality must be complete even if no native bridge is available. Do not pretend a browser can directly read HealthKit.
- **X03** Signed-in cloud account isolated per user; Firestore rules/server security verified (client checks insufficient), no keys/secrets in code or logs.
- **X04** Settings for Appearance, Home Screen, Fitness & Nutrition, Tracking Preferences, Data & Backup, with deep pages and search as approved.

## User approval boundaries
- All above functional decisions have been approved in conversation. Small implementation choices may be resolved autonomously if they preserve these rules.
- The user approved autonomous work on `logbook-v2-upgrade` but did **not** authorize production merge, deployment, real-data access, or real-data migration.
