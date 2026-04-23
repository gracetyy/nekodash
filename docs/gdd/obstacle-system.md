# Obstacle System

> **Status**: Approved
> **Author**: Grace + GitHub Copilot
> **Last Updated**: 2026-03-31
> **Implements Pillar**: Pillar 1 — Every Move Is a Choice

## Overview

The Obstacle System manages the non-floor tile data for a loaded level. Its two
responsibilities at MVP are: (1) build an in-memory index of obstacle coordinates
and types after `load_grid()` completes, and (2) drive the `TileMapLayer` node's
visual cell assignments for all tiles — both walkable floor and BLOCKING walls — using
the art-ID mapping already defined in Grid System. At MVP scope (static walls only),
the Obstacle System has no runtime gameplay function: tile walkability is baked into
the level file and never changes during a session. It is lightweight by design, and
its primary value at MVP is correct visual rendering and a stable, extensible API
that post-jam dynamic obstacles (`MOVING_WALL`, `TIMED_WALL`, `TELEPORTER`) can slot
into without requiring changes to any other system.

## Player Fantasy

The walls are the puzzle. When a player glances at a new level, their eyes trace the
wall clusters before making the first swipe: "If I go right, I end up against that
wall. If I go up from there, I'll pocket into this corner. Can I thread the whole
board in eight moves?" That spatial reasoning — reading wall layout as a language —
is the entire cognitive experience of NekoDash.

The Obstacle System's job is to make that reading instant and accurate. Walls must
look visually solid, spatially distinct from the floor, and must precisely match the
game's collision logic. A player who slides the cat and it stops exactly where they
expected — against that wall, in that corner — is trusting that the visual wall and
the logical wall are the same thing. Any gap between graphic and physics destroys
that trust and makes the puzzle feel unfair.

This serves **Pillar 1 — Every Move Is a Choice**: spatial reasoning only works if
the player can read the board. The Obstacle System makes the board readable.

## Detailed Design

### Core Rules

1. **Load sequence**: After `Grid.load_grid(level_data)` completes, the Obstacle
   System calls `initialize_obstacles()`. This is the single entry point for
   all per-level setup. It must execute before the first frame is rendered using
   that level's data.

2. **Full tile render pass**: `initialize_obstacles()` iterates every coordinate
   `(col, row)` in the grid (`0..grid_width-1` × `0..grid_height-1`). For each:
   - Fetches `TileData` via `Grid.get_tile(coord)`.
   - Calls `Grid.get_tile_art_id(tile.walkability, tile.obstacle_type)` to resolve
     the atlas cell ID.
   - Calls `TileMapLayer.set_cell(coord, atlas_id)` to set the visual cell.
     This single pass renders the entire level — both walkable floor tiles and BLOCKING
     wall tiles — using the art mapping owned by Grid System.

3. **Obstacle index**: During the same pass, for every tile where
   `tile.obstacle_type != ObstacleType.NONE`, the Obstacle System records the
   coordinate and type in `_obstacle_index: Dictionary[Vector2i, ObstacleType]`.
   An empty floor tile (`WALKABLE`, `NONE`) is not recorded.

4. **obstacle_registered signal**: For each tile added to `_obstacle_index`, emits
   `obstacle_registered(coord: Vector2i, type: ObstacleType)` after the visual cell
   is set. This gives downstream systems (e.g., a level-editor overlay tool) a
   hook into the obstacle population phase.

5. **Read-only at runtime (MVP)**: No tile walkability changes during a level session.
   The `_obstacle_index` is populated once at `initialize_obstacles()` and is
   read-only until `reset()` clears it at the next level load. Any method that would
   mutate walkability at runtime is stubbed and logs a warning in MVP builds.

6. **Reset**: `reset()` clears `_obstacle_index`, clears the `TileMapLayer` (all
   cells set to empty), and resets internal state. Called by the Scene Manager when
   transitioning away from a level scene.

