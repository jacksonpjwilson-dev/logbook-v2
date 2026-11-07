# LOGBOOK — CODEX IMPLEMENTATION AND VISUAL AUDIT
**Companion to:** `LOGBOOK_MASTER_SPEC.md`  
**Audit status:** READY TO RUN; current source repository and on-device behavior **NOT YET INSPECTED**.

## Immediate Codex instructions

Read `LOGBOOK_MASTER_SPEC.md` completely before editing code. Treat it as the consolidated signed-off product requirements, with explicit **VISUAL REFERENCE REQUIRED** blockers. The 88-decision design review is closed. The user subsequently added approved accounts, Help and Coaching requirements in master spec §15; treat these as binding changes, not a new round of design decisions. Do not invent other features or redesign approved elements. Inspect the existing code and original visual references, compile and run, then fill the audit below using evidence before implementing fixes.

Every audit finding must include: **requirement**, **status**, **source path and symbol**, **runtime evidence**, **test name/result**, **screenshot/reference pair**, **severity**, **fix**, and **retest**. `PASS` requires observed result, not assertion. Use statuses `PASS / PARTIAL / MISSING / BLOCKED / UNVERIFIED`.

## Audit matrix to populate

| ID | Audit area | Verification standard | Initial status |
|---|---|---|---|
| V01 | 20 theme placements (19 unique themes) | All current theme IDs installed and visually compared against available reference evidence; mark source-limited designs accordingly | UNVERIFIED |
| V02 | Home page structure | Daily / Training / Food / Progress & History, swipe/page dots | UNVERIFIED |
| V03 | Home geometry | 2×4 cell 8 capacity, 1×1/2×1/2×2, no vertical scroll | UNVERIFIED |
| V04 | Fixed athlete dock | Original five correct icons/actions, no obstruction; coaches gain a role-gated Coaching action without losing original icons | UNVERIFIED |
| V05 | Daily Home | 1 large + 1 medium + 2 small, precise content and separate taps | UNVERIFIED |
| V06 | Training Home | Two 2×2 large widgets, 2-column split tiles, full monthly calendar | UNVERIFIED |
| V07 | Food Home | 7-day trends/hydration + meals + streak + Easy Next | UNVERIFIED |
| V08 | Progress Home | Five-tab 30d chart + heatmap + PR + adherence | UNVERIFIED |
| V09 | Widget editing | Long press, cross-page drag, auto reflow, valid grid, reset | UNVERIFIED |
| T01 | Programs | Multiple named programs, independently persisted rotations | UNVERIFIED |
| T02 | Rotation behavior | scheduled save/skip, discard, rest, non-next session | UNVERIFIED |
| T03 | Switching draft programs | original association + correct original-program rotation | UNVERIFIED |
| T04 | Template editor | drag/drop, sets/reps/rest, supersets, custom exercise | UNVERIFIED |
| T05 | Exercise data types | weighted/reps-only/duration/weighted-distance | UNVERIFIED |
| T06 | Active UI | exact 5 columns, cards, top blue rest, bottom stats | UNVERIFIED |
| T07 | Timer | 90s default, pause, resume, skip, +15, Ready, superset rule | UNVERIFIED |
| T08 | Autosave | force-stop recovery, Resume banner, notes intact | UNVERIFIED |
| T09 | Completion | summary, incomplete save, correct rotation | UNVERIFIED |
| T10 | Multi-session dates | distinct History records/calendar day list and aggregates | UNVERIFIED |
| T11 | Historical corrections | independent session snapshots, stats/PR recompute | UNVERIFIED |
| T12 | PR eligibility | first baseline, later strict increase, max one/exercise/workout | UNVERIFIED |
| T13 | Progression prompts | optional, explicit acceptance, no template auto-edit | UNVERIFIED |
| F01 | Food sheet | Exactly Search / Barcode / Manual / Recent | UNVERIFIED |
| F02 | Food navigation | swipe, arrows, date picker, no gesture conflict | UNVERIFIED |
| F03 | Food search / sources | Canadian Nutrient File + OFF, provenance, offline cache | UNVERIFIED |
| F04 | Food input | verified serving, g/oz, corrections, favourites, recents | UNVERIFIED |
| F05 | Copy / recipes | snapshot historical values, Add/Replace matching | UNVERIFIED |
| F06 | Nutrition goals | date overrides, adherence math, missing vs failing | UNVERIFIED |
| F07 | Hydration | presets/custom, dated editing, footer quick-add | UNVERIFIED |
| H01 | Sleep | wake date, naps, duration override, quality, Health source | UNVERIFIED |
| H02 | Weight | lb/kg, previous measurement, history | UNVERIFIED |
| H03 | Supplements | schedule, dose, Taken/Undo, no-due neutral | UNVERIFIED |
| H04 | Habits | correct perfect-day + denominator + streak | UNVERIFIED |
| H05 | Reminders | four independent OFF defaults + due/completion suppression | UNVERIFIED |
| N01 | HealthKit | permission boundaries, two-way permitted mappings, dedup | UNVERIFIED |
| N02 | Watch | installed native companion, workout logging, timer sync/haptics | UNVERIFIED |
| N03 | Live Activity | real rest timer, expanded stats, Dynamic Island if supported | UNVERIFIED |
| N04 | Widgets | four Home types + four Lock types, real deep-link data | UNVERIFIED |
| N05 | Complications | four Watch face types and current state | UNVERIFIED |
| D01 | Offline database | complete functioning write/edit/read with no network | UNVERIFIED |
| D02 | iCloud conflicts | safe merge, true same-field conflict resolution | UNVERIFIED |
| D03 | Backup exports | portable full export/import, CSVs, backup validation | UNVERIFIED |
| D04 | Restore | merge/replace + safety backup + duplicate checks | UNVERIFIED |
| D05 | Deleted records | 30-day recoverable, recompute, expiry, sync tombstones | UNVERIFIED |
| S01 | Settings | six approved sections, all original controls | UNVERIFIED |
| S02 | Onboarding | original 3-second splash -> required account sign-in for new/signed-out users -> optional/skippable setup -> Home; returning sessions restored | UNVERIFIED |
| A01 | Identity providers | working Sign in with Apple, Google, email-based signup/signin/verification and account linking | UNVERIFIED |
| A02 | Role selection | coach/athlete roles, secure backend enforcement, default athlete dock retained | UNVERIFIED |
| A03 | Offline and migration | authenticated offline use, preserve existing local data via account migration | UNVERIFIED |
| C01 | Coach dock | Coaching icon on coach dock, fit/targets/layout verified on small iPhones | UNVERIFIED |
| C02 | Coach roster | real per-client statuses, searchable roster, identity-linked records | UNVERIFIED |
| C03 | Client dashboard | accurate mini progress for food/workouts/weight/sleep/habits, missing data distinguished | UNVERIFIED |
| C04 | Coach editing | configure/edit client plans, targets, food parameters, attribution and historical safety | UNVERIFIED |
| C05 | Invite flows | email invite existing client, athlete coach-email request and acceptance/decline | UNVERIFIED |
| C06 | Coach client signup | pending profile, preconfigure goals/workouts, athlete activation and consent without credential takeover | UNVERIFIED |
| C07 | Coach Mode toggle | revoke remote access on OFF; restricted ON resume; disconnect/re-consent | UNVERIFIED |
| C08 | Authorization and security | server-side role/record permissions, token expiry, cross-client isolation, revoked queued writes | UNVERIFIED |
| C09 | Multi-device coach sync | backed by secure service, offline reconciliation and consistent edit conflict handling | UNVERIFIED |
| S03 | Help & Support | settings entry, interactive walkthrough, searchable FAQs, offline help and accurate deep links | UNVERIFIED |
| Q01 | Automated tests | business logic, persistence, navigation, sync, UI screenshot | UNVERIFIED |
| Q02 | Physical devices | real iPhone and compatible Watch capability checks | UNVERIFIED |

