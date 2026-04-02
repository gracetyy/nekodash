# Level Data Format

> **Status**: Approved
> **Author**: Grace + GitHub Copilot
> **Last Updated**: 2026-03-31
> **Implements Pillar**: Infrastructure — defines the puzzle; enables all pillars

## Overview

The Level Data Format defines the on-disk schema and in-memory resource structure for a single NekoDash puzzle level. It is a Godot `Resource` subclass (`LevelData`) stored as a `.tres` file that carries everything needed to instantiate a playable level: the grid dimensions, per-tile walkability and obstacle data, the cat's starting position, pre-computed minimum move count, and level metadata (ID, world, display name, star thresholds). The Grid System's `load_grid(level_data: LevelData)` call is the primary consumer, but the BFS Solver, Move Counter, Star Rating System, and Level Progression all read fields from the same resource. All 15–20 MVP levels ship as `.tres` files bundled with the game. The format is the single source of truth for puzzle content — no puzzle data is hard-coded anywhere else.

## Player Fantasy

The Level Data Format has no direct player fantasy — the player never sees or touches it. Its emotional contribution is the integrity of the puzzle itself: a well-formed level file is what makes a puzzle feel authored and intentional, not generated. When a player stares at a grid and thinks "there's definitely a clever path here," they're trusting that someone thought carefully about the tile layout, the cat's starting position, and whether the minimum move count is achievable. The Level Data Format is the vessel that carries that authorship from the level designer to the player. It serves every pillar indirectly: a correctly structured level file is a prerequisite for **Pillar 1 — Every Move Is a Choice** being meaningful at all.

## Detailed Design

### Core Rules

1. A level is represented as a Godot `Resource` subclass called `LevelData` (`class_name LevelData extends Resource`). Each level ships as a `.tres` file loadable via Godot's `load()` or `preload()`.
2. `LevelData` contains two parallel `PackedInt32Array` fields — `walkability_tiles` and `obstacle_tiles` — indexed by `col + row * grid_width`. Index 0 = top-left `(0, 0)`. Values map to `TileWalkability` and `ObstacleType` integer values respectively. This layout mirrors the Grid System's coordinate convention exactly.
3. `LevelData` stores the cat's starting position as a `Vector2i`. The start position must be a WALKABLE tile. Loading a level where the cat start is on a BLOCKING tile is a content error — `load_grid()` logs a warning and falls back to the first available WALKABLE tile.
4. `LevelData` stores `minimum_moves: int` — the pre-computed BFS optimal solution. This value is calculated offline by the BFS Minimum Solver tool and baked into the `.tres` file before shipping. It is **never computed at runtime**.
5. `LevelData` stores three star-threshold fields:
   - `star_3_moves: int` — moves ≤ this → 3 stars (equals `minimum_moves` for well-authored levels)
   - `star_2_moves: int` — moves ≤ this → 2 stars (see Formulas section for default guideline)
   - `star_1_moves: int` — moves ≤ this → 1 star (see Formulas section for default guideline)
   - Completing in > `star_1_moves` → 0 stars (level complete but no rating)
6. `LevelData` contains level metadata: `level_id: String` (unique, e.g. `"w1_l1"`), `world_id: int` (1-based), `level_index: int` (1-based, within world), and `display_name: String`.
7. Level files are read-only at runtime. The game never writes back to `.tres` level files. Player progress (stars earned, completion status) is stored separately by the Save/Load System.
8. Level files are organized in `assets/levels/world_{n}/` subdirectories. The Level Progression system indexes them by scanning this directory structure at startup (or from a hand-maintained manifest — see Open Questions).

### `LevelData` Resource Schema

```gdscript
class_name LevelData
extends Resource

## Identity
@export var level_id: String           # e.g. "w1_l1" — unique across all levels
@export var world_id: int              # 1-based world number
@export var level_index: int           # 1-based position within the world
@export var display_name: String       # e.g. "First Steps"

## Grid Layout
@export var grid_width: int            # 3–MAX_GRID_SIZE (15)
@export var grid_height: int           # 3–MAX_GRID_SIZE (15)
@export var walkability_tiles: PackedInt32Array   # TileWalkability int values, row-major
@export var obstacle_tiles: PackedInt32Array      # ObstacleType int values, row-major
@export var cat_start: Vector2i        # Starting tile coord for the cat

## Pre-computed Solution
@export var minimum_moves: int         # BFS optimal; 0 = not yet solved

## Star Rating Thresholds
@export var star_3_moves: int          # ≤ this = 3 stars (should equal minimum_moves)
@export var star_2_moves: int          # ≤ this = 2 stars
@export var star_1_moves: int          # ≤ this = 1 star
```

