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
- Preserve four horizontally swipeable Home pages, in their approved order, and the fixed 2-column × 4-row square-cell grid.
- Preserve small 1×1 square, medium 2×1, and large 2×2 sizing, no Home vertical scroll, and the five-icon athlete dock.
- Follow approved reference content and appearance. Concept images are not permission to change layout or widget content. Do not propagate themes until Default receives explicit visual approval.

## Verification and reporting
- Distinguish `NOT STARTED`, `IN PROGRESS`, `IMPLEMENTED — UNVERIFIED`, `VERIFIED`, and `BLOCKED` in the tracker. Use `VERIFIED` only with requirement-appropriate evidence.
- Unit tests do not prove UI behavior; UI tests do not prove visual fidelity. Keep technical verification, screenshot comparison, physical-device verification and user's visual approval distinct.
- Record exact commit, device, OS, tests run, pass/fail/skip counts, screenshots and remaining limits. Never count unavailable or skipped tests as passes.
- After each substantial milestone update the tracker, `docs/CURRENT_MILESTONE.md`, and QA report. Use `docs/REQUIREMENTS_PROGRESS.md` for the generated summary.

## Session continuity
Resume the scope recorded in `docs/CURRENT_MILESTONE.md`; inspect the current branch and working tree before edits. Preserve pre-existing changes. Continue independent work while CI is pending, but do not claim unobserved results. See `docs/NATIVE_APP_DEVELOPMENT_WORKFLOW.md` for the milestone process.