## Audit deliverables Codex must produce

1. `AUDIT_RESULTS.md` with the matrix populated, grounded source references and proof.
2. `REQUIREMENTS_TRACEABILITY.csv` containing all granular requirements in the master spec, not only the grouped matrix above.
3. `VISUAL_DIFFS/` with original approved image, actual capture and difference for each Home page × relevant theme/device, including records of missing references.
4. `IMPLEMENTATION_PLAN.md` with ordered fixes, code ownership, test strategy and risks, clearly separating external capabilities from code problems.
5. Test reports: build, unit, integration, UI and actual device limitations; final documented PASS/PARTIAL/BLOCKED matrix.

## Strict failure conditions

- A passing build is not proof of working behavior.
- A SwiftUI preview is not proof of exact final UI or persistence.
- Mocked food data, mock workout sessions and fake metric charts are not production implementations.
- Using a fifth Home page, removing/reordering any of the five original athlete dock icons, changing the 2×4 Home geometry or moving the rest timer to the bottom violates requirements. A role-gated Coaching dock action for coaches is **expressly required** by §15; verify safe fit rather than rejecting it categorically.
- Theme count alone without correct original palette and visual evidence is insufficient.
- A nonfunctional Watch screen, a widget demo-only target or a simulated cloud sync is not completion.
- Do not silently coerce unresolved conflicts, overwrite historical nutrition snapshots or discard historical records.
- A dummy Apple/Google button, local-only simulated coaching data, client access before consent, or a sharing toggle that merely hides UI instead of revoking server authorization is a critical failure.
- Do not treat mandatory account authentication as justification to make the approved guided setup mandatory.
- Never assert implementation success before gathering concrete evidence.