### States and Transitions

The `LevelData` resource itself is stateless — it is a pure data container. The loading lifecycle is:

| State       | Entry Condition                               | Exit Condition                      | Behavior                                                        |
| ----------- | --------------------------------------------- | ----------------------------------- | --------------------------------------------------------------- |
| **On Disk** | Game ships / file exists                      | `load()` or `preload()` called      | `.tres` file; not yet in memory                                 |
| **Loaded**  | Godot resource system loads it                | Level scene freed                   | `LevelData` object in memory; passed to `load_grid(level_data)` |
| **In Use**  | `load_grid(level_data)` called by Grid System | Level scene freed / new level loads | Grid System, Move Counter, Star Rating read from it             |
| **Freed**   | Level scene queue_free()'d                    | —                                   | GC'd if no other references                                     |

### Interactions with Other Systems

| System                 | Direction                             | Interface                                                                                                          |
| ---------------------- | ------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| **Grid System**        | Level Data Format → Grid              | `load_grid(level_data: LevelData)` — Grid reads `grid_width`, `grid_height`, `walkability_tiles`, `obstacle_tiles` |
| **Sliding Movement**   | Level Data Format → Sliding Movement  | Reads `cat_start: Vector2i` to place the cat at level start                                                        |
| **Move Counter**       | Level Data Format → Move Counter      | Reads `minimum_moves`, `star_3_moves`, `star_2_moves`, `star_1_moves` to display targets and compute rating        |
| **BFS Minimum Solver** | Level Data Format → BFS Solver        | BFS Solver reads the full tile layout and writes back `minimum_moves` at level design time (offline only)          |
| **Obstacle System**    | Level Data Format → Obstacle System   | Reads `obstacle_tiles` to know which tiles have which obstacle types                                               |
| **Level Progression**  | Level Data Format → Level Progression | Reads `level_id`, `world_id`, `level_index` to build the ordered level list                                        |
| **Star Rating System** | Level Data Format → Star Rating       | Reads `star_3_moves`, `star_2_moves`, `star_1_moves` to assign star rating at level complete                       |

## Formulas

### Tile Array Index

```
index = col + row * grid_width
```

| Variable     | Type | Range                     | Description                |
| ------------ | ---- | ------------------------- | -------------------------- |
| `col`        | int  | 0 to `grid_width - 1`     | Column (x), left = 0       |
| `row`        | int  | 0 to `grid_height - 1`    | Row (y), top = 0           |
| `grid_width` | int  | 3 to `MAX_GRID_SIZE` (15) | Width of this level's grid |

This is the single formula used to map `Vector2i(col, row)` coordinates to `PackedInt32Array` indices. Both `walkability_tiles` and `obstacle_tiles` use this same index formula.

**Array length**: `grid_width * grid_height`

_Note: This matches the reference formula in the Grid System GDD — both use row-major order with `col + row * width`._

### Total Tile Count

```
total_tiles = grid_width * grid_height
walkable_count = count(walkability_tiles[i] == TileWalkability.WALKABLE)
```

`walkable_count` is the coverage target for Coverage Tracking. It is derived from the level file at load time and cached by the Grid System — never stored as a field in `LevelData`.

### Star Threshold Defaults

These are authoring guidelines for level designers, not enforced formulas. The BFS Minimum Solver fills `minimum_moves`; the designer chooses the other thresholds:

```
star_3_moves = minimum_moves          # perfect play
star_2_moves = minimum_moves + floor(minimum_moves * 0.4)   # ~40% slack
star_1_moves = minimum_moves + floor(minimum_moves * 1.0)   # ~100% slack
```

| Level Difficulty | Suggested star_2 slack | Suggested star_1 slack |
| ---------------- | ---------------------- | ---------------------- |
| Tutorial (easy)  | +3                     | +8                     |
| Normal           | +floor(min \* 0.4)     | +floor(min \* 1.0)     |
| Hard             | +1 or +2               | +floor(min \* 0.5)     |

