# Default visual comparison status

## Current real Simulator evidence

The latest candidate captures were produced from test commit `dfd8678efdc354d47aac0e549850a46bae533cdd` on iPhone SE (3rd generation) and iPhone 16 / iOS 18.5 in [GitHub Actions run #80](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42430593049). Each device passed 34 unit + 7 UI tests. The iPhone 18 Pro QA step was skipped and remains untested.

- Gallery HTML: `/workspace/logbook-training-review-run80/index.html`
- Downloadable gallery ZIP: `/workspace/logbook-training-review-run80.zip`
- There are 24 actual XCTest PNG captures (12 per available device). They are candidates only, not approved or protected baselines.

## Default reference comparison

- `themes/references/defaults/default_CONCEPT.png` and `default_COMPOSITE_CROP.png` are visual-style references, not exact pixel baselines. Their promotional widget content and layout are not copied.
- The current Daily candidate uses the pale neutral/blue background, rounded translucent card surfaces, blue progress accents and five-icon dock. The four Daily widgets remain in the approved order and fit above the dock on both tested simulators.
- Daily geometry from run #80: iPhone SE large 212.35 × 212.35 pt, medium 211.5 × 101.25 pt, small ~102 × 102 pt; iPhone 16 large 268.52 × 268.52 pt, medium 267.5 × 129.25 pt, small 130.18 × 130.18 pt.
- Training Home has a large empty region when the active program contains one real workout. This is consistent with master spec §2.3, which requires unused positions to remain empty rather than fabricating workouts. The eight-workout QA candidate fills the fixed arrangement. Do not populate those cells with invented content or change the exterior geometry without a new approved specification.
- Active Workout and completion/history sheets use native grouped/light surfaces that differ from the translucent Home surface. No original screen-specific reference was supplied for these details, and no visual approval has been recorded. The completion sheet also has a large unused upper area; leave it for user review before changing presentation.

The supplied original theme binaries are available in the local handoff workspace but are not mirrored into GitHub. Their exact 26 filenames and destination folders are in `docs/handoff-v2/themes/REFERENCE_INDEX.md`; the four White/Blue/Grey/Champagne Glass references are thumbnail-only.

No theme baseline has been approved, overwritten or added. Do not propagate the remaining themes until Default receives explicit visual approval.
