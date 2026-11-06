# Default visual comparison status

No actual iOS Simulator captures are present in this workspace. The environment is Linux and has no Xcode or iOS Simulator, so a screenshot comparison cannot be produced without misrepresenting an illustration or simulator-less render as app evidence.

Available v2 visual references:

- `themes/references/defaults/default_CONCEPT.png` — generated concept / promotional style reference only.
- `themes/references/defaults/default_COMPOSITE_CROP.png` — cropped composite style reference only.
- `themes/backgrounds/default_PROVISIONAL_BLUR.jpg` — provisional blurred starter image bundled as the Default background candidate.
- `themes/tokens/theme_manifest.PROVISIONAL.json` — provisional palette/material values, not visually approved tokens.

After running the simulator script, export actual app captures to `native-ios/QA/artifacts/` and create a side-by-side/difference image here. Mark differences as `REFERENCE_LIMITED` wherever only concept or cropped artwork is available. No screenshots in this directory are approved baselines.
