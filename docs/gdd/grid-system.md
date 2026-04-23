# Grid System

> **Status**: Approved
> **Author**: Grace + GitHub Copilot
> **Last Updated**: 2026-03-31
> **Implements Pillar**: Pillar 1 — Every Move Is a Choice

## Overview

The Grid System is the foundational data structure for NekoDash. It defines the game world as a 2D array of tiles, where each tile occupies a discrete coordinate on the grid and carries a type (walkable, wall, or other obstacle variants). The system provides a single source of truth for tile layout and exposes a query API used by every other gameplay system: Sliding Movement queries for walkable bounds, Coverage Tracking queries for tile state, the Obstacle System registers tile types, and the BFS Solver enumerates the full grid to compute minimum moves. It is entirely invisible to the player — no grid lines, no coordinate display — but without it, no other system can function.

## Player Fantasy

The Grid System has no direct player fantasy — it is pure infrastructure. Its emotional contribution is indirect: a well-designed grid layout is what makes a level feel like a fair puzzle with a satisfying solution, rather than an arbitrary obstacle course. When a player scans a level and thinks "I think I see a path," that intuition is made possible by the Grid System providing clear, predictable spatial rules. The grid serves **Pillar 1 — Every Move Is a Choice**: the player's ability to reason about tile layout, anticipate the cat's slide path, and plan multiple moves ahead depends entirely on the grid being a consistent, unambiguous structure. If the grid had inconsistencies or surprises, the puzzle would feel unfair. The Grid System's job is to be perfectly trustworthy.

## Detailed Design

### Core Rules

1. The grid is a finite 2D space indexed by `Vector2i(col, row)` with origin `(0, 0)` at the top-left corner. `+x` points right, `+y` points down. All coordinates are integer-only — no sub-grid positions exist.
2. Each tile is described by a `TileData` struct with two independent properties:

   **`TileData` struct definition:**

   | Field           | Type                     | Default    | Description                              |
   | --------------- | ------------------------ | ---------- | ---------------------------------------- |
   | `walkability`   | `TileWalkability` (enum) | `WALKABLE` | Whether the cat can enter this tile      |
   | `obstacle_type` | `ObstacleType` (enum)    | `NONE`     | What kind of obstacle occupies this tile |

   **`TileWalkability` enum:**
   - `WALKABLE` — cat may slide through or stop here
   - `BLOCKING` — cat cannot enter; acts as a wall/stop surface

   **`ObstacleType` enum:**
   - `NONE` — plain floor (if WALKABLE) or plain static wall (if BLOCKING)
   - `STATIC_WALL` — explicit static wall (BLOCKING; MVP)
   - _(post-jam stubs: `TELEPORTER`, `MOVING_WALL`, `TIMED_WALL` — BLOCKING or WALKABLE depending on activation state)_

3. Grid dimensions (width, height) are fixed per level and set at load time. They do not change during gameplay (for MVP).
4. **Minimum grid size**: 3 × 3. **Maximum grid size**: 15 × 15 (tuning knob — see Section G).
5. The Grid System does **not** store cat position, coverage state, or move history. Those belong to their respective systems.
6. The grid is **read-only at runtime** for MVP. No tile walkability changes during a level session (post-jam: `MOVING_WALL` and `TIMED_WALL` will mutate tile walkability via the Obstacle System).
7. Querying an out-of-bounds coordinate returns `BLOCKING` walkability by convention — this makes the Sliding Movement's bounds checking trivially simple (slide until `is_walkable()` is false, and out-of-bounds is always false).

### Public API