## Extension-specific Codex execution requirements

1. Audit existing auth/splash and local database migration **before** adding providers or accounts. Identify backend provider strategy, entitlement, Apple review and Google OAuth setup, verified email handling and credential security. Mark unavailable credentials/console configuration **BLOCKED**, not implemented.
2. Build backend permission tests before exposing coaching roster. Treat patient-like wellness data as sensitive; explicitly audit coach invitation consent, record visibility, edits, suspension/revocation, client activation and separate user identity.
3. Screenshot and interaction-test **coach and athlete docks separately** against approved themes and all supported iPhone geometries; preserve four original Home pages and original athlete five-icon layout.
4. Audit Help & Support against actually implemented screens and ensure offline FAQ works.
5. Include account/coach server test suite and security report in final audit deliverables. Record the exact data-sharing model and which personal iCloud data remains private vs securely shared with a coach.

**Next engineering action:** execute this audit against the existing Xcode project. Only after findings are recorded, begin production fixes.


## Visual system gate for post-review theme catalogue

**Source of truth**: the new §16 of the master specification and `themes/REFERENCE_INDEX.md`; older 16-theme lists are historical and must not override the current three-class roster. User-referenced screenshot artwork is qualitative evidence, not a pixel-accurate source file for every scheme.

**Do not falsely pass**: any theme with missing or too-small reference cannot pass pixel-exact acceptance; instead mark `REFERENCE_LIMITED` and present screenshots for user acceptance. Correct user-approved geometry must be independently validated with measurable frame dimensions on device. Theme switching may not alter layout, data, widget interactions or the athlete five-icon dock. Coach-mode extra action must be tested separately.

**Required output per theme**: manifest id/name/category, provenance ref, screenshot on same device/simulator with same fixture, semantic token map, measured grid/dock frames, contrast and Dynamic Type check, screenshot differences list and PASS/FAIL/REFERENCE_LIMITED status. Follow `audit/VISUAL_ACCEPTANCE_MATRIX.md`.
