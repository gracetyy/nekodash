## Prototype Report: Gameplay Scene Wiring

### Hypothesis

The four M1 production systems (GridSystem autoload, SlidingMovement, CoverageTracking,
MoveCounter) can be wired together in a single GameplayScene to play a level end-to-end:
load grid → slide cat → track coverage → count moves → detect level completion.

### Approach

Built a minimal `GameplayPrototype.tscn` scene that:

1. Loads a LevelData `.tres` resource
2. Calls `GridSystem.load_grid()`, then `initialize_level()` on each gameplay system
3. Uses `bind_sliding_movement()` to wire CoverageTracking and MoveCounter to SlidingMovement's signals
4. Renders the grid as colored rectangles (proto_grid_renderer.gd)
5. Draws the cat as an orange circle with ears (proto_cat_sprite.gd)
6. Displays move count and coverage in a simple HUD (proto_hud.gd)
7. Supports R to restart and 1/2/3 to switch between w1_l1/l2/l3

**Shortcuts taken**: No real art, no TileMapLayer, no scene transitions, hardcoded
level paths, placeholder visuals via `_draw()`.

### Recommendation: PROCEED

The production systems wire together cleanly. The `bind_sliding_movement()` /
`initialize_level()` API design makes the wiring straightforward — the GameplayScene's
`_ready()` function is ~20 lines. Signal connections are clean, no cyclic dependencies.
One bug found (move counter off-by-one at completion) — documented below with fix strategy.

---

# Playtest Report

## Session Info

- **Date**: 2026-04-01
- **Build**: Prototype (gameplay-scene), post-fix run
- **Duration**: Automated sequence (~15 seconds per run) + manual verification
- **Tester**: Automated autoplay harness + manual play (via Godot MCP)
- **Platform**: PC (Windows, Godot 4.6.1 via MCP)
- **Input Method**: Programmatic (InputSystem.direction_input.emit) + manual KB
- **Session Type**: Systematic coverage — all 3 World 1 levels + edge cases

## Test Focus

End-to-end validation of the full signal chain: load level → slide cat → track coverage
→ count moves → detect completion → restart. Specifically testing:

- All 3 World 1 levels complete correctly at minimum moves
- Move counter shows correct count at completion (off-by-one fixed)
- Coverage HUD updates in sync with grid visuals (stale coverage fixed)
- Start position marked as covered on initialization
- Blocked slides rejected correctly
- Rapid input during slide animation rejected
- Restart resets all state cleanly

## First Impressions (First 5 minutes)

- **Understood the goal?** Yes — cover all walkable tiles
- **Understood the controls?** Yes — arrow keys to slide, R to restart, 1/2/3 to switch levels
- **Emotional response**: Functional — prototype visuals serve their purpose
- **Notes**: Grid rendering and HUD are clear enough to validate gameplay. Cat slides
  smoothly with tween animation. Coverage overlay (green) provides immediate feedback.

## Gameplay Flow

### What worked well

- Signal chain fires in correct order: `direction_input` → `slide_started` → `slide_completed` → `move_count_changed` → `tile_covered` → `coverage_updated` → `level_completed`
- Move counter now shows correct count at completion thanks to bind-order fix (MoveCounter before CoverageTracking)
- Coverage HUD updates via `coverage_updated` signal — always in sync with grid visuals
- Multi-tile slides work correctly (w1_l3: cat slides from (1,1) to (3,1) covering 2 tiles in one move)
- Start position is properly marked as covered at initialization (fixed during code review)
- Restart resets all state: moves=0, coverage=1/total (start tile only), HUD updated
- Level switching via 1/2/3 keys works cleanly with full re-initialization
- Blocked slide rejection works — cat stays in place when no walkable tile exists in the slide direction

### Pain points

- No visual/audio feedback when a slide is blocked — Severity: Low (SlidingMovement has bump animation; audio pending AudioManager)
- No transition or delay between level completion and allowing continued input — Severity: Low (Level Coordinator responsibility)

### Confusion points

- None observed in automated testing. The signal chain is unambiguous.

### Moments of delight

- Watching the cat slide across multiple tiles in w1_l3 (the ring level) with tiles lighting up green in sequence feels correct and satisfying even with placeholder art.

## Bugs Encountered

| #   | Description                                                                                                                                                                                                                                             | Severity | Reproducible             | Status |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ------------------------ | ------ |
| 1   | Move counter shows N-1 at completion. `level_completed` fires from CoverageTracking's `on_slide_completed` BEFORE MoveCounter's `on_slide_completed` increments the count for the same signal. All 3 levels report wrong move count at completion time. | High     | Yes — 100% on all levels | FIXED  |
| 2   | Coverage HUD lags by one move. After fixing Bug 1 by binding MoveCounter first, `move_count_changed` fires before CoverageTracking processes the slide. The HUD was reading stale coverage inside `_on_move_count_changed`.                             | Medium   | Yes — 100% on all levels | FIXED  |

