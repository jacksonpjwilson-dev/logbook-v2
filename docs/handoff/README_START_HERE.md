# Logbook v2 — Codex Handoff

**Handoff prepared:** 2026-10-25 (project state verified from the connected GitHub repository during this handoff)

## Mission
Finish the approved Logbook v2 mobile-first PWA by enhancing the existing `jacksonpjwilson-dev/logbook-v2` repository. Work in `logbook-v2-upgrade`, preserving all existing useful behavior. Prioritize correct, durable data first; then Training, Nutrition, Sleep/Weight/Supplements, Home/Widgets/Appearance, History and release validation.

## Read in order
1. `CODEX_START_PROMPT.md` — copy into your first Codex task.
2. `FUNCTIONAL_REQUIREMENTS.md` — the authoritative approved feature and behavior specification.
3. `DESIGN_AND_THEMES.md` — approved visual identity, screens and themes.
4. `ENGINEERING_AND_STATUS.md` — actual repository state, technical constraints, completed/pending work.
5. `TESTING_AND_ACCEPTANCE.md` — executable quality gates and regression cases.

**This package is the requirements handoff, not working source code.** Codex must inspect the repository itself, validate and update the facts in the engineering status, and continuously maintain a requirements-to-test traceability matrix.

## Absolute development boundaries
- Allowed: commits and automated testing on **`logbook-v2-upgrade`** only. The user authorized autonomous development on this branch.
- Forbidden without new, explicit approval: changes to **`main`**, merging, production deployment, access to real user data/accounts, using production Firebase in testing, importing or migrating real user data.
- Use **synthetic fixtures**, **Firebase emulators** and, if genuinely necessary, an explicitly isolated test Firebase project. Fail closed if an environment cannot be shown to be isolated.
- Preserve a rollback and independently verified recoverable backup before any later real-data migration. This requires separate authorization.
- Never mark a feature complete solely because code exists; demonstrate tests, working UI where applicable, and absence of regressions.
- Do not ask the user to approve each routine implementation decision. Escalate only changes to approved behavior, missing critical reference assets, external permissions, production actions, and meaningful safety blockers.

## Source-of-truth priority
1. Approved behavior and designs in this package, interpreted with the user's direct instructions when new ones exist.
2. Current GitHub code for what **exists now** (not what was approved).
3. Test evidence for what **actually works**.

When references conflict or details are underspecified: preserve user-visible functionality, choose conservative reversible behavior, and disclose assumption. No guessing on historical record identities or nutrition unit conversions. Visual references for the exact 16 themes were user-supplied earlier in ChatGPT and **are not bundled** here; retrieve them from source chat if possible, or request those images before claiming exact visual fidelity. Existing old colorways are NOT an acceptable substitute.

## Key URLs
- Repository: https://github.com/jacksonpjwilson-dev/logbook-v2
- Development branch: https://github.com/jacksonpjwilson-dev/logbook-v2/tree/logbook-v2-upgrade
- Main baseline at handoff: `278f0936b8a8f8f4b39bd6fbbe2dc72c961b3f32`
- Existing PWA code: `preview-widget/`
- Stage 0 baseline audit: `docs/STAGE0_BASELINE.md`
- Stage 1 test instructions: `stage1/README.md`
- CI workflow: `.github/workflows/stage1-synthetic.yml`

## Outcome definition
A validated, polished, local-first Logbook v2 implementation meeting every material feature requirement, with a self-contained acceptance report and remaining limitations. Stage 1 signoff must precede reliance on production-equivalent data workflows; Stage 2+ can follow autonomously within the approved development branch when gates pass. **No production release without explicit approval.**
