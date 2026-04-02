# Playtest Report

## Session Info

- **Date**: 2026-04-01 (updated 2026-04-02 — post-fix; updated 2026-04-02 — full World 1 review; updated 2026-04-02 — World Map S3-04 review)
- **Build**: `db76df9` (post S3-04 WorldMapScene)
- **Duration**: Single focused feedback session
- **Tester**: Player draft synthesis
- **Platform**: PC
- **Input Method**: Keyboard (WASD/Arrow)
- **Session Type**: Targeted test

## Test Focus

Gameplay readability and feel for `gameplay.tscn`, with emphasis on controls, completion transition, scoring pressure, and HUD clarity. **World Map scene (S3-04)** first-impression review: level list rendering, navigation, and layout.

## First Impressions (First 5 minutes)

- **Understood the goal?** Partially
- **Understood the controls?** Partially
- **Emotional response**: Engaged
- **Notes**: Core puzzle loop is understandable, but onboarding and feedback timing need improvement.

## Gameplay Flow

### What worked well

- Wireframe baseline is playable and communicates the core loop.
- Current visual direction is acceptable for a prototype/wireframe stage.

### Pain points

- ~~Undo button appears disabled after first move and clicking gives no response.~~ **Fixed** (`hud.gd`: undo button refresh added to `_on_move_count_changed`)
- ~~Completion transitions to stars screen too immediately after full coverage; lacks satisfying pause/animation bridge.~~ **Fixed** (`level_coordinator.gd`: 0.6s delay + `LEVEL_COMPLETE_OVERLAY_DELAY_SEC` constant)
- ~~Move counter number lacks explicit label/context, reducing readability.~~ **Fixed** (`gameplay.tscn`: `MovesPrefix` label `"Moves: "` added before `MoveLabel`)
- ~~Coverage counter may be redundant for players because tile colors already communicate progress.~~ **Fixed** (`gameplay.tscn`: `CoverageLabel` and `Spacer` hidden; data still flows for debug)
- Current UI and animation quality feel early-stage and need significant polish for production. **Severity: Low (for current stage), High (for final quality target)**
- ~~World Map button on the Level Complete screen does nothing when tapped.~~ **Fixed** (S3-05: wired to `SceneManager.go_to(Screen.WORLD_MAP)`)
- World Map screen shows "No levels found" — level grid is empty on first visit. **Severity: High — world map is non-functional**
- Back button on World Map screen does nothing. **Severity: High — navigation dead-end**
- "NEW BEST!" badge no longer appears on the Level Complete screen. Was visible after Sprint 2; appears to be a regression. **Severity: High — save feedback broken**
- Button order on Level Complete screen is wrong: currently Next Level / Retry / World Map, should be World Map / Retry / Next Level (most to least common action). **Severity: Medium — UX flow**
- "NekoDash" title text on World Map screen is not horizontally centred. **Severity: Low — visual polish**
- Levels 4, 5, and 6 do not offer meaningful route-choice tension; the player can find the solution on first try without deliberating between trade-offs. The gameplay prototype levels are a better reference for challenge through branching paths. **Severity: High — core engagement risk**
- Star icons on the Level Complete screen are small and grey/white, making them visually underwhelming as a reward signal. **Severity: Medium**

### Confusion points

- Controls and objective are not taught in-scene; new players may not know swipe vs keyboard mappings or completion objective.

### Moments of delight

- Puzzle concept is still clear and promising despite rough presentation.

## Bugs Encountered

| #   | Description                                                                      | Severity | Reproducible | Status                |
| --- | -------------------------------------------------------------------------------- | -------- | ------------ | --------------------- |
| 1   | Undo remains disabled after first move and button click has no effect            | High     | Yes          | ✅ Fixed (2026-04-02) |
| 2   | Level complete jumps to results too quickly without transition beat              | High     | Yes          | ✅ Fixed (2026-04-02) |
| 3   | World Map button on Level Complete screen is non-functional (no navigation)      | High     | Yes          | ✅ Fixed (S3-05)      |
| 4   | Move counter lacks text label clarifying what the number means                   | Medium   | Yes          | ✅ Fixed (2026-04-02) |
| 5   | Star icons on Level Complete screen are small and grey/white; lack reward impact | Medium   | Yes          | ✅ Fixed (S3-06)      |
| 6   | World Map shows "No levels found" — level grid is empty on first visit           | High     | Yes          | ⚠️ Open               |
| 7   | Back button on World Map screen does nothing                                     | High     | Yes          | ⚠️ Open               |
| 8   | "NEW BEST!" text badge missing from Level Complete screen (regression)           | High     | Yes          | ⚠️ Open               |
| 9   | Level Complete button order: should be World Map / Retry / Next Level            | Medium   | Yes          | ⚠️ Open               |
| 10  | "NekoDash" title not horizontally centred on World Map screen                    | Low      | Yes          | ⚠️ Open               |

