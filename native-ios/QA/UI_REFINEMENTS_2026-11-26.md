# UI refinements and local first-launch setup

The November 26 request authorizes sharing the current functional widgets across themes and replacing the opening artwork with the supplied MP4. The user's subsequent decision defers account-provider selection and real registration. Account authentication and cloud synchronization remain unimplemented. Apple Health permission remains disabled, with an informational optional setup stage.

The dashboard now puts date, title, page name and Edit in a compact header. Grid dimensions use available width and height while retaining square cells, four horizontal pages and the fixed dock. A square four-row grid can remain height-limited on shorter devices, so 12–16 point side margins are a preferred inset rather than an unconditional width.

The old renderer selected updated widgets only when the theme was Default and the page exactly matched a stock layout. Shared widget selection now follows widget kinds and variants across themes and customized layouts. Background artwork, palettes, borders, materials and shadows remain theme-controlled. The repository currently exposes 17 theme IDs. Earlier requirements describe 19 distinct designs, so complete reference coverage remains a separate pre-existing gap.

Theme preview images previously had a fixed height but unconstrained aspect-fill width, permitting drawing and interaction geometry beyond their apparent card. Previews now constrain the image width to their grid cell, clip it, give the visible card an explicit hit shape and prevent decorative imagery from handling touches.

The supplied 720 × 1264 MP4 runs for approximately 6.04 seconds. Playback uses a full-screen aspect-fill AVPlayerLayer, completion and failure callbacks, and a nine-second fallback. The center logo fits within the iPhone portrait crop in the inspected sample frames. Physical playback and user visual approval remain separate verification gates.

Setup has nine stages, back navigation, optional steps, persistent draft progress, manual nutrition targets, preferences, optional workout creation, theme selection and a Settings entry for revisiting setup. Preferences are initialized from existing data. Completion saves goals, selected units, optional workout/supplement and completion state in one transaction. Missing setup data decodes from older backups without replacing records. Accounts are explicitly marked deferred.

Verification is in progress. Results, devices, source revision and screenshots will be recorded here at completion. The existing unrelated Sleep, Food and timer QA findings remain preserved in the working tree.
