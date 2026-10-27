# Asset provenance

- `reference-wallpapers.png`: generated with the image editing tool from the three attached authoritative sheets. The prompt removed UI, device framing, notches, text and share overlays and requested the 16 selected backgrounds in the exact approved order. No unrelated theme was selected. This is reconstructed art, not an original-source extraction or proof of exact pixel matching.
- Original filenames and SHA-256s are in `docs/handoff/VISUAL_ASSET_MANIFEST.json`; selected panel mapping is in `docs/handoff/VISUAL_REVIEW.md`.
- Output SHA-256: `a41216b3f34b88500862142c79741158882a4bc85902d133652c64e3870759de`.
- Atlas: 1024×1536, four columns/four rows, no gutters. Approved order is `themes.js` list order. CSS background-position selects a tile without destructive cropping. Scenic fidelity and final appearance require human visual acceptance; the atlas is not claimed to be the unavailable original wallpaper files.
- `icon.svg`: source-code vector implementation of the approved black rounded-square, bold white angular L direction. PNG variants render that SVG through `build-icons.cjs` at 180/192/512px. Exploration-board alternate app icons are not used.
