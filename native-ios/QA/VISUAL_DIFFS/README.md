# Default visual comparison status

## Actual simulator evidence

Four real simulator PNG candidates were captured on iPhone 16 / iOS 18.5 from tested commit `9d6a724655218de42f0f4b70f66f9be37c7db12e` in [GitHub Actions run 42274999088](https://github.com/jacksonpjwilson-dev/logbook-v2/actions/runs/42274999088). The run passed 7 tests and reported no missing asset warnings. The downloadable review gallery contains Daily, Training, Food, and Progress & History. No screenshot is a protected baseline.

## Default reference comparison

- `themes/references/defaults/default_CONCEPT.png` and `default_COMPOSITE_CROP.png` are concept/promotional visual-style references, not exact pixel baselines. Per the handoff, their widget layouts and placeholder content were not copied.
- `themes/backgrounds/default_PROVISIONAL_BLUR.jpg` is provisional background artwork, not the final approved source. It loaded in the latest simulator run.
- `themes/tokens/theme_manifest.PROVISIONAL.json` explicitly labels palette/material estimates as provisional.

The captured Default candidate uses the pale, blurred blue background, rounded translucent pale-blue cards, dark blue text, and blue accents. Its layout was changed to the master-spec grid and correct Daily widget order. Because there is no approved full-screen Default image or exact color/material values, pixel-difference scoring against the concept would be misleading. The final visual decision remains with the user.

## Measured geometry and visual findings

The iPhone 16 capture shows a large square Calories & Protein Remaining card, a full-width medium Next Workout card, and two small square cards. All four are above the fixed five-item dock. See `AUDIT_RESULTS.md` for exact point frames. The Daily small-card header now fits; other pages visibly contain generic or incomplete widget content and remain audit-only. Daily Habits/check-in content and Next Workout details need implementation against the master spec in a later approved scope.

No theme baselines have been approved, replaced, or added. Do not implement remaining v2 themes until the user approves this Default candidate.
