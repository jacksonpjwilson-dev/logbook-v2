# Stage 5 widget inventory

All 38 canonical IDs are retained; Food10 / Training10 / Body9 / History8 / Home1. Every ID supports S/M/L in the new Home renderer. Four explicitly selectable approved display variants fill the requested default Home roles without pretending an unconnected legacy source exists. No old demo measurements, meal clocks, fibre estimates, steps or heart rates are copied.

| ID | Legacy canonical name | Family | Stage 5 source / limitation |
| --- | --- | --- | --- |
| `kcal` | Calories left | food | Immutable food-log totals and effective target |
| `macros` | Macros | food | Immutable logged protein/carbs/fat |
| `protein` | Protein goal | food | Logged protein and effective target |
| `water` | Water | food | Identified mL events; optional explicit goal |
| `meals` | Today’s meals | food | Actual selected-date food entries by numbered meal |
| `favs` | Quick log | food | Explicit personal favorites; quantity review on every Add |
| `timing` | Meal timing | food | Canonical clocks unavailable; approved Nutrition Adherence display variant |
| `fibre` | Fibre | food | Explicit snapshot label fibre only; approved Nutrition Streak variant |
| `kcalavg` | Weekly calories | food | Average of observed logged dates only |
| `split` | Workout split | train | Permanent templates and numbered rotation |
| `easynext` | Easy next | food | Observed habitual foods with remaining target |
| `today` | Today | home | Current actual summaries and optional check-in |
| `next` | Next workout | train | Active snapshot or next numbered template |
| `week` | This week | train | Actual Monday–Sunday finished sessions |
| `last` | Last workout | train | Actual last saved workout |
| `prs` | Personal records | train | Corrected real set achievements; optional month filter |
| `volume` | Volume trend | train | Completed valid working sets only |
| `streak` | Streak | train | Closed weeks meeting configured workout target |
| `muscles` | Muscle groups | train | Recorded primary-muscle IDs and completed working sets |
| `rest` | Rest timer | train | Active workout rest or separate timestamp timer |
| `plan` | Upcoming plan | train | Actual rotation order; no fictional future dates |
| `sleeplast` | Last night | body | Actual sleep wake dates, no overlapping aggregate |
| `sleep7` | Sleep chart | body | Observed sleep dates only |
| `consist` | Sleep consistency | body | Measured goal-hit proportion with effective goals |
| `weight` | Weight | body | Actual official measurements and original dates |
| `wtrend` | Weight trend | body | At least three distinct actual trailing-week dates |
| `measure` | Measurements | body | Canonical circumference source unavailable; approved Habits Streak variant |
| `supps` | Supplements | body | Actual scheduled dose denominator and explicit Taken |
| `vitals` | Steps & resting HR | body | Canonical HealthKit source unavailable; approved Detailed Daily Check-in variant |
| `bedtime` | Bedtime target | body | Explicit planned bedtime; never a measured sleep observation |
| `graph` | Graph | hist | Actual 30-day chosen metric; one exercise ID for strength |
| `calheat` | Calendar heatmap | hist | Actual completed-workout dates; calendar display variant |
| `month` | Month summary | hist | Observed month counts/averages |
| `bestweek` | Best week | hist | Week containing actual completed working-set volume |
| `compare` | Compare | hist | Equal observation windows with sufficient actual data |
| `milestones` | Milestones | hist | Actual saved-session count thresholds |
| `journal` | Journal | hist | User-entered workout/sleep notes |
| `totals` | All-time totals | hist | Actual all-time session/food/sleep counts |

## Default display variants

| Canonical ID | Explicit option | Approved default role |
| --- | --- | --- |
| `measure` | `view: habits` | Habits Streak, actual sleep + weight + scheduled dose satisfaction; zero doses is satisfied |
| `vitals` | `view: checkin` | Detailed Daily Check-in |
| `fibre` | `view: nutrition-streak` | Nutrition Streak, today provisional |
| `timing` | `view: adherence` | Nutrition Adherence, observed closed-day targeted logs |

The gallery names source limits directly. Missing external/manual source fields are not zeros. No real-source migration or HealthKit integration is claimed.
