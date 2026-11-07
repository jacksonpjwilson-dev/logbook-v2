# Logbook development lessons

This note records process lessons supported by the available handoffs, audits, commits and CI runs. It does not claim to recover every original conversation or design decision.

## Requirements management
The initial handoff described approved behavior, but later review found important design/content decisions had been omitted or summarized incorrectly. That led to repeated corrections after implementation. Keep one versioned master spec and a traceability row per stable requirement; record later user changes as dated/scope-limited amendments. Preserve the previous decision and explain precisely what the amendment supersedes. Treat an audit's source inventory as evidence of code location, not proof of behavior. Split “implemented” from “verified” and from user visual approval.

## Visual implementation
Promotional theme images included examples whose layout/content were not authoritative. The v2 handoff explicitly separates style inspiration from the fixed 2×4 widget grid and master-spec content. Translate approved geometry into constraints and frame assertions, then compare full-resolution native Simulator captures for content density, typography, spacing, materials, icon consistency and safe areas. Do not infer pixel-exact tokens from low-resolution thumbnails or provisional blur assets. Use a human approval gate before accepting baselines or propagating the Default theme. Screenshots from CI are evidence of rendered output, not evidence of aesthetic acceptance.

## Native testing and CI evidence
- Daily Home QA run #26 failed compiling on iPhone 16 and SE. Logs reported a Swift argument-order error (`minWidth` before `maxWidth`) and an invalid `.accessibilityFrame` member chain; tests were cancelled before execution (0 ran). A green workflow summary from a skipped simulator job must not be misread as test success.
- Run #41 executed tests but exposed a real UI inconsistency: the footer timer advanced while the floating top rest card stayed at “Ready.” The display was reading a stale captured timer value. The fix reads the current persisted timer state during timeline updates; run #42 passed the active-workout terminate/relaunch/resume UI test on iPhone 16 and SE.
- Simulator availability varies by GitHub runner. Run #42 skipped iPhone 18 Pro because that simulator was unavailable; mark it untested. Preserve run-specific simulator model and OS evidence.
- UI tests need stable accessibility identifiers/frames and should test behavior without brittle keyboard timing. Do not “fix” a failing measurement by weakening its assertion; inspect the hierarchy and actual screenshot/video.
- Repository-level persistence tests and OS-level app termination/relaunch prove different things. Keep both where recovery is required.

## Architecture and data integrity
The Training specification requires program-owned independent rotations, durable workout drafts with origin program/template snapshots, anchored rest-timer state, and editable completed records whose derived volume and PRs recalculate. Keep durable facts in the store/repository, derive summaries consistently, and test migration and reopen behavior with isolated fixtures. Historical edits and deletion/restore must recompute derived PRs rather than leave stale cached results. Preserve distinct session identities for multiple workouts on the same date. Do not treat a UI label or screen as proof that these rules hold.

## Reuse for future apps
Freeze product contracts before UI implementation; validate external APIs/capabilities before building around them; use small but complete vertical milestones; keep synthetic data and exact CI evidence; and make visual approval explicit. Reuse only mature components with clear boundaries. Do not force unrelated apps to share a backend or data model merely because they share SwiftUI.