_These are suggestions only — designers override per level. The formulas here guide first-pass authoring._

## Edge Cases

| Scenario                                                         | Expected Behavior                                                                                                    | Rationale                                                                 |
| ---------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| `walkability_tiles` length ≠ `grid_width * grid_height`          | `load_grid()` logs an error, treats all tiles as BLOCKING, does not crash                                            | Corrupted or hand-edited `.tres`; must not crash the game                 |
| `cat_start` is on a BLOCKING tile                                | `load_grid()` logs a warning, falls back to first WALKABLE tile in row-major order                                   | Content authoring error; should be caught by BFS Solver at design time    |
| `cat_start` is out of bounds                                     | Same fallback as above — warning + first WALKABLE tile                                                               | Prevents null-position errors in Sliding Movement                         |
| `minimum_moves == 0`                                             | Treat as "not yet solved"; Move Counter still displays current move count; no star rating assigned at level complete | BFS hasn't been run yet; allows testing levels before solving them        |
| `star_3_moves < minimum_moves`                                   | Use `minimum_moves` as the effective `star_3_moves` floor; log a warning                                             | Designer error — 3 stars can never be less demanding than the BFS minimum |
| `star_2_moves <= star_3_moves` or `star_1_moves <= star_2_moves` | Clamp thresholds to be strictly ascending; log a warning                                                             | Prevents all stars mapping to the same move count                         |
| `grid_width` or `grid_height` outside 3–`MAX_GRID_SIZE`          | `load_grid()` clamps to valid range; logs a warning                                                                  | Consistent with Grid System clamping behavior                             |
| Level file missing from expected path                            | Godot `load()` returns null; Level Progression skips the level and logs an error                                     | Missing file is a distribution error, not a runtime crash scenario        |
| Two levels with the same `level_id`                              | Level Progression logs a warning and keeps the first loaded; second is ignored                                       | Authoring error; `level_id` must be unique                                |
| `walkable_count == 0` (no walkable tiles)                        | `load_grid()` treats this as a malformed level; Grid System returns empty `get_all_walkable_tiles()`                 | Same guard as documented in Grid System GDD                               |

## Dependencies

| System                 | Direction                             | Nature                                                                                                                          | Hard/Soft                                                                         |
| ---------------------- | ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| **Grid System**        | Level Data Format → Grid System       | `LevelData` is the input to `load_grid()`; Grid System reads `grid_width`, `grid_height`, `walkability_tiles`, `obstacle_tiles` | **Hard** — Grid cannot be populated without it; the whole game depends on this    |
| **Sliding Movement**   | Level Data Format → Sliding Movement  | Reads `cat_start` to position the cat at level start                                                                            | **Hard** — cat has no valid starting tile without this                            |
| **Move Counter**       | Level Data Format → Move Counter      | Reads `minimum_moves` and star thresholds                                                                                       | **Hard** — Move Counter cannot display targets or compute star ratings without it |
| **BFS Minimum Solver** | Level Data Format ↔ BFS Solver        | BFS reads tile layout; writes `minimum_moves` back at level design time (offline tool, not runtime dependency)                  | **Hard** (offline) — `minimum_moves` must be populated before shipping a level    |
| **Obstacle System**    | Level Data Format → Obstacle System   | Reads `obstacle_tiles` to initialize obstacle state at level load                                                               | **Hard** — Obstacle System cannot distinguish wall types without it               |
| **Level Progression**  | Level Data Format → Level Progression | Reads `level_id`, `world_id`, `level_index` to build the ordered level sequence                                                 | **Hard** — progression ordering breaks without these fields                       |
| **Star Rating System** | Level Data Format → Star Rating       | Reads star threshold fields at level complete                                                                                   | **Hard** — ratings cannot be assigned without thresholds                          |
| **Save / Load System** | Save/Load ↔ Level Data Format         | Save/Load stores player progress keyed on `level_id`; never writes to the `.tres` file itself                                   | **Soft** — game works without save; progress is just lost on restart              |

## Tuning Knobs

The Level Data Format itself has no runtime tuning knobs — it is a data schema, not a system with live parameters. The following authoring parameters apply at level design time:

> **Content Convention — Catalogue path**: The `LevelCatalogue` resource must be saved at
> `res://assets/levels/level_catalogue.tres`. This exact path is hardcoded in World Map
> and used by Level Coordinator via `@export`. If the file is placed anywhere else,
> both systems silently fail to load levels.

