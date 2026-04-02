# Playtest Report - gameplay.tscn

## Session Info

- **Date**: 2026-04-02
- **Scene Under Test**: `res://scenes/gameplay/gameplay.tscn`
- **Build**: main branch (post-M1, all Sprint 2 tasks complete)
- **Duration**: ~40 seconds wall-clock (automated run, all 6 levels)
- **Tester**: GitHub Copilot (automated MCP playtest)
- **Platform**: Windows PC (Godot 4.3, Intel Iris Xe)
- **Input Method**: Scripted directional inputs via `PlaytestRunner` (rewritten for 6-level coverage)
- **Session Type**: Full World 1 regression test — visual coverage + scene transitions, all 6 levels

## Test Focus

- Verify visual coverage overlay (CoverageVisualizer) renders correctly across all 6 levels
- Verify LevelCompleteScreen scene transition fires correctly for every level
- Verify 3-star optimal solutions for new levels w1_l4–w1_l6 (Side Step, Double S, Three Turn)
- Verify Next Level button advances progression end-to-end through w1_l1 → w1_l6
- Verify "Three Turn" (w1_l6) correctly shows no Next Level button (last level) and runner terminates

## First Impressions (First 5 minutes)

- **Understood the goal?** Yes
- **Understood the controls?** Yes
- **Emotional response**: Engaged
- **Notes**:
  - Grid correctly centered in viewport on all 6 grid sizes (4×3 through 6×7).
  - CoverageVisualizer green overlay visibly expands with each move — clearly communicates progress.
  - Level Complete screen consistently shows name, 3 stars, move count vs minimum, "NEW BEST!" badge, and navigation buttons.
  - w1_l6 (last level) correctly omits the Next Level button and shows only Retry + World Map.

## Gameplay Flow

### What worked well

- All 6 levels complete in one uninterrupted automated pass — no crashes, no stuck states.
- CoverageVisualizer renders correctly: spawn tile pre-covered green at level load; each slide paints the path green; walls remain dark. Verified visually on w1_l6 (6×7 S-shape).
- Scene transition chain fires reliably: `CoverageTracking.level_completed` → `StarRatingSystem` → `LevelProgression.level_record_saved` → `SceneManager.go_to(LEVEL_COMPLETE)` → `LevelCompleteScreen.on_next_btn_pressed()` → `SceneManager.go_to(GAMEPLAY)`.
- `PlaytestRunner` correctly survives between-scene gaps as a persistent autoload, reconnecting to the new coordinator via `SceneManager.transition_completed` signal.
- Undo button activates after first move (correctly disabled at level start).
- Move counter increments correctly and matches minimum on 3-star completions for all levels.

### Pain points

- Last-move screenshot sometimes captures the LevelCompleteScreen rather than the final gameplay state, because the level-complete chain fires faster than the 0.6s screenshot timer. **Severity: Low — cosmetic only, no functional impact.**

### Confusion points

- None. All level solutions executed as designed.

### Moments of delight

- w1_l6 mid-play (move 4): green CoverageVisualizer paint clearly separates the solved top-half S-arm from the uncovered dark-blue bottom — visually communicates puzzle progress at a glance.
- "NEW BEST!" badge appears on every level (first-time completions). Reads cleanly against the dark LevelCompleteScreen background.

## Bugs Encountered

| #   | Description                                                                                                                                                                                     | Severity | Reproducible              |
| --- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ------------------------- |
| 1   | Last-move screenshot captures LevelCompleteScreen instead of final gameplay frame (timing race between level_complete chain and 0.6s timer)                                                     | Low      | Yes — non-blocking        |
| 2   | Three pre-existing script warnings in debug output: `save_corrupted` signal unused (SaveManager), `swapped` var unused (SceneManager), `name` param shadows Node property (LevelCompleteScreen) | Low      | Yes — tracked as TD items |

No High or Medium severity bugs found. All previously reported bugs (grid/HUD overlap, stuck completion flow, cat sprite quality) remain resolved.

## Feature-Specific Feedback

### CoverageVisualizer (visual overlay)

- **Understood purpose?** Yes
- **Found engaging?** Yes
- **Verified**: Initializes correctly on level load; `on_tile_covered` and `on_spawn_position_set` update the overlay per-move; `queue_redraw()` triggers correctly; all covered tiles rendered green by end of solution.
- **Suggestions**:
  - Consider a subtle fill animation (brief alpha pulse) when a tile is first covered to amplify the "paint the board" satisfaction loop.

### Level Complete Screen

- **Understood purpose?** Yes
- **Found engaging?** Yes
- **Verified**: Stars, move count, NEW BEST badge, and navigation buttons all populate correctly. Next Level button absent on w1_l6 (last level). `on_next_btn_pressed()` correctly triggers `next_level_requested` → SceneManager navigation.
- **Suggestions**:
  - If analytics are added, track `Retry` vs `Next Level` tap rate — useful signal for difficulty calibration.

### Grid + HUD Composition

- **Understood purpose?** Yes
- **Found engaging?** Yes
- **Verified**: Grid centers correctly across all 5 distinct grid dimensions in World 1 (4×3, 4×4, 5×5, 5×4, 6×6, 6×7). HUD remains at top, no overlap with any grid size.
- **Suggestions**:
  - Maintain current 100px top HUD margin as a safety budget for future HUD additions.

### Scene Transition Flow

- **Understood purpose?** Yes
- **Found engaging?** Yes
- **Verified**: SceneManager correctly frees old scene and instantiates new one before `_ready()`. `receive_scene_params()` contract honoured for both GAMEPLAY and LEVEL_COMPLETE screens across all 6 transitions.
- **Suggestions**: None — flow is robust.

## Quantitative Data

- **Levels tested**: 6/6 (all World 1 levels)
- **Completion status**: 6/6 PASS
- **Stars achieved**: ★★★ on all 6 levels
- **Moves vs minimum**:
  - `w1_l1` First Steps: 1 / 1
  - `w1_l2` Turn the Corner: 3 / 3
  - `w1_l3` Central Wall: 4 / 4
  - `w1_l4` Side Step: 4 / 4
  - `w1_l5` Double S: 5 / 5
  - `w1_l6` Three Turn: 6 / 6
- **Screenshots captured**: 37 (session `20260402_112853`)
- **Scene transitions fired**: 11 (6× GAMEPLAY, 5× LEVEL_COMPLETE)
- **Regression tests**: 464/464 passing (GUT, pre-run)

## Overall Assessment

- **Would play again?** Yes
- **Difficulty**: Just Right (World 1 as tutorial ramp)
- **Pacing**: Good — slide animation speed feels satisfying, level-complete chain snappy
- **Session length preference**: Good

## Top 3 Priorities from this session

1. **SaveManager disk I/O (TD-003)** — all 6 levels show "NEW BEST!" because saves are in-memory only; progress is lost on restart. This is the highest-impact correctness gap before any real playtesting with humans.
2. **Screenshot timing for last move** — tighten capture before the level-complete chain fires (reduce post-move wait from 0.6s to 0.3s, or capture on `slide_completed` signal directly) to preserve in-game final state documentation.
3. **Fix TD-001 script warning** — `test_level_data.gd:243` SCRIPT ERROR fires on every GUT run; one-line fix (`var tile: Node` → `var tile: GridSystem.GridTileData`).
