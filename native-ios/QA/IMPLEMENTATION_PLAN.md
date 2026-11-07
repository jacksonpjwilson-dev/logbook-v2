# Default-first implementation plan

1. **Audit (done, source-only):** compare the existing Xcode source and test infrastructure against the v2 master specification; record runtime and visual evidence limits in `AUDIT_RESULTS.md` and `REQUIREMENTS_TRACEABILITY.csv`.
2. **Default geometry and shared tokens (implemented in worktree, not built):** use one square-cell dimension across both grid axes; apply only the new Default semantic tokens and provisional art; preserve old theme values/assets and existing persisted theme choices.
3. **Default content pass (partial):** render the required calorie ring and separate macro bars. Next review/fix the Habits and Daily Check-in detail, independently tappable regions, and any other §2.2 content discrepancies only after simulator inspection identifies concrete work.
4. **Training System Phase 2 (implementation in progress):** See `TRAINING_PHASE2.md` and the update at the top of `AUDIT_RESULTS.md`. Run #27 passed Daily geometry assertions on iPhone 16 and iPhone SE, but failed two assertions; fixes and Training additions remain pending a fresh CI run. iPhone 18 Pro was unavailable and is untested.
5. **User approval gate:** provide candidate PNGs, frame measurements and remaining discrepancies. Do not replace/add a protected visual baseline without explicit approval.
6. **Only after Default approval:** add the remaining v2 themes through the same token engine, one reviewable batch at a time, then proceed to detail screens and the broader feature/security audit. Keep the 19-unique-ID / 20-placement Soft Ivory deduplication from the specification.

## Scope exclusions for this gate

No HealthKit access (user declined it); no edits to `main`; no production or Firebase configuration; no rollout of the remaining v2 themes; no account/coaching backend or fabricated integration; no baseline approval; no data migration or destructive changes.