## Feature-Specific Feedback

### Undo Interaction

- **Understood purpose?** Yes
- **Found engaging?** No
- **Suggestions**: Enable Undo immediately after first valid slide and provide clear enabled-state visuals.
- **Design intent cross-check**: **Conflict** with HUD acceptance criteria (HU-7: Undo should enable after first slide).

### Completion Transition

- **Understood purpose?** Yes
- **Found engaging?** Partially
- **Suggestions**: Add short completion beat (for example 0.3-0.8s pause, tile pulse, or cat reaction) before showing results.
- **Design intent cross-check**: **Conflict** with Level Complete fantasy describing a completion punctuation/beat before results.

### Star Rating Pressure

- **Understood purpose?** Yes
- **Found engaging?** Partially
- **Suggestions**: Relax 3-star threshold tolerance slightly on selected levels so small inefficiencies can still earn 3 stars.
- **Design intent cross-check**: **Partial conflict/risk**. Game concept supports both casual and perfectionist play. If thresholds feel too strict, this can undermine Pillar 3 (Complete Your Own Way). Threshold tuning should be handled in level data balance, not hardcoded logic.

### Move Counter Clarity

- **Understood purpose?** Partially
- **Found engaging?** Partially
- **Suggestions**: Add explicit label such as "Moves" or "Moves / Target" near the numeric display.
- **Design intent cross-check**: **Conflict** with Move Counter/HUD intent of clearly communicating progress toward minimum moves.

### Coverage Counter Visibility

- **Understood purpose?** Yes
- **Found engaging?** Neutral
- **Suggestions**: Consider hiding detailed coverage count from player-facing HUD and retaining it in debug output (or optional advanced HUD mode).
- **Design intent cross-check**: **Potential conflict**. Current Coverage and HUD design explicitly present live coverage counts to aid planning. This needs a product decision before change.

### World Map Navigation (Level Complete → World Map)

- **Understood purpose?** Yes
- **Found engaging?** N/A
- **Suggestions**: World Map button is now wired (S3-05 ✅). However the World Map scene itself shows "No levels found" — investigate catalogue loading at `res://data/level_catalogue.tres`.
- **Design intent cross-check**: **Conflict** — WM-1 acceptance criterion requires all worlds visible on first load.

### World Map — Level Grid Empty

- **Understood purpose?** Yes (intended to show all levels)
- **Found engaging?** No — grid is blank, "No levels found" label shows
- **Suggestions**: Verify `res://data/level_catalogue.tres` exists and is populated. If path is wrong, align with canonical path contract from GDD.
- **Design intent cross-check**: **Conflict** with WM-1 (screen loads and displays all worlds from LevelCatalogue).

### World Map — Back Button Dead

- **Understood purpose?** Yes
- **Found engaging?** N/A
- **Suggestions**: Back button press should call `SceneManager.go_to(Screen.MAIN_MENU)`. Confirm `_back_btn` is discovered by `_auto_discover_ui_nodes()` and `_on_back_btn_pressed()` is connected.
- **Design intent cross-check**: **Conflict** with WM-7 (back button returns to Main Menu).

### "NEW BEST!" Badge Regression

- **Understood purpose?** Yes
- **Found engaging?** Yes (was satisfying in Sprint 2)
- **Suggestions**: Badge was present post-Sprint 2 but appears missing now. Check `_update_new_best_badge()` in `level_complete_screen.gd` — confirm `is_new_best()` returns true and badge node is not hidden or misnamed.
- **Design intent cross-check**: **Conflict** — regression from previously confirmed working state.

### Level Complete Button Order

- **Understood purpose?** Yes
- **Found engaging?** Neutral
- **Suggestions**: Reorder buttons in `level_complete.tscn` ButtonRow to: **World Map** → **Retry** → **Next Level**. Most players finishing a level will want to exit to World Map or retry first; Next Level as rightmost CTA only makes sense when forward progression is the dominant goal.
- **Design intent cross-check**: **Minor conflict** — no explicit order in GDD; standard mobile UX puts primary exit action on the left.

### Level Design — Route Divergence (Levels 4–6)

- **Understood purpose?** Yes
- **Found engaging?** Partially
- **Suggestions**: Redesign w1_l4–w1_l6 so multiple viable routes exist — ideally at least one short path (3-star) and one or two longer paths (1–2 star) that are each discoverable. The gameplay prototype levels are a strong reference for this tension. Force a deliberate choice rather than a single obvious path.
- **Design intent cross-check**: **Conflict** with core loop Pillar 1 (spatial reasoning / route selection). Levels without branching paths reduce the mechanic to execution rather than planning.

