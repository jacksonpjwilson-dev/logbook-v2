# Theme reference index and provenance

Theme screenshots are **STYLE REFERENCES ONLY**. None overrides approved 2×4 square-cell Home geometry.

| Category | UI name | Unique ID | Reference condition |
|---|---|---|---|
| Defaults | Default | `default` | Generated style concept / promotional mockup |
| Defaults | Classic White | `classic-white` | Generated style concept / promotional mockup |
| Defaults | Classic Dark | `classic-dark` | Generated style concept / promotional mockup |
| Defaults | Classic Blue | `classic-blue` | Generated style concept / promotional mockup |
| Defaults | Classic Green | `classic-green` | Generated style concept / promotional mockup |
| Defaults | Soft Slate | `soft-slate` | Generated style concept / promotional mockup |
| Defaults | Soft Ivory | `soft-ivory` | Generated style concept / promotional mockup |
| Defaults | Graphite Linen | `graphite-linen` | Generated style concept / promotional mockup |
| Defaults | Pearl Mist | `pearl-mist` | Generated style concept / promotional mockup |
| Glass | Black Glass | `black-glass` | Large screenshot panel from latest user supplied image |
| Glass | White Glass | `white-glass` | **Thumbnail only — exact-match reference limited** |
| Glass | Blue Glass | `blue-glass` | **Thumbnail only — exact-match reference limited** |
| Glass | Grey Glass | `grey-glass` | **Thumbnail only — exact-match reference limited** |
| Glass | Champagne Glass | `champagne-glass` | **Thumbnail only — exact-match reference limited** |
| Glass | Alpine Glass | `alpine-glass` | Generated style concept / promotional mockup |
| Featured | Soft Ivory | `soft-ivory` | Generated style concept / promotional mockup |
| Featured | Ember Dusk | `ember-dusk` | Generated style concept / promotional mockup |
| Featured | Forest Studio | `forest-studio` | Generated style concept / promotional mockup |
| Featured | Aurora Pulse | `aurora-pulse` | Generated style concept / promotional mockup |
| Featured | Sandstone Minimal | `sandstone-minimal` | Generated style concept / promotional mockup |

## Asset hierarchy

1. `references/overview/LATEST_APPROVED_GLASS_SCREENSHOT.png`: direct user-selected five glass theme screenshot.
2. `references/glass/*.png`: cropped user screenshot; only Black Glass large preview, the rest are **small thumbnails**.
3. `references/overview/APPLE_STYLE_FIVE_COLOURS.png`: collage for Default and four Classic colour variants.
4. `references/{defaults,glass,featured}/*_CONCEPT.png`: the generated single theme images when present.
5. `backgrounds/*_PROVISIONAL_BLUR.jpg`: reconstructed blurred gradient backgrounds, **not exact exports**.
6. `tokens/theme_manifest.PROVISIONAL.json`: sensible CSS/SwiftUI starting values; every number must be reviewed in actual UI.

## Asset gaps / blockers

- Original pixel-perfect backgrounds, symbol assets and typography source metadata are not available for all 19 designs.
- Latest screenshot thumbnails for White/Blue/Grey/Champagne Glass are too low-resolution for pixel-exact spec extraction. If better source images exist in the Codex repository, use them unchanged and update this index. Otherwise implement best-fit and request visual approval.
- The user can approve a render that intentionally differs from the promotional image when needed to obey the approved Home geometry.
- Pre-existing visual HTML galleries are historic; if an element conflicts with the later 2026-11-06 approvals, the later approval takes precedence.
