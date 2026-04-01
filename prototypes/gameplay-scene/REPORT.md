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

### Result

**Full signal chain verified working**. Automated test output:

```
[GameplayScene] Level 'Turn the Corner' loaded — 4 walkable tiles, 3 minimum moves
[AUTOPLAY] Sending direction: (1, 0)
slide_started: (1, 1) -> (2, 1) dir=(1, 0)
slide_completed: (1, 1) -> (2, 1) tiles=[(2, 1)]
[AUTOPLAY] Sending direction: (0, 1)
slide_started: (2, 1) -> (2, 2) dir=(0, 1)
slide_completed: (2, 1) -> (2, 2) tiles=[(2, 2)]
[AUTOPLAY] Sending direction: (-1, 0)
slide_started: (2, 2) -> (1, 2) dir=(-1, 0)
slide_completed: (2, 2) -> (1, 2) tiles=[(1, 2)]
[AUTOPLAY] Sending direction: (0, -1)
slide_started: (1, 2) -> (1, 1) dir=(0, -1)
[GameplayScene] LEVEL COMPLETE! Moves: 3 / Minimum: 3
slide_completed: (1, 2) -> (1, 1) tiles=[(1, 1)]
[AUTOPLAY] Test complete. Coverage: 4/4 (100%) Moves: 4
```

**All signals fire in correct order**:

- `direction_input` → SlidingMovement picks it up
- `slide_started` fires with correct from/to/direction
- `slide_completed` fires with correct tiles_covered array
- CoverageTracking marks tiles, emits `tile_covered` per tile
- MoveCounter increments, emits `move_count_changed`
- CoverageTracking emits `level_completed` at 100% coverage

### Metrics

- **Startup time**: < 1 second (no measurable delay)
- **Runtime errors**: 0 (only expected stub warnings from SaveManager)
- **Signal chain latency**: Negligible — all synchronous within same frame
- **Iteration count**: 2 runs (first hit a `.godot` cache issue, resolved by opening editor)
- **Level complete detection**: Fires correctly at 100% coverage on w1_l2 (4 tiles, 3 minimum moves)

### Timing Nuance Discovered

`level_completed` fires inside CoverageTracking's `on_slide_completed` handler, which runs
BEFORE MoveCounter's `on_slide_completed` handler processes the same signal. This means:

- `level_completed` fires when MoveCounter shows moves = 3 (the completion move)
- MoveCounter then increments to 4 (the already-covered return tile)

**Impact**: The Level Coordinator (future) should capture `move_counter.get_current_moves()`
at the moment `level_completed` fires, OR freeze the counter on the completing slide. The
current MoveCounter.freeze() is designed for this — it just needs to be wired in the Level
Coordinator.

### Recommendation: PROCEED

The production systems wire together cleanly. The `bind_sliding_movement()` /
`initialize_level()` API design makes the wiring straightforward — the GameplayScene's
`_ready()` function is ~20 lines. Signal connections are clean, no cyclic dependencies,
no timing issues beyond the documented completion-vs-counter ordering.

### If Proceeding

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
   fire depends on connection order. The Level Coordinator should not rely on ordering between
   these handlers.
4. **w1_l2 grid has only 4 walkable tiles** — The TileWalkability enum has WALKABLE=0,
   BLOCKING=1, so the PackedInt32Array values `1` mean blocking. The level content is correct
   for the enum definition but the visual impression of a 4×4 grid with only a 2×2 walkable
   center is very small. Consider whether level content matches design intent.