### Star Rating Visibility

- **Understood purpose?** Yes
- **Found engaging?** No
- **Suggestions**: Increase star icon size and use filled yellow/gold colour for earned stars. Dimmed stars for unearned can remain grey/translucent. This is a high-return visual change for a low-effort implementation cost.
- **Design intent cross-check**: **Conflict** with reward clarity intent of the Level Complete screen.

### Star Rating Thresholds

- **Understood purpose?** Yes
- **Found engaging?** Partially
- **Suggestions**: Allow 3-star completion for solutions 1–2 moves above the absolute minimum, not only for the single optimal solution. Players should feel accomplished for near-optimal play without feeling punished by a single extra slide. Tune per-level in the level data (`star_3_moves` field).
- **Design intent cross-check**: **Partial conflict/risk**. See Pillar 3 (Complete Your Own Way). Thresholds are already data-driven per level — this is a balance pass, not a code change.

### Tutorial / Onboarding

- **Understood purpose?** Partially
- **Found engaging?** N/A
- **Suggestions**: Add early step-by-step tutorial hints covering controls and objective (mobile swipe + desktop WASD/arrow). Scope as a good-to-have for a later stage, not MVP.
- **Design intent cross-check**: **Open decision**. Supports onboarding quality; should be scoped against MVP constraints.

### Visual Polish (UI, Animation, Cat)

- **Understood purpose?** Yes
- **Found engaging?** Partially
- **Suggestions**: Current assets are acceptable as a wireframe baseline. Schedule a dedicated polish pass for motion, icon sizing, color hierarchy, and character expressiveness. Cat sprite design follows the right direction but has room for improvement.
- **Design intent cross-check**: **Aligned** with current stage; polish expected post-wireframe.

## Quantitative Data (if available)

- **Deaths**: N/A
- **Time per area**: N/A
- **Items used**: N/A
- **Features discovered vs missed**:
  - Discovered: core movement, level completion, results screen
  - Missed/unclear: clear control teaching, explicit move-counter meaning, World Map navigation
- **Open bugs**: 5 (World Map empty, World Map back button dead, NEW BEST badge regression, button order, title alignment)

## Overall Assessment

- **Would play again?** Maybe
- **Difficulty**: Just Right mechanically, but feedback clarity needs improvement
- **Pacing**: Slightly too abrupt at completion transition
- **Session length preference**: Good

## Top 3 Priorities from this session

~~1. Fix Undo button state/behavior so Undo is usable after first move.~~ ✅ Fixed
~~2. Add a short completion transition beat before results screen.~~ ✅ Fixed
~~3. Improve HUD clarity (labeled move counter) and decide whether coverage count remains player-facing.~~ ✅ Fixed (label added; coverage hidden)

## Revised Priorities (post full World 1 review, 2026-04-02)

~~1. **Fix World Map button** — wire `on_world_map_btn_pressed()` to a real navigation target so Level Complete is never a dead end.~~ ✅ Fixed (S3-05)
~~3. **Enlarge star icons and fill earned stars yellow/gold** — small grey stars undercut the reward loop.~~ ✅ Fixed (S3-06) 2. **Redesign w1_l4–w1_l6 for route divergence** — levels must offer meaningful trade-offs between longer and shorter paths to validate the core spatial-planning mechanic. Reference the gameplay prototype. (High, design-critical) 4. **Relax 3-star thresholds** — increase `star_3_moves` by 1–2 per level so near-optimal play still earns 3 stars. Reduces player pressure without removing skill ceiling. (Medium, balance) 5. **Add step-by-step tutorial hints** — controls and objective teaching (mobile swipe + desktop WASD/arrow). Good-to-have for a later stage; not MVP-blocking.

## Revised Priorities (post World Map S3-04 review, 2026-04-02)

1. **Fix World Map "No levels found"** — level catalogue is not loading; investigate `res://data/level_catalogue.tres` path and ensure it exists and is populated. (High, blocking — WM-1)
2. **Fix World Map back button** — `_on_back_btn_pressed()` not navigating; confirm node discovery and signal connection. (High, blocking — WM-7)
3. **Investigate "NEW BEST!" regression** — badge was present in Sprint 2 build, now missing; check `is_new_best()` and badge node visibility in `level_complete_screen.gd`. (High, regression)
4. **Fix Level Complete button order** — reorder ButtonRow in `level_complete.tscn` to: World Map → Retry → Next Level. (Medium, UX)
5. **Centre "NekoDash" title on World Map** — `TitleLabel` needs correct horizontal alignment within the header `HBoxContainer`. (Low, visual)
