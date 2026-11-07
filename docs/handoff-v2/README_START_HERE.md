# Logbook — Codex Visual Handoff v2

**Status:** User-approved Logbook product requirements and new theme taxonomy; proposed design token/background values require user visual acceptance. **Native implementation not inspected in this handoff.**

## Read first
1. `docs/CODEX_EXECUTION_PROMPT.md` — paste the contents to Codex, with the full extracted folder accessible to it.
2. `LOGBOOK_MASTER_SPEC.md` — binding functional and screen requirements, including coaching and updated theme §16.
3. `themes/REFERENCE_INDEX.md` — reference images with quality/limitations.
4. `themes/tokens/theme_manifest.PROVISIONAL.json` — structured starting theme values, not verified screenshots.
5. `audit/VISUAL_ACCEPTANCE_MATRIX.md` and `CODEX_IMPLEMENTATION_AUDIT.md` — acceptance and test plan.

## Theme classes
- **Defaults (9):** Default, Classic White, Classic Dark, Classic Blue, Classic Green, Soft Slate, Soft Ivory, Graphite Linen, Pearl Mist.
- **Glass (6):** Black Glass, White Glass, Blue Glass, Grey Glass, Champagne Glass, Alpine Glass.
- **Featured (5):** Soft Ivory, Ember Dusk, Forest Studio, Aurora Pulse, Sandstone Minimal.
- 20 category placements / 19 unique themes. Soft Ivory intentionally appears in two categories as one actual theme.

## Important restrictions
- The approved layout is **not** the promotional images' layout. Never copy older Today/Workout Split cards, a mood check-in, unrelated fitness habit fields, or substitute Home/Progress dock icons from a generated poster.
- Original 5-icon athlete dock persists. Coach-specific addition is a separately audited feature.
- Every abstract background JPG is a **PROVISIONAL generated coloured blur**, not a guaranteed approved production asset.
- No fabricated pixel matching or screenshot acceptance. The latest glass screenshot's last four panels are only thumbnails: users must judge actual native screenshots and can supply high-res assets if strict fidelity is needed.
- Work on the real project within its Xcode workspace; this package does not contain the actual app source.

## Workflow
Audit existing repo -> geometry-correct Default -> simulator screenshots & user signoff -> shared token system -> 19-theme review -> complete functional/security tests.