### Bug 1: Move Counter Off-by-One at Completion — FIXED

**Raw data showing the bug (pre-fix):**

```
Level 1 (w1_l1 "First Steps"): min=1 move
  Move 1: right (1,1)->(2,1) coverage 1->2/2 (100%)
  LEVEL COMPLETE! Moves: 0 / Minimum: 1          ← should be 1

Level 2 (w1_l2 "Turn the Corner"): min=3 moves
  Move 1: right (1,1)->(2,1) coverage 1->2/4 (50%)
  Move 2: down  (2,1)->(2,2) coverage 2->3/4 (75%)
  Move 3: left  (2,2)->(1,2) coverage 3->4/4 (100%)
  LEVEL COMPLETE! Moves: 2 / Minimum: 3          ← should be 3

Level 3 (w1_l3 "Central Wall"): min=4 moves
  Move 1: right (1,1)->(3,1) coverage 1->3/8 (38%)
  Move 2: down  (3,1)->(3,3) coverage 3->5/8 (63%)
  Move 3: left  (3,3)->(1,3) coverage 5->7/8 (88%)
  Move 4: up    (1,3)->(1,1) coverage 7->8/8 (100%)
  LEVEL COMPLETE! Moves: 3 / Minimum: 4          ← should be 4
```

**Root cause**: Both CoverageTracking and MoveCounter connect to
`SlidingMovement.slide_completed`. Godot calls signal handlers in connection order.
CoverageTracking is bound first, so its handler runs first — it detects 100% coverage
and emits `level_completed`. At that moment, MoveCounter has NOT yet incremented for
the current slide.

**Fix strategy**: The Level Coordinator should handle this. Options:

1. **Freeze + 1**: When `level_completed` fires, read `move_counter.get_current_moves() + 1`
2. **Deferred completion**: Connect `level_completed` as deferred (`CONNECT_DEFERRED`) so it
   fires after all `slide_completed` handlers finish
3. **Reverse bind order**: Bind MoveCounter before CoverageTracking (fragile, order-dependent)

Recommended: **Option 2** — `CONNECT_DEFERRED` is the cleanest Godot idiom. The Level
Coordinator connects `coverage_tracking.level_completed` with `CONNECT_DEFERRED`, ensuring
MoveCounter has already processed the slide by the time the completion handler runs.

**Resolution**: Applied Option 3 — reversed bind order in prototype + Level Coordinator
(`_connect_signals()` binds MoveCounter before CoverageTracking). Verified with autoplay:

```
LEVEL COMPLETE! Moves: 1 / Minimum: 1    ← was 0, now correct
LEVEL COMPLETE! Moves: 3 / Minimum: 3    ← was 2, now correct
LEVEL COMPLETE! Moves: 4 / Minimum: 4    ← was 3, now correct
```

### Bug 2: Coverage HUD Stale by One Move — FIXED

**Root cause**: After fixing Bug 1 by binding MoveCounter before CoverageTracking,
`_on_move_count_changed` fires before CoverageTracking has processed `slide_completed`.
The HUD was piggy-backing coverage updates on `move_count_changed`, reading stale
`coverage_tracking.get_covered_count()` values.

**Symptom**: HUD shows correct move count (e.g., "Moves: 2 / 4") but stale coverage
(e.g., "Coverage: 3 / 8" when 5 tiles are visually green on-screen).

**Fix**: Separated concerns — `_on_move_count_changed` now only updates the move
display. Coverage HUD is driven by `coverage_tracking.coverage_updated` signal,
which fires from CoverageTracking's handler (after tiles are actually marked).

## Feature-Specific Feedback

### Sliding Movement

- **Understood purpose?** Yes
- **Found engaging?** Yes — ice-physics sliding until hitting a wall is intuitive
- **Notes**: Multi-tile slides feel correct. Tween animation provides smooth visual feedback.
  Rapid input during animation is correctly rejected (tested: right+down in quick succession,
  only right was processed).

### Coverage Tracking

- **Understood purpose?** Yes
- **Found engaging?** Yes — watching tiles turn green gives clear progress feedback
- **Notes**: Start position now correctly marked on init. Tiles covered during multi-tile
  slides are all tracked. `get_coverage_percent()` returns accurate values.

### Move Counter

- **Understood purpose?** Yes
- **Found engaging?** N/A — counter display works correctly after bind-order fix
- **Notes**: Counter increments correctly during gameplay and at completion.

### Grid Rendering (prototype)

- **Understood purpose?** Yes
- **Notes**: Colored rectangles clearly distinguish walkable (dark blue) from blocking (gray)
  tiles. Green overlay for covered tiles is immediately readable.

## Quantitative Data

### Level Completion Data

| Level                   | Grid | Walkable | Min Moves | Actual Moves | Coverage   | Result |
| ----------------------- | ---- | -------- | --------- | ------------ | ---------- | ------ |
| w1_l1 "First Steps"     | 4×3  | 2        | 1         | 1            | 2/2 (100%) | PASS   |
| w1_l2 "Turn the Corner" | 4×4  | 4        | 3         | 3            | 4/4 (100%) | PASS   |
| w1_l3 "Central Wall"    | 5×5  | 8        | 4         | 4            | 8/8 (100%) | PASS   |

