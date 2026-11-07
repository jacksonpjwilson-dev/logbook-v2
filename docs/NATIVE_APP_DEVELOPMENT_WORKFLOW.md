# Native Apple app development workflow

Use this workflow for Logbook and future native apps. It is intentionally lightweight; keep each stage proportionate to the app.

## 1. Audit
Inspect the existing repository, branch, working tree, targets, data store, migrations, navigation, dependencies, tests, build configuration, screenshots and native capabilities. Read the current milestone and issue register. Write down what works, what is partial/missing, and the evidence. Do not rewrite an existing app before auditing it.

## 2. Requirements
Maintain one approved master spec and canonical tracker. Record user-approved behavior, acceptance criteria, edge cases, offline/privacy constraints, dependencies and later amendments. Label assumptions separately. Link each implementation change and test to stable requirement IDs. Resolve conflicts explicitly; never silently overwrite an approval.

## 3. Visual design
For important screens, inventory source references and their quality. Specify content hierarchy, geometry, type, spacing, colors, symbols, materials, interaction regions, safe-area and Dynamic Type constraints. Use actual assets/tokens when available; mark estimates provisional. Capture native simulator screenshots for review before broad theming. Do not take content or layout from conceptual/promotional images unless explicitly approved.

## 4. Integration validation
Before relying on a service, check API availability, platform rules/capabilities, authentication, rate/cost limits, licensing, offline behavior, and background execution. Test access safely and document account/capability setup. Keep secrets outside the app binary and repository. Implement the offline/core path independently where required. Ask the user only for credentials, account/capability choices, or policy approval that they must provide; never ask them to paste secrets into chat.

## 5. Implementation
Work in connected user workflows, not isolated screens. For each milestone: restate scope from the spec; inspect dependencies; implement model/business rules, persistence and migration; wire real navigation and UI; handle empty/error/offline states; add focused tests; run relevant checks; fix failures; inspect screenshots; update tracker, issue register and current milestone. Keep changes on an isolated development branch and preserve unrelated work.

## 6. Verification
Run build, relevant unit tests, integration tests and UI tests. Review failed logs and result bundles. Repeat affected tests after fixes. Record tests as passed, failed, skipped, or not run, and attach device/OS/commit. A workflow's overall success can include skipped matrix jobs; inspect each job. Unit tests prove business rules, UI tests prove only the exercised paths, screenshots prove rendering only, and physical devices prove their own platform behavior.

## 7. Visual review
Capture actual simulator screenshots at representative compact and large sizes, with deterministic synthetic fixtures. Compare geometry and component content to approved references; inspect text clipping, safe areas, keyboard, scrolling, touch regions, contrast, typography and Dynamic Type. Preserve candidate screenshots separately from protected baselines. Ask for visual approval before marking a design approved or propagating Default styling to other themes.

## 8. Device beta
When agreed beta requirements pass, sign a development/TestFlight build. Verify permissions, notifications, background behavior, widgets, Live Activities and device-only integrations on actual hardware. Test upgrade, migration, offline launch, recovery, export and account logout. Document unavailable device/capability tests as unverified. Do not publish/release or migrate real data without authorization.

## 9. Milestone closeout
Use the standardized format in `docs/CURRENT_MILESTONE.md` and `native-ios/QA/REPORT.md`: completed/verified, implemented but unverified, remaining, blocked, exact tests/device/commit, visual approval, open defects and next milestone. Do not invent completion percentages.
