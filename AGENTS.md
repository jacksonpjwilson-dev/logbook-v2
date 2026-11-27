# Codex operating guide — Logbook

## Identity and starting point
Logbook is a native iPhone-first app for food and nutrition, training, sleep, weight, supplements, habits, and progress. It is not an aviation logbook. At the start of each session, read this file, [`docs/CURRENT_MILESTONE.md`](docs/CURRENT_MILESTONE.md), the [canonical requirements tracker](native-ios/QA/REQUIREMENTS_TRACEABILITY.csv), and the relevant sections of the approved handoff before changing code.

## Authority and conflict handling
1. The user's most recent explicit product decision controls its stated scope. It supersedes an earlier decision only where they conflict.
2. The approved functional source is [`docs/handoff-v2/LOGBOOK_MASTER_SPEC.md`](docs/handoff-v2/LOGBOOK_MASTER_SPEC.md). Its visual companion files are in `docs/handoff-v2/`; the theme reference index records source quality and gaps. Original approved reference art takes priority over token estimates. Provisional tokens are not approvals.
3. `native-ios/QA/AUDIT_RESULTS.md` and `native-ios/QA/REQUIREMENTS_TRACEABILITY.csv` describe observed implementation status. Code presence alone is not proof.
4. Automated evidence is limited to the exact commit, devices, OS, tests and screenshots reported in `native-ios/QA/REPORT.md` and `docs/CURRENT_MILESTONE.md`.
5. Older handoff documents are historical. If they conflict with the v2 master or later user approval, keep the later authority and record the discrepancy; do not silently reinterpret it.

If two approved requirements conflict or an essential visual source is missing, document the conflict/gap and preserve existing behavior until resolved. Do not invent product requirements.

## Development rules
- Preserve working behavior; make incremental changes and implement complete workflows with real navigation, persistence, validation and error handling.
- Never replace working features with placeholders. Avoid unnecessary rewrites, dependencies, and architecture migration risk.
- Keep the offline-first core and data migration/recovery guarantees. Use synthetic test data, never production data.
- Do not commit credentials or expose secrets in output, logs or chat. Use secure platform storage and external configuration.
- HealthKit access is disabled by the user's explicit instruction. Do not request or enable it unless the user changes that instruction.
- Work on a development branch. Do not change production configuration or merge to `main` without explicit approval.

## Visual constraints
- Preserve four horizontally swipeable Home pages, in their approved order, and the fixed 2-column × 4-row grid.
- Preserve small 1×1, medium 2×1, and large 2×2 grid footprints, no Home vertical scroll, and the five-icon athlete dock. The November 27 user decision permits rectangular cells to fill the available width with 12–16 point side insets; it supersedes the earlier square-cell requirement.
- Follow approved reference content and appearance. Concept images are not permission to change layout or widget content. Do not propagate themes until Default receives explicit visual approval.

## Verification and reporting
- Distinguish `NOT STARTED`, `IN PROGRESS`, `IMPLEMENTED — UNVERIFIED`, `VERIFIED`, and `BLOCKED` in the tracker. Use `VERIFIED` only with requirement-appropriate evidence.
- Unit tests do not prove UI behavior; UI tests do not prove visual fidelity. Keep technical verification, screenshot comparison, physical-device verification and user's visual approval distinct.
- Record exact commit, device, OS, tests run, pass/fail/skip counts, screenshots and remaining limits. Never count unavailable or skipped tests as passes.
- After each substantial milestone update the tracker, `docs/CURRENT_MILESTONE.md`, and QA report. Use `docs/REQUIREMENTS_PROGRESS.md` for the generated summary.

## Session continuity
Resume the scope recorded in `docs/CURRENT_MILESTONE.md`; inspect the current branch and working tree before edits. Preserve pre-existing changes. Continue independent work while CI is pending, but do not claim unobserved results. See `docs/NATIVE_APP_DEVELOPMENT_WORKFLOW.md` for the milestone process.

## Automatic physical iPhone deployment
The user permanently authorizes this workflow for tasks that change application source code, UI, assets or functionality. Complete it autonomously without requesting routine deployment or push approval. Later explicit user instructions control their stated scope. Documentation-only changes do not trigger deployment.

1. Implement the requested changes while preserving unrelated working-tree changes and outstanding QA findings.
2. Run the relevant compilation and validation checks. Resolve build failures and regressions introduced by the task before deployment. Record pre-existing failures and unavailable checks accurately. Outstanding unrelated UI test failures or incomplete CI verification do not block an otherwise working device build.
3. Build and sign the updated application using the existing Apple Developer team and installed application identity. Use team `7HL7Y5SP24`, bundle identifier `com.logbook.7hl7y5sp24` and App Group `group.com.logbook.7hl7y5sp24`, with their existing widget and Watch companion identifiers. Preserve the app's features, themes, integrations and companion targets, including the current HealthKit permission policy.
4. Execute `ci/deploy-iphone.py` with `LOGBOOK_DEVELOPMENT_TEAM=7HL7Y5SP24` and `LOGBOOK_BUNDLE_ID=com.logbook.7hl7y5sp24`. The script performs the signed device build, installation and launch checks. Select the user's paired iPhone with `LOGBOOK_DEVICE_UDID` when needed. Prefer its available wireless connection, with USB as a fallback. Inspect the actual device connection and report the transport used; do not claim wireless deployment merely because the device supports it.
5. Install the signed update over the existing application, preserving user data. Never uninstall the app, reset its data, change its bundle identifier or App Group, or revoke signing certificates to resolve deployment issues. Do not install a build that failed compilation, signing validation or relevant checks exposing a broken application.
6. Verify successful launch and the script's check that the app remains alive for at least 15 seconds. Record the device, OS, source revision, build result and deployment evidence. Treat installation, launch survival and functional verification as distinct evidence.
7. Commit and push the completed task changes to the existing development branch, excluding unrelated or unverified working copies. Preserve the exact deployed source revision and describe any subsequent documentation-only commit. Leave the branch unmerged for review.
8. Report explicitly whether the updated application is installed on the user's iPhone, whether launch verification passed, the connection used, the published commit and any remaining gaps.

If the iPhone is unavailable, locked, disconnected or otherwise inaccessible, preserve the completed changes, finish independent validation, and commit and push the completed task scope. Clearly report that device deployment remains pending and identify the condition needed to resume it. Keep the existing installed application and its data intact. A failed installation or launch is pending remediation and must never be reported as a successful deployment.