### Edge Case Results

| Test                                   | Expected             | Actual                          | Result |
| -------------------------------------- | -------------------- | ------------------------------- | ------ |
| Blocked slide up from (1,1) on w1_l1   | Cat stays at (1,1)   | Cat stays at (1,1)              | PASS   |
| Blocked slide down from (1,1) on w1_l1 | Cat stays at (1,1)   | Cat stays at (1,1)              | PASS   |
| Rapid input (right+down during slide)  | Only right processed | Only right processed, pos=(3,1) | PASS   |
| Restart resets moves                   | moves=0              | moves=0                         | PASS   |
| Restart resets coverage                | coverage=1/total     | coverage=1/total                | PASS   |
| Start pos covered on init              | coverage starts at 1 | coverage starts at 1            | PASS   |

### Runtime Errors

- **GDScript errors**: 0
- **Warnings**: 2 (expected SaveManager stubs — `save_corrupted` signal unused, disk I/O not implemented)

## Overall Assessment

- **Would play again?** Yes — core loop is functional and satisfying
- **Difficulty**: Just Right (for tutorial levels)
- **Pacing**: Good — levels are appropriately sized for World 1
- **Session length preference**: Good (quick puzzle sessions suit mobile)

## Top 3 Priorities from this session

1. **Wire Level Coordinator to production HUD** — The coordinator's `_on_move_count_changed` and `_on_coverage_updated` handlers are TODO stubs; HUD needs `coverage_updated` (not `move_count_changed`) for coverage display
2. **Add blocked-slide audio feedback** — SlidingMovement has bump animation; Audio event needed via future AudioManager
3. **Grid centering** — Grid renders at (0,0); needs horizontal centering in the 540×960 viewport

## If Proceeding

The production GameplayScene should:

1. **Architecture**: Make it a proper scene at `src/gameplay/gameplay_scene.gd` that receives
   `LevelData` via SceneManager params (not hardcoded paths)
2. **Visual rendering**: Use a `TileMapLayer` node with a tile atlas instead of `_draw()` rectangles
3. **Cat visual**: Use a `Sprite2D` or `AnimatedSprite2D` with the actual cat sprite
4. **HUD integration**: Wire to the production HUD system (design/gdd/hud.md)
5. **Level Coordinator**: Implement the Level Coordinator (design/gdd/level-coordinator.md) to
   manage the LOADING → PLAYING → COMPLETE state machine, freeze MoveCounter on completion,
   and transition to LevelCompleteScreen
6. **Grid centering**: Center the grid horizontally in the viewport with proper margins.
   SlidingMovement uses `GridSystem.grid_to_pixel()` for absolute positioning — the grid renderer
   and SlidingMovement must share the same coordinate space (common parent offset)
7. **Estimated production effort**: The wiring itself is trivial. The real work is the visual
   layer (TileMapLayer, sprites, HUD) and the Level Coordinator state machine.

### Blocker Discovered: `.godot` Cache Dependency

The project fails to run from a clean state (no `.godot/` directory) because `class_name LevelData`
isn't resolved until the editor rebuilds `global_script_class_cache.cfg`. Running headless or
from command line without the cache causes `Parser Error: Could not find type "LevelData"` in
every file that references it.

**Fix**: Open the project in the Godot editor at least once before running from CLI. This is
standard Godot behavior but should be documented for CI/CD pipelines.

### Lessons Learned

1. **`bind_sliding_movement()` pattern works well** — CoverageTracking and MoveCounter both
   implement this, making wiring declarative and safe (idempotent, checks `is_connected`)
2. **`initialize_level()` ordering matters** — GridSystem must be loaded first, then
   SlidingMovement (which emits `spawn_position_set`), then CoverageTracking (which needs
   the walkable tile list), then MoveCounter (which needs LevelData thresholds)
3. **Signal ordering between subscribers** — When multiple nodes subscribe to the same signal
   (e.g., both CoverageTracking and MoveCounter listen to `slide_completed`), the order they
   fire depends on connection order. The Level Coordinator enforces
   MoveCounter → CoverageTracking ordering to prevent off-by-one at completion.
4. **HUD must use per-system signals, not cross-read** — After fixing the bind order, the HUD
   coverage display lagged because it read CoverageTracking state from inside a MoveCounter
   signal handler. Each HUD element should update from its own system's signal
   (`move_count_changed` for moves, `coverage_updated` for coverage).
5. **w1_l2 grid has only 4 walkable tiles** — The TileWalkability enum has WALKABLE=0,
   BLOCKING=1, so the PackedInt32Array values `1` mean blocking. The level content is correct
   for the enum definition but the visual impression of a 4×4 grid with only a 2×2 walkable
   center is very small. Consider whether level content matches design intent.