| Method                   | Signature                                                                           | Returns                    | Notes                                                                                                                            |
| ------------------------ | ----------------------------------------------------------------------------------- | -------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| `load_grid`              | `load_grid(level_data: LevelData) -> void`                                          | —                          | Clears existing state, populates tile dictionary from `LevelData` resource. Clamps to `MAX_GRID_SIZE`.                           |
| `is_walkable`            | `is_walkable(coord: Vector2i) -> bool`                                              | `true` if WALKABLE         | Out-of-bounds → `false`. Primary query used by Sliding Movement.                                                                 |
| `get_tile`               | `get_tile(coord: Vector2i) -> TileData`                                             | `TileData`                 | Out-of-bounds → default `TileData(BLOCKING, NONE)`. Never returns null.                                                          |
| `get_all_walkable_tiles` | `get_all_walkable_tiles() -> Array[Vector2i]`                                       | Array of coords            | Cached after `load_grid()`; not computed per-call. Used by Coverage Tracking and BFS Solver.                                     |
| `get_width`              | `get_width() -> int`                                                                | Grid width                 | Returns 0 if Uninitialized.                                                                                                      |
| `get_height`             | `get_height() -> int`                                                               | Grid height                | Returns 0 if Uninitialized.                                                                                                      |
| `get_tile_art_id`        | `get_tile_art_id(walkability: TileWalkability, obstacle_type: ObstacleType) -> int` | TileMapLayer atlas cell ID | Maps tile type to visual atlas ID; used at load time to drive TileMapLayer. Atlas IDs defined in coordination with Art Director. |

### States and Transitions

| State             | Entry Condition                   | Exit Condition                             | Behavior                                                     |
| ----------------- | --------------------------------- | ------------------------------------------ | ------------------------------------------------------------ |
| **Uninitialized** | Game start / scene loaded         | `load_grid()` called with valid level data | All queries return default BLOCKING; grid dimensions are 0×0 |
| **Loaded**        | `load_grid()` called successfully | Level scene freed / new level loaded       | All queries return live tile data                            |

No tile-level state transitions in Grid System at MVP scope. The grid is a static lookup table once loaded.

### Interactions with Other Systems

| System                   | Direction                | Interface                                                                                                                                                                                                                 |
| ------------------------ | ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Level Data Format**    | Level Data Format → Grid | Calls `load_grid(level_data: LevelData)` at scene start; Grid reads tile layout from the `LevelData` resource                                                                                                             |
| **Sliding Movement**     | Sliding Movement → Grid  | Calls `is_walkable(coord)` repeatedly to find the cat's stopping position during a slide                                                                                                                                  |
| **Coverage Tracking**    | Coverage Tracking → Grid | Calls `get_all_walkable_tiles() -> Array[Vector2i]` once at level load to know which tiles must be covered; calls `is_walkable(coord)` to validate tiles                                                                  |
| **Obstacle System**      | Obstacle System → Grid   | At MVP: static walls are BLOCKING tiles baked into the level file; no runtime interface needed for MVP. Post-jam: Obstacle System will call `set_tile_walkability(coord, walkability)` during dynamic obstacle activation |
| **BFS Minimum Solver**   | BFS Solver → Grid        | Reads the full tile dictionary via `get_all_walkable_tiles()` and `is_walkable(coord)` to enumerate the full puzzle state space                                                                                           |
| **TileMapLayer (Godot)** | Grid → TileMapLayer      | Grid System drives the visual tile rendering by calling TileMapLayer cell APIs to match the logical grid state after load                                                                                                 |

## Formulas

### Coordinate-to-Array Index (reference formula for BFS Solver)

```
index = col + row * grid_width
```

| Variable     | Type | Range                  | Description           |
| ------------ | ---- | ---------------------- | --------------------- |
| `col`        | int  | 0 to `grid_width - 1`  | Column (x) coordinate |
| `row`        | int  | 0 to `grid_height - 1` | Row (y) coordinate    |
| `grid_width` | int  | 3 to `MAX_GRID_SIZE`   | Grid width in tiles   |

_Note: The runtime uses `Dictionary[Vector2i, TileData]`, so this formula is a reference only — used by the BFS Solver if it constructs an internal state array for performance._

### Grid Tile Count