7. **Post-jam extension point**: `set_obstacle_active(coord: Vector2i, active: bool)`
   is defined but stubbed at MVP. In post-jam builds, this method calls
   `Grid.set_tile_walkability(coord, BLOCKING if active else WALKABLE)` and updates
   the visual cell. `MOVING_WALL` and `TIMED_WALL` will call this on a timer or
   path schedule. `TELEPORTER` requires a separate interception hook in Sliding
   Movement (not part of Obstacle System's own API).

### States and Transitions

| State             | Entry Condition                    | Exit Condition                  | Behavior                                                           |
| ----------------- | ---------------------------------- | ------------------------------- | ------------------------------------------------------------------ |
| **Uninitialized** | Scene loaded; no level yet         | `initialize_obstacles()` called | `_obstacle_index` empty; TileMapLayer empty; queries return `NONE` |
| **Initialized**   | `initialize_obstacles()` completes | `reset()` called                | `_obstacle_index` populated; TileMapLayer rendered; queries live   |
| **Reset**         | `reset()` called                   | `initialize_obstacles()` called | Same as Uninitialized; TileMapLayer cleared                        |

### Interactions with Other Systems

| System                 | Direction                          | Interface                                                                                                                                 |
| ---------------------- | ---------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| **Grid System**        | Grid → Obstacle System             | After `Grid.load_grid()`, Obstacle System calls `Grid.get_tile(coord)` for all coords; calls `Grid.get_tile_art_id()` for atlas IDs.      |
| **Level Data Format**  | Level Data Format → (via Grid)     | Obstacle System reads obstacle data indirectly through Grid after `load_grid()` populates the tile dictionary. No direct LevelData read.  |
| **TileMapLayer**       | Obstacle System → TileMapLayer     | `TileMapLayer.set_cell(coord, atlas_id)` called for every tile at `initialize_obstacles()`. `TileMapLayer.clear()` called at `reset()`.   |
| **Scene Manager**      | Scene Manager → Obstacle System    | Scene Manager calls `reset()` when unloading a level scene. Calls `initialize_obstacles()` (or triggers its caller) at level load.        |
| **Sliding Movement**   | Obstacle System → (none, indirect) | No direct signal connection at MVP. Sliding Movement queries `Grid.is_walkable()` which reads the same tile data Obstacle System indexed. |
| **Coverage Tracking**  | Obstacle System → (none)           | BLOCKING tiles are excluded from `Grid.get_all_walkable_tiles()` and therefore excluded from Coverage Tracking's total automatically.     |
| **BFS Minimum Solver** | Obstacle System → (none)           | BFS is offline; it reads tile data from `LevelData`/Grid directly when run. No Obstacle System dependency at runtime.                     |

## Formulas

### Tile Index (linear to grid coordinate)

Tile arrays in `LevelData` are row-major. Obstacle System uses the same convention
when iterating in coordination with Grid System:

$$
\text{index}(col, row) = col + row \times \text{grid\_width}
$$

Obstacle System does not use this formula directly — it iterates `(col, row)` loops
and calls `Grid.get_tile(Vector2i(col, row))`. Grid System owns the index-to-coord
conversion internally.

### Obstacle Density (level design reference)

Not a runtime formula — a design guideline for level authors:

$$
\text{obstacle\_density} = \frac{\text{count(BLOCKING tiles)}}{\text{total\_tiles}}
$$

| Recommended Range | Notes                                                                               |
| ----------------- | ----------------------------------------------------------------------------------- |
| 0.10 – 0.20       | MVP sweet spot: sparse enough to leave a navigable board, dense enough to challenge |
| < 0.10            | Trivially open; BFS minimum likely ≤ 3 moves                                        |
| > 0.30            | Risk of unsolvable layouts or unusually short slide distances                       |

_This is guidance only. BFS Solver validates solvability — density alone does not._

## Edge Cases

| Scenario                                                         | Expected Behavior                                                                                                                | Rationale                                                                              |
| ---------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| Grid not yet initialized when `initialize_obstacles()` is called | Log error; no-op. `_obstacle_index` remains empty; TileMapLayer is not touched.                                                  | Caller must sequence `Grid.load_grid()` before `initialize_obstacles()`                |
| `obstacle_tiles` contains a value not in `ObstacleType` enum     | Use `ObstacleType.NONE` as fallback; log a warning with the offending coord and raw value                                        | Malformed level file guard; game should not crash on bad data                          |
| BLOCKING tile with `obstacle_type == NONE`                       | Visual cell is set correctly (plain wall appearance); tile is NOT added to `_obstacle_index` (index only tracks `!= NONE` types) | Outer-border or implied walls may be BLOCKING with no named obstacle type — valid      |
| `initialize_obstacles()` called twice without `reset()` between  | Clears `_obstacle_index` and resets TileMapLayer before re-populating; no duplicate entries                                      | Defensive for scene reuse patterns                                                     |
| Tile at the grid boundary (col 0, row 0, etc.)                   | Processed identically to interior tiles; no special handling                                                                     | Grid System handles boundary semantics; Obstacle System simply iterates the full range |
| `get_obstacle_at()` queried for out-of-bounds coord              | Returns `ObstacleType.NONE`; no crash                                                                                            | Consistent with Grid System's out-of-bounds convention                                 |
| `set_obstacle_active()` called at MVP runtime                    | Logs a warning ("Dynamic obstacles not supported in MVP"); no state change                                                       | Post-jam stub guard                                                                    |

## Dependencies

| System                | Direction                       | Nature                                                                                                | Hard/Soft                                                                                        |
| --------------------- | ------------------------------- | ----------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| **Grid System**       | Grid → Obstacle System          | Reads all tile data and art IDs; `initialize_obstacles()` cannot function without an initialized Grid | **Hard** — Grid must be loaded first; Obstacle System has no data source without it              |
| **Level Data Format** | Level Data Format → (via Grid)  | Indirect; Grid reads `walkability_tiles` + `obstacle_tiles` from LevelData during `load_grid()`       | **Hard** (indirect) — malformed LevelData produces bad tile types; Obstacle System inherits that |
| **TileMapLayer**      | Obstacle System → TileMapLayer  | Drives all cell assignments; without TileMapLayer reference, visual rendering fails silently          | **Hard** for visuals; gameplay is unaffected (Grid owns collision logic)                         |
| **Scene Manager**     | Scene Manager → Obstacle System | Calls `reset()` at level unload; coordinates `initialize_obstacles()` timing at level load            | **Soft** — can be initialized manually; Scene Manager integration is the clean path              |

## Tuning Knobs

The Obstacle System itself has no runtime tuning knobs. All obstacle configuration is
baked into `LevelData` at level-design time. The only authoring-time parameters are:

| Parameter                  | Owner             | Description                                                                       |
| -------------------------- | ----------------- | --------------------------------------------------------------------------------- |
| `obstacle_type` per tile   | Level Data Format | Which `ObstacleType` enum value is assigned per tile                              |
| `walkability` per tile     | Level Data Format | Whether the tile is WALKABLE or BLOCKING                                          |
| Atlas tile art assignments | Grid System       | `get_tile_art_id()` mapping; controlled by Art Director in coordination with Grid |
| Obstacle density per level | Level Designer    | How many BLOCKING tiles a level contains; validated by BFS Solver for solvability |

Post-jam, if dynamic obstacles are introduced, tuning knobs will include:

- `MOVING_WALL` cycle period (seconds)
- `TIMED_WALL` on/off phase durations
- `TELEPORTER` destination coordinate pairs

## Visual/Audio Requirements

| Event / State                           | Owner            | Description                                                                       | Priority |
| --------------------------------------- | ---------------- | --------------------------------------------------------------------------------- | -------- |
| Static wall tile rendering              | Obstacle System  | `TileMapLayer.set_cell()` with correct STATIC_WALL atlas ID at level load         | Required |
| Floor tile rendering                    | Obstacle System  | Same render pass; WALKABLE tiles rendered with floor atlas ID                     | Required |
| Wall art (atlas tile design)            | Art Director     | Distinct, readable wall silhouettes; must not be confused with floor at a glance  | Required |
| Level-load tile reveal animation (opt.) | TileMapLayer     | Optional shader animation on tile populate; controlled by a separate visual layer | Stretch  |
| (Post-jam) Moving wall animation        | Technical Artist | Sprite or shader animation for MOVING_WALL tiles; Obstacle System drives position | Post-jam |
| (Post-jam) Timed wall glow/pulse        | Technical Artist | Visual indicator of TIMED_WALL activation state                                   | Post-jam |

No audio events are emitted by the Obstacle System directly. If wall graphics require
sound on level load (e.g., tiles clicking into place), that is owned by SFX Manager
reacting to `obstacle_registered`.

## UI Requirements

The Obstacle System has no UI of its own. The visual tiles rendered in `TileMapLayer`
are the only player-facing output. There is no HUD element, tooltip, or overlay
owned by the Obstacle System at MVP.

Level-editor tooling (out of MVP scope) may display the `_obstacle_index` contents
as an overlay, but that is a tools-programmer concern.

## Acceptance Criteria

| #     | Criterion                                                                                                                                   |
| ----- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| OS-1  | After `initialize_obstacles()`, every tile in the grid has a corresponding `TileMapLayer` cell set to a valid atlas ID.                     |
| OS-2  | Every tile where `obstacle_type != NONE` is present in `_obstacle_index` with the correct type.                                             |
| OS-3  | `obstacle_registered(coord, type)` is emitted exactly once per non-NONE obstacle tile during `initialize_obstacles()`.                      |
| OS-4  | BLOCKING tiles with `obstacle_type == NONE` are rendered correctly but are NOT added to `_obstacle_index`.                                  |
| OS-5  | After `reset()`, `_obstacle_index` is empty, and `TileMapLayer` has no cells set.                                                           |
| OS-6  | `get_obstacle_at(coord)` returns `ObstacleType.NONE` for an out-of-bounds coord without crashing.                                           |
| OS-7  | `initialize_obstacles()` called before `Grid.load_grid()` logs an error and performs no state changes.                                      |
| OS-8  | `initialize_obstacles()` called twice without `reset()` does not produce duplicate entries in `_obstacle_index`.                            |
| OS-9  | `set_obstacle_active()` called at MVP logs a warning and does not modify any grid or obstacle state.                                        |
| OS-10 | Visual tiles match collision data: every BLOCKING tile visible in TileMapLayer correctly returns `is_walkable() == false` from Grid System. |

## Open Questions

| #    | Question                                                                                                                                                                                                                                                                                                            | Priority | Owner                                        | Resolution                  |
| ---- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | -------------------------------------------- | --------------------------- |
| OQ-1 | Should Obstacle System drive ALL tile rendering (floor + walls in one pass), or should a separate FloorRenderer handle WALKABLE tiles while Obstacle System handles only BLOCKING/obstacle tiles? Provisional: single pass, Obstacle System renders everything — simpler, fewer nodes, trivially fast at MVP scale. | Low      | Resolve during Scene Manager or HUD GDD      | Provisional: single pass    |
| OQ-2 | The `TileMapLayer` reference — should Obstacle System hold a direct `@onready` reference to the TileMapLayer node, or receive it as a dependency injection at `initialize_obstacles(level_data, tilemap_layer)` call time? Provisional: dependency injection to keep Obstacle System scene-agnostic and testable.   | Medium   | Resolve during implementation                | Provisional: inject at call |
| OQ-3 | Post-jam: Which obstacle type is introduced in World 2? Game concept specifies "one new type per world." Candidates: `TELEPORTER` (most novel/fun), `MOVING_WALL` (most complex), `TIMED_WALL` (middle ground).                                                                                                     | Low      | Resolve during World 2 level/design planning | Open                        |
