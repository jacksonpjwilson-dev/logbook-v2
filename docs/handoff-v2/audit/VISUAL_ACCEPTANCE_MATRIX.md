# VISUAL ACCEPTANCE MATRIX — REVIEW AGAINST ACTUAL RUNNING APP

## Contract
- **Reference evidence**: user-provided theme image or previous approved preview (qualitative visual style), NOT the app's home grid. The bundled PROVISIONAL token/background values are NOT authoritative.
- **Layout contract**: Daily Home top 2×2 large square, next 2×1 medium full-width, bottom two 1×1 square widgets, fixed 2 columns×4 rows, eight grid cells, gaps same in both axes. Example values on fitting reference canvas: small ~176×176, medium ~360×176, large ~360×360, gap 8. The actual implementation must satisfy proportional equations at the simulator safe width.
- **Other page layouts**: Training two 2×2 square widgets; Food large 2×2, medium 2×1, two small 1×1; Progress & History large 2×2, medium 2×1, two small 1×1. Content and functionality from master spec only.
- **No Home vertical scrolling**, clipped labels, hidden fifth icon, or tappable controls obscured by dock/safe area. Coach docking as separate role-based behavior.

## Calculation checks
For a usable grid width W and gap g, smallCellSide=(W-g)/2. Width of medium=2*smallCellSide+g=W. Large width=W, height=W. Small height=smallCellSide; medium height=smallCellSide. Required full grid height=4*smallCellSide+3*g. Confirm this fits above dock; adapt W/safe horizontal margins *proportionately* if necessary, rather than distorting cells.

## Per-theme test sheet (repeat 19 unique IDs)
| Test | Proof required | Fail condition |
|---|---|---|
| Background | Simulator screenshot, screenshot reference, tokens/assets | Sharply rendered scenery or mismatched tint if blurred motif was requested |
| Widget material | Blur/translucency/opacity/radius/edge/shadow inspection | Opaque fallback, inconsistent card styles, unreadable glass |
| Icon coherence | All five athlete dock icons + each widget icon | Multicoloured rainbow dock, different illustration styles, nonmatching accent |
| Typography | Dynamic Type & weights/leading/contrast | Truncation, arbitrary font, hard-to-read labels |
| Progress visuals | Calorie ring + separate protein/carb/fat bars | All identical when semantic differentiation required; unrelated rainbow style |
| Geometry | Extract measured SwiftUI/UITest frames | Small non-square; large not square; medium narrower/taller than grid rule |
| Home content | Compare against master spec not mockup | Mood cards/water habit introduced instead of approved sleep/weight/supplements; missing macro bars or actions |
| Navigation | Tap mapped subregions & fixed dock | Dead targets, whole widget capturing other control taps |
| 4 pages | Same theme fixture for all four approved pages | Layout drift or recolouring resets data and layout |
| Accessibility | VoiceOver labels, tap target, contrast, Dynamic Type | Inaccessible icons/controls or text clipping |
| Screenshot evidence | Filenames, simulator device/iOS, exact app commit | AI concept render presented as simulator evidence |

## Staged gates
- **G0** Baseline existing-repo scan + screenshot inventory.
- **G1** Default Daily Home proportional geometry + four Home pages; native screenshots; user visual acceptance.
- **G2** All 19 unique themes using one token system; screenshot/contact-sheet; user approval.
- **G3** All functional/native/integration/security criteria pass or explicitly blocked.

## Audit labels
`PASS`, `FAIL`, `PARTIAL`, `BLOCKED`, `REFERENCE_LIMITED`, `NOT_TESTED`. Do not replace missing proof with assumptions.

## Required Codex deliverables
- Native screenshots for every theme (same device, same fixed data) and side-by-side style references.
- Source code map for background tokens, widget materials, icons, dock styles and typography.
- Screenshot frame-measurement results and a per-theme test matrix.
- Regression results when toggling theme, editing widgets, logging a workout and enabling Coach mode.
