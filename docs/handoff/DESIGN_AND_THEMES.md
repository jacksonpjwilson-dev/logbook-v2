# Authoritative Visual System and UI Specification

**Do not invent replacement themes or reinterpret approved image references.** The user approved a specific Apple Home Screen/widget-inspired design set based on ~30 visual references in an earlier ChatGPT conversation. Those actual reference images are NOT inside this text package. Retrieve from the original chat or ask for the original images before declaring visual fidelity complete. Build layout and behavior while awaiting exact assets.

## Brand identity
- Premium, iPhone-native-feeling, accessible PWA interface, glass surfaces, layered wallpaper, spacious but useful widgets. Do not simply reuse the legacy colorway or old UI unchanged.
- **App icon:** black rounded square with bold white angular **L**. Adaptive icon/manifest and iPhone touch icon variants.
- **Default theme:** **Premium Glass** (#6 in exact list).
- **Cold launch:** fresh cold open cinematic 3-second **Blended Theme Mark** splash with sweeping glass gradients, faded transition; never delay routine app resumes. Respect reduced-motion.
- Subtle contextual animated feedback and optional supported haptics; no blocking celebratory animations.

## Exactly 16 approved themes
1. Modern Clean
2. Sunset Vibes
3. Ocean Breeze
4. Monochrome Pro
5. Soft Pastel
6. **Premium Glass — DEFAULT**
7. Mountain Dawn
8. Coastal Minimal
9. Midnight Luxe
10. Cherry Blossom
11. Arctic Mountain (also called Alpine Frost)
12. Slate Glass
13. Midnight Glass
14. Monochrome
15. Neon Gradient
16. Teal & Coral

Implement a tokenized adaptable theme system with per-theme wallpaper, text color, card materials, dock and panel contrast, gradients and accessibility. **Theme names are exact user selections, not design descriptions.** Theme Gallery = Hybrid Gallery with live previews and Preview-Then-Apply; transitions should be smooth and reversible.

## Home Screen navigation
- **Four default customizable pages; no Home Screen vertical scrolling:** Daily, Training, Food, Progress & History.
- Users can add, rename, reorder pages and move widgets across them; retain intentional empty spaces.
- Fixed five-icon app dock: **Training | Food | History | Sleep & Check-ins | Settings**.
- Apple-style date/title/subtitle header, swipeable pages, Glass Page Indicator, glass dock, restrained wallpaper parallax **only while scrolling**, non-distracting transitions and contextual zoom opens.
- Cache quick visual updates so widgets render immediately while underlying data syncs.
- iPhone safe area and multiple device sizes; interactive elements have appropriate touch target sizes.

## Default widgets and four pages
- **Daily:** medium Today Calories/Protein Remaining; medium Next Workout; small Habits Streak (sleep, weight, scheduled supplements where zero scheduled is satisfied); small Detailed Daily Check-in.
- **Training:** two equally prominent large widgets, **Workout Split numbered rotation** and **Workout Calendar**.
- **Food:** big Nutrition Today; medium Today's Meals; small Nutrition Streak; small Easy Next.
- **Progress & History:** large switchable 30-day Weight/Strength/Sleep/Calories/Protein graph; medium activity heatmap; small PRs This Month; small Nutrition Adherence.
- **38 widget types** approved in families **Food (10), Training (10), Body (9), History (8), Home (1)**. Existing widget registry should be inventoried to identify canonical names and exact data bindings; this package does not fabricate unknown widget names. Any gaps should be documented and built using approved functionality.
- Small / medium / large widget size variants with realistic layouts, no clipped content. Widgets open meaningful detail screens/actions.
- Long-press edit -> Premium Glass wiggle editing and repositioning, across-page drag and reorder. Hybrid Widget Gallery has categories, search, previews and size picker. Smart Tidy with Undo. Widget data must be truthful, immediate, and follow correct history/sync state.

## Training screens
- **Workout First screen** with featured Up Next, expandable workout cards, activity strip, recent history, stats/shortcuts.
- In active session: visual exercise cards with accessible thumbnails and fallbacks; five columns **Set, Previous, Weight, Reps, Complete** without sideways scrolling; sticky top progress header and bottom compact action bar.
- Unified superset group panel, exercise jump menu, expanded rest-timer bar, linked replacement cards, set-complete microfeedback.
- Incomplete workout confirmation, completed workout summary, valid previous-session comparisons. Short Premium PR Celebration pill for achieved record categories per set.
- Preserve workout content on resume; no full-screen takeover on routine reopen, just persistent Resume Banner.

## Food screens
- Summary First nutrition header: ring/bar calorie progress and three macro cards; expandable hydration; user-numbered collapsible meal cards and detailed food rows.
- Section shortcuts Nutrition/Water/Meals; hybrid Add Food controls at top, in each meal, and compact floating + while scrolling.
- Hybrid search/recent/favorites/barcode/manual logger; quantity editor showing live kcal/P/C/F; saved meal additions confirm each ingredient's quantity.
- Nutrition streak clear calendar green/red/gray/provisional for current day; missing records not shown as failures.

## Sleep, weight, supplements, History screens
- One combined Sleep & Check-ins dock destination with large Sleep overview, side-by-side Weight and Supplements previews, clear detailed analytics screens.
- Sleep timeline bottom sheet; weight hybrid numeric/stepper entry; supplement scheduled/taken controls.
- History: segmented Overview / Training / Body / Nutrition / Sleep, interactive true-data chart switchers, calendar with three modes and expandable selected date.

## Appearance, interactions and constraints
- Premium Glass page transitions, dynamic pill status, optional haptics on successful interactions where supported, never mandatory.
- Reduced-motion, contrast and readable labels apply to *all 16 themes*. No fake graph zeros, mock values, or pretend completed PRs in empty states.
- No random stylistic redesign after approval: exact references should govern final visual appearance. Maintain a visual QA screenshot matrix by theme and app section.
- Old theme assets/colorways are background reference at best, not authorized stand-ins for the 16 themes.
