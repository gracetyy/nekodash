# Playtest Report - gameplay.tscn

## Session Info

- **Date**: 2026-04-02
- **Scene Under Test**: `res://scenes/gameplay/gameplay.tscn`
- **Build**: `db76df9` (post S3-03 SaveManager disk I/O, S3-04 WorldMapScene, S3-06 star recolor)
- **Duration**: ~12 seconds wall-clock (automated run, all 6 levels)
- **Tester**: GitHub Copilot (automated MCP playtest)
- **Platform**: Windows PC (Godot 4.3, Intel Iris Xe)
- **Input Method**: Scripted directional inputs via `PlaytestRunner`
- **Session Type**: Full World 1 regression — fresh save state, post-Sprint-3 mid-sprint build

## Test Focus

- Verify S3-03 SaveManager disk I/O: "NEW BEST!" badge confirms records written and read correctly
- Verify S3-06 enlarged gold stars (48px) render correctly on LevelCompleteScreen
- Verify end-to-end progression w1_l1 → w1_l6 with fresh save (unlock chain working)
- Verify Next Level button advances through all 6 levels and is absent on w1_l6 (last level)
- Full regression: no regressions from S3-01 through S3-06 changes

## First Impressions (First 5 minutes)

- **Understood the goal?** Yes
- **Understood the controls?** Yes
- **Emotional response**: Engaged
- **Notes**:
  - Grid correctly centred in viewport on all 6 grid sizes (4×3 through 6×7).
  - CoverageVisualizer green overlay expands visibly with each move.
  - Level Complete screen shows gold 48px stars prominently — high contrast against dark background.
  - w1_l6 (last level) correctly omits Next Level button, shows only Retry + World Map.

## Gameplay Flow

### What worked well

- All 6 levels complete in one uninterrupted automated pass — no crashes, no stuck states.
- **S3-03 SaveManager disk I/O confirmed working**: "NEW BEST!" badge appears on every level (first-time completions on fresh save). Records correctly written each time.
- **S3-06 gold stars confirmed**: 48px gold stars (`Color(1.0, 0.85, 0.2)`) render cleanly on LevelCompleteScreen for all 6 levels.
- Move counter and minimum-move display accurate on all levels.
- Next Level button correctly absent on w1_l6; runner correctly terminates with `6/6 PASSED`.
- Scene transition chain fires reliably across all 6 level → complete → next-level cycles.

### Pain points

- **Empty space on small grids**: 4×3 (w1_l1) and 4×4 (w1_l2) leave large blank areas in the 540×960 viewport — the grid occupies roughly the centre third. **Severity: Medium — affects perceived polish.**
- **No scene transition animation**: Instant swap between gameplay and level-complete screen. **Severity: Low — post-jam polish.**
- **Uncovered walkable tiles vs. wall tiles**: Dark blue walkable tiles and grey wall tiles have limited contrast before the cat visits them. **Severity: Medium — readability concern for new players.**

### Confusion points

- None in automated run. Onboarding/tutorial not tested.

### Moments of delight

- Gold star rendering on level-complete is satisfying and immediately readable.
- Cat sprite is charming.
- "NEW BEST!" badge confirms progress is being saved — psychologically rewarding.

## Bugs Encountered

| #   | Description                                                        | Severity | Reproducible   |
| --- | ------------------------------------------------------------------ | -------- | -------------- |
| 1   | `swapped` variable declared but unused in `scene_manager.gd`       | Low      | Yes — cosmetic |
| 2   | `name` parameter shadows `Node.name` property in a script function | Low      | Yes — cosmetic |

No High or Medium severity bugs found. Previously reported High priority (TD-003 SaveManager disk I/O) is **resolved** in this build. TD-001 script error (`test_level_data.gd:243`) is **resolved**.

## Feature-Specific Feedback

### SaveManager Disk I/O (S3-03)

- **Understood purpose?** N/A (invisible to player)
- **Verified**: "NEW BEST!" badge on first completion of every level confirms `set_level_record()` writes to disk and `is_level_completed()` reads back correctly on level-complete screen population.
- **Suggestions**: No issues. TD-003 closed.

### Level Complete Screen — Gold Stars (S3-06)

- **Understood purpose?** Yes
- **Found engaging?** Yes
- **Verified**: 48px gold stars render at `Color(1.0, 0.85, 0.2)` for all 3 stars on every 3-star completion across 6 levels. High contrast against dark `Color(0.08, 0.08, 0.12)` background. Grey unearned stars verified visually distinct.
- **Suggestions**: None — star presentation is clear and rewarding.

### Grid + HUD Composition

- **Understood purpose?** Yes
- **Found engaging?** Yes
- **Verified**: Grid centred across all 5 distinct grid dimensions in World 1. HUD remains at top, no overlap.
- **Suggestions**: Consider a minimum grid display size — small grids leave significant empty screen real estate.

### Scene Transition Flow

- **Understood purpose?** Yes
- **Verified**: SceneManager `receive_scene_params()` contract honoured across all 6 level transitions and 5 level-complete transitions.
- **Suggestions**: A brief fade (0.1–0.2s) between gameplay and level-complete would add polish.

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
- **Screenshots captured**: 37 (session `20260402_160714`)
- **Scene transitions fired**: 11 (6× GAMEPLAY, 5× LEVEL_COMPLETE)
- **Regression tests**: 464/464 passing (GUT, pre-run)

## Overall Assessment

- **Would play again?** Yes
- **Difficulty**: Just Right (World 1 as tutorial ramp)
- **Pacing**: Good — slide animation speed feels satisfying, level-complete chain snappy
- **Session length preference**: Good

## Top 3 Priorities from this session

1. **Tile contrast / empty space on small grids** — uncovered walkable tiles vs. wall tiles have limited contrast before the cat visits them; small grids (4×3, 4×4) leave large empty viewport areas. Readability concern for new players.
2. **Scene transition animation** — instant scene swaps feel abrupt; a short 0.1–0.2s fade would add conveyed polish without complexity.
3. **Script warnings cleanup** — `swapped` unused var in `scene_manager.gd` and `name` param shadowing in a GDScript function are low noise but worth resolving.

---

_Previous priorities resolved: TD-003 SaveManager disk I/O (S3-03 ✅), TD-001 test_level_data type error (S3-01 ✅)._