| Parameter             | Default Guideline                    | Notes                                                                        |
| --------------------- | ------------------------------------ | ---------------------------------------------------------------------------- |
| `star_3_moves`        | = `minimum_moves`                    | Authoring guideline; set per level by designer after BFS run                 |
| `star_2_moves`        | = `minimum_moves + floor(min * 0.4)` | More generous for hard levels; tighter for tutorial levels                   |
| `star_1_moves`        | = `minimum_moves + floor(min * 1.0)` | Should be achievable by a first-time player with no optimization             |
| Level count per world | 5–7 levels                           | Not enforced by format; guideline for Level Progression and World Map design |
| World count at MVP    | 3 worlds                             | Not enforced by format; matches game-concept.md MVP scope                    |

_Note_: `MAX_GRID_SIZE` (15) and `MIN_GRID_SIZE` (3) are owned by the Grid System GDD and referenced here — they are not redefined.

## Visual/Audio Requirements

The Level Data Format is pure data — no visual or audio output. The tile, obstacle, and layout data it carries is consumed by:

- **Grid System / TileMapLayer**: renders the tile grid visually from `walkability_tiles` + `obstacle_tiles`
- **Sliding Movement**: places the cat sprite at `cat_start`

The Level Data Format has no direct rendering or audio responsibilities.

## UI Requirements

The Level Data Format has no direct UI responsibilities. Its fields surface to the player through downstream systems:

- `display_name` → displayed by the **World Map / Level Select** screen above each level card
- `minimum_moves` → displayed by the **Move Counter** HUD as the target
- `star_3/2/1_moves` → used by **Star Rating System** at level-complete screen
- `world_id` + `level_index` → used by **Level Progression** to order levels in the World Map

The Level Data Format does not own or render any of this UI itself.

## Acceptance Criteria

| #    | Criterion                                                                                                                                                |
| ---- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AC-1 | A valid `.tres` file loads without errors via `ResourceLoader.load()`; the resulting object is an instance of `LevelData`.                               |
| AC-2 | `load_grid(level_data)` correctly populates the Grid System's tile dictionary from `walkability_tiles` and `obstacle_tiles` using the index formula.     |
| AC-3 | The cat spawns at `cat_start` after level load; `cat_start` is a WALKABLE tile.                                                                          |
| AC-4 | A level file where `walkability_tiles.size() != grid_width * grid_height` causes `load_grid()` to log an error and set all tiles to BLOCKING — no crash. |
| AC-5 | `minimum_moves > 0` for all shipped levels; Move Counter displays it as the target on level load.                                                        |
| AC-6 | `star_3_moves >= minimum_moves`; `star_2_moves > star_3_moves`; `star_1_moves > star_2_moves` — enforced by clamping with logged warnings if violated.   |
| AC-7 | `level_id` is unique across all loaded levels; duplicate IDs log a warning, and Level Progression uses only the first loaded.                            |
| AC-8 | A level with `cat_start` on a BLOCKING tile logs a warning and falls back to the first WALKABLE tile in row-major order — no crash.                      |
| AC-9 | All 15–20 MVP levels load correctly in < 16 ms each (measured in Godot profiler on target device).                                                       |

## Open Questions

| #    | Question                                                                                                                                                                                                       | Priority | Owner                                                      |
| ---- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------------------------------------------------- |
| OQ-1 | Should Level Progression discover level files by scanning `assets/levels/` at startup, or from a hand-maintained manifest array? Scanning is convenient; a manifest is more predictable and easier to order.   | Medium   | Resolve during Level Progression GDD                       |
| OQ-2 | Should `ObstacleType` remain an enum or migrate to a Godot `Resource` per obstacle for richer post-jam data? (flagged as open in Grid System GDD)                                                              | Medium   | Resolve before first art sprint; flagged in Grid System OQ |
| OQ-3 | Should star thresholds be stored per-level in `LevelData` (current design) or in a separate balance data file shared across all levels? Per-level is flexible; a shared file is easier to re-balance globally. | Low      | Resolve during Star Rating System GDD                      |
| OQ-4 | Does `LevelData` need a `version: int` field for forward-compatibility if the schema changes post-jam? Low risk for a jam scope but important for live updates.                                                | Low      | Resolve before first public release                        |
