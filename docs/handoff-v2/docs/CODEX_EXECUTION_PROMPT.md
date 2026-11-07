# CODEX EXECUTION PROMPT — COPY INTO CODEX

You are implementing and auditing the **existing** native Logbook iOS/watchOS project. Use the attached `Logbook_Codex_Visual_Handoff_v2` directory or zip as the binding handoff package. Do not assume any feature is working simply because it appears in a UI screenshot or spec.

## STOP/READ BEFORE MODIFYING CODE
1. Read `LOGBOOK_MASTER_SPEC.md` in full, including §15 (auth, help, coach mode) and §16 (new theme taxonomy). Read `CODEX_IMPLEMENTATION_AUDIT.md`, `themes/REFERENCE_INDEX.md`, `themes/tokens/theme_manifest.PROVISIONAL.json` and `audit/VISUAL_ACCEPTANCE_MATRIX.md`.
2. Inspect the actual Xcode repository, app targets, SwiftUI views, assets, persistence, tests, simulator set-up, signing, extensions, HealthKit, watchOS, authentication/backend and current screenshots. **Audit first, do not blindly overwrite existing working code or redesign the interface.**
3. Produce a requirement-to-implementation matrix with `IMPLEMENTED_AND_TESTED / PARTIAL / MISSING / BLOCKED / REFERENCE_LIMITED` and code/test/screenshot evidence. Clearly distinguish existing code from intended work. Do not say 'done' based only on a build.

## GATE 1: BUILD DEFAULT FIRST
4. Preserve exactly four horizontally swipable Home pages and the ORIGINAL athlete dock icons Training, Food, History, Sleep & Check-ins, Settings. The coaching access extension must not silently replace the athlete dock.
5. Enforce grid: 2 columns × 4 equal square rows, no vertical Home scroll. Small=1×1 square; medium=2×1 full-width with single-row height; large=2×2 square. The correct Daily Home is large top Calories & Macros Remaining, medium Next Workout below, two square bottom Habits and Daily Check-in. Preserve the individually tappable subregions, calorie ring, separate macro bars, Next Workout details, habits streak and check-in content in the master spec. Other three Home pages have their separately specified widget layouts.
6. Implement `Default` with shared semantic tokens, reusable theme-aware icon, text, dock, ring, bars, cards, background system and test fixture data. Do NOT recreate generated promotional screens literally—they contain outdated/incorrect widgets. Use only their colours/material inspiration.
7. Capture full iPhone Simulator screenshots for Default Daily/Training/Food/Progress & History, plus active workout, Food Log, Settings and Coach roster (if implemented). Report device, simulator, OS version, run configuration and exact screenshot paths. Measure frame rectangles and show that large/small squares, medium width/height and dock/safe areas pass. Provide the screenshot output to the user for visual sign-off BEFORE multiplying themes.

## GATE 2: THEME IMPLEMENTATION
8. Create ONE consistent theme engine with semantic design tokens and shared surfaces so all 19 distinct theme IDs render the **same approved screens**. Theme category menus: Defaults 9, Glass 6, Featured 5; Soft Ivory is one theme ID in both Defaults and Featured, not a duplicated variant. `Classic White/Dark/Blue/Green` are distinct from White/Black/Blue Glass.
9. `theme_manifest.PROVISIONAL.json` is NOT exact approved art. Treat palette, blur, opacity, radii and suggested font choices as draft starting values. Reference-specific screenshot panels define visual intent; identify missing or low-resolution originals as `REFERENCE_LIMITED`. Bundle starter blurred backgrounds as provisional only. Match card/glass/dock/icon/ring/bar colours cohesively, not random rainbow colors.
10. After Default visual approval, capture identical fixture/device screenshots for **all 19 unique themes** in Daily Home; then visual checks of all other three Home pages for each theme, plus representative detail screens. Preserve contrast, icons and legible text in all appearances. Provide theme grid contact sheet and links to full-resolution simulator screenshots. The acceptance artifact is a screenshot of the **running native app**, not another AI-generated conceptual image.

## GATE 3: FUNCTIONAL/SECURITY AUDIT
11. Run all critical tests from the existing master + audit: Food, PR/recomputation, multiple programs, rest timer, offline recovery, data consistency, Watch/Live Activities, HealthKit, cloud conflicts, full backup, sign-in, coach permissions & revocation. Any unavailable integration must be `BLOCKED` with reproducible explanation. Never fake a feature to pass UI snapshots.
12. Keep separate implementation priorities and blocked work; provide exact file diffs/commits and runnable tests. Do not make feature-scope changes or declare signoff without user approval. If source art is insufficient for strict equality, explicitly ask for higher-resolution assets or request visual approval of the best-fit screenshot.

## FIRST RESPONSE TO USER
Return: (a) repo findings, (b) implementation matrix, (c) existing screenshot inventory, (d) deviations from geometry, (e) specific first Default theme fix plan, and (f) exact commands/tests to validate it. Only then begin safe implementation.