```
total_tiles = grid_width * grid_height
walkable_tiles = count of tiles where TileWalkability == WALKABLE
```

Coverage Tracking uses `walkable_tiles` as its completion denominator. This is computed once at level load and stored as a cached value; it is not a per-frame calculation.

## Edge Cases

| Scenario                                              | Expected Behavior                                                                       | Rationale                                                                        |
| ----------------------------------------------------- | --------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| `is_walkable(coord)` called with out-of-bounds coord  | Returns `BLOCKING` (false)                                                              | Sliding Movement stops at grid edge without a dedicated bounds check; no crash   |
| `get_tile(coord)` called with out-of-bounds coord     | Returns a default `TileData` with `TileWalkability.BLOCKING` and `ObstacleType.NONE`    | Consistent with out-of-bounds = wall rule; no null-dereference risk              |
| Level has zero walkable tiles                         | `get_all_walkable_tiles()` returns empty array; Coverage Tracking logs an error at load | Indicates a malformed level file; must not crash                                 |
| `load_grid()` called while a grid is already loaded   | Previous grid state is fully cleared before loading new state                           | Level restart and world transitions both call `load_grid()`; no stale data leaks |
| Grid with all tiles WALKABLE (no walls)               | Valid — Coverage Tracking covers all tiles; Sliding Movement slides to grid edge        | Tests the minimum-obstacle case; a valid (if trivial) puzzle                     |
| Grid filled entirely with BLOCKING tiles              | `get_all_walkable_tiles()` returns empty array; treated as malformed level              | Invalid level design; caught by the same zero-walkable guard                     |
| `col` or `row` is negative                            | Out-of-bounds rule applies; returns `BLOCKING`                                          | Prevents underflow in BFS/slide code without explicit clamp logic in callers     |
| Level file specifies grid larger than `MAX_GRID_SIZE` | `load_grid()` clamps to `MAX_GRID_SIZE` and logs a warning; does not crash              | Guards against malformed or hand-edited level files                              |
| Duplicate coordinate in level file                    | Last-write wins during `load_grid()`; warning logged                                    | Dictionary insert semantics; should be caught at level design time, not runtime  |

## Dependencies

| System                 | Direction                | Nature                                                                                                              | Hard/Soft                                                |
| ---------------------- | ------------------------ | ------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------- |
| **Level Data Format**  | Level Data Format → Grid | Provides tile layout at level load; Grid reads `LevelData` resource to populate its dictionary                      | **Hard** — Grid cannot be populated without it           |
| **Sliding Movement**   | Sliding Movement → Grid  | Queries `is_walkable(coord)` to find slide destination                                                              | **Hard** — movement cannot function without the grid     |
| **Coverage Tracking**  | Coverage Tracking → Grid | Queries `get_all_walkable_tiles()` at load; queries `is_walkable(coord)` during play                                | **Hard** — no completion detection without the grid      |
| **Obstacle System**    | Obstacle System → Grid   | Reads tile data at load (MVP: static walls are baked into level file); post-jam: will call `set_tile_walkability()` | **Hard** at MVP; adds write dependency post-jam          |
| **BFS Minimum Solver** | BFS Solver → Grid        | Reads full tile layout to enumerate the puzzle state space                                                          | **Hard** — solver cannot run without the grid            |
| **TileMapLayer**       | Grid → TileMapLayer      | Grid drives TileMapLayer visual cell data after load                                                                | **Soft** — game logic is unaffected; only display breaks |

## Tuning Knobs

| Parameter                          | Current Value | Safe Range | Effect of Increase                                                                                                     | Effect of Decrease                                                    |
| ---------------------------------- | ------------- | ---------- | ---------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| `MIN_GRID_SIZE` (width and height) | 3             | 2–5        | More room for trivial tutorial puzzles                                                                                 | Below 2 creates single-tile grids; meaningless as a puzzle            |
| `MAX_GRID_SIZE` (width and height) | 15            | 8–20       | Larger puzzles; BFS pre-computation time grows exponentially with walkable tile count; level creation effort increases | Caps complexity; may constrain late-game puzzle design in full vision |
| `DEFAULT_TILE_SIZE_PX`             | 64            | 32–128     | Grid tiles larger on screen; fewer tiles visible; easier to tap on mobile                                              | Tiles smaller; more fit on screen; harder to tap precisely on mobile  |

_Note_: `DEFAULT_TILE_SIZE_PX` affects rendering and input hit areas, not the logical grid. The Grid System exposes this as a constant; visual tile sizing is implemented in TileMapLayer configuration and referenced by the Input System for tap zone calculations.

## Visual/Audio Requirements

| Event                       | Visual Feedback                                                    | Audio Feedback | Priority |
| --------------------------- | ------------------------------------------------------------------ | -------------- | -------- |
| Level load complete         | TileMapLayer renders the full grid using the correct tile art      | None           | Required |
| WALKABLE tile               | Rendered with floor tile sprite (pastel, flat, thick-outlined)     | None           | Required |
| BLOCKING / STATIC_WALL tile | Rendered with wall tile sprite (distinct color/texture from floor) | None           | Required |
| Out-of-bounds region        | Not rendered — camera is framed to grid bounds only                | None           | Required |

_Note: All visual tile art is owned by the Art Director. The Grid System manages tile type data only; TileMapLayer handles rendering. The Grid System must expose a `get_tile_art_id(TileWalkability, ObstacleType) -> int` mapping so TileMapLayer cell IDs can be assigned at load time._

## UI Requirements

The Grid System has no direct UI responsibilities. Grid state is surfaced to the player by other systems:

- **Coverage Tracking** is responsible for the tile coverage glow / completion display
- **Obstacle System** is responsible for obstacle-specific visual overlays
- **TileMapLayer** renders the grid itself — no separate UI widget is needed

The Grid System's only presentation obligation is correctly driving the TileMapLayer cell data after `load_grid()`.

## Acceptance Criteria

- [ ] `load_grid(level_data)` correctly populates the tile dictionary from a valid `LevelData` resource
- [ ] `is_walkable(Vector2i(0,0))` returns `true` for a FLOOR tile and `false` for a WALL tile
- [ ] `is_walkable(Vector2i(-1, 0))` returns `false` (negative coordinate = out-of-bounds = BLOCKING)
- [ ] `is_walkable(Vector2i(100, 100))` returns `false` on a 6×6 grid (far out-of-bounds = BLOCKING)
- [ ] `get_all_walkable_tiles()` returns exactly the correct count of WALKABLE tiles for a known test level
- [ ] Calling `load_grid()` twice in sequence leaves no stale data from the first call
- [ ] A level with zero walkable tiles: `get_all_walkable_tiles()` returns an empty array with no crash
- [ ] A level file specifying a 20×20 grid is clamped to 15×15 with a logged warning
- [ ] TileMapLayer visual state matches the logical grid state after `load_grid()` (visual tile IDs match tile types)
- [ ] Performance: `load_grid()` completes within 5ms for a 15×15 grid on target mobile hardware

## Open Questions

| Question                                                                                                               | Owner                           | Target Resolution                            | Resolution |
| ---------------------------------------------------------------------------------------------------------------------- | ------------------------------- | -------------------------------------------- | ---------- |
| Should `ObstacleType` use a GDScript `enum` on `TileData`, or a separate `Resource` subclass per obstacle type?        | Lead Programmer                 | Before Level Data Format GDD is approved     | Open       |
| Which TileMapLayer atlas cell IDs map to FLOOR vs STATIC_WALL? (Art-dependent)                                         | Art Director                    | Before first art sprint                      | Open       |
| Post-jam: should `set_tile_walkability()` emit a signal so Coverage Tracking and Sliding Movement can react mid-level? | Game Designer + Lead Programmer | When Dynamic Obstacles are scoped (post-jam) | Deferred   |
