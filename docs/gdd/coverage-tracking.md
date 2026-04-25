# Coverage Tracking

> **Status**: Approved
> **Author**: Grace + GitHub Copilot
> **Last Updated**: 2026-03-31
> **Implements Pillar**: Pillar 1 — Every Move Is a Choice; Pillar 3 — Complete Your Own Way

## Overview

The Coverage Tracking system maintains a persistent record of which walkable tiles have been visited during the current level attempt. The Level Coordinator routes completed moves into `apply_tiles_covered(...)` after it has already recorded the undo snapshot and incremented the move count. Coverage Tracking exposes the current coverage state to downstream systems. Its two primary outputs are: a `Dictionary[Vector2i, bool]` (or equivalent) accessible to the visual tile layer for rendering covered vs. uncovered tiles, and a `level_completed` signal emitted when coverage reaches 100%. Coverage Tracking holds no animation logic and no move logic — it is a pure state tracker. It never modifies the grid; it only records what has been visited. Coverage is monotonically increasing within a single attempt: tiles once covered cannot be uncovered except by Undo or Restart.

## Player Fantasy

The golden tiles. As the cat glides across the floor, each tile it touches lights up — a warm, pastel glow spreading behind the slide path. The player sees the total percentage (or tile count) ticking upward after every move. When the last tile finally lights up, the whole grid pulses with a completion flourish. The player didn't just reach an exit — they _filled the space_. That feeling of completing a canvas, tile by tile, is the core emotional loop of NekoDash.

This serves **Pillar 1 — Every Move Is a Choice** because the coverage visualization makes every slide's contribution legible: the player always knows which tiles are still unlit, and that information is what powers their routing decisions. It serves **Pillar 3 — Complete Your Own Way** because both the casual player (just finish the level, whatever order) and the perfectionist (plan the minimum-move route) are both chasing the same 100% coverage goal — just with different move counts.

## Detailed Design

### Core Rules

1. **Initialization**: At level load, Coverage Tracking calls `grid.get_all_walkable_tiles()` to get the complete set of tiles that must be covered. It stores this as a `Dictionary[Vector2i, bool]` where all values start as `false` (uncovered). The total count, `total_walkable: int`, is cached from this array's size.

2. **Starting tile**: Coverage Tracking receives `spawn_position_set(pos: Vector2i)` during level initialization. When received, it marks `coverage_map[pos] = true` and increments `covered_count`. This matches the BFS Solver's initial state convention: the starting tile is pre-covered before any move is made.

3. **Per-move coverage**: The Level Coordinator calls `apply_tiles_covered(from_pos, to_pos, direction, tiles_covered: Array[Vector2i])` after the undo snapshot and move counter update. For each `Vector2i` in `tiles_covered`, it sets `coverage_map[tile] = true` if not already set, and increments `covered_count` only for newly covered tiles.

4. **Coverage percentage**:

   ```
   coverage_percent = float(covered_count) / float(total_walkable) * 100.0
   ```

   This value is recomputed after every coordinator-dispatched coverage update and exposed as a read-only property.

5. **Level completion detection**: After processing each coordinator-dispatched coverage update, if `covered_count == total_walkable`, emit `level_completed`. This signal is the trigger for the level-complete flow (Move Counter captures final count, Star Rating computes stars, Level Complete Screen displays).

6. **No duplicate counting**: If a tile appears in `tiles_covered` that is already `true` in `coverage_map`, it is silently skipped. `covered_count` only increments for tiles newly transitioning from `false` to `true`.

7. **Undo support**: Undo/Restart owns coverage state rollback. Coverage Tracking exposes `get_coverage_snapshot() -> Dictionary[Vector2i, bool]` (a deep copy) and `restore_coverage_snapshot(snapshot: Dictionary[Vector2i, bool]) -> void`. The Undo system calls these before/after rewinding a move. When `restore_coverage_snapshot()` is called, `covered_count` is recomputed from the snapshot.

8. **Full restart**: On level restart, Undo/Restart calls `reset_coverage()` (or `initialize_level()` again). Coverage Tracking reinitializes from the Grid System, clearing all coverage and resetting `covered_count` to 0 before the spawn position is applied again.

9. **No rendering ownership**: Coverage Tracking does not draw tiles. It exposes the `coverage_map` and emits `tile_covered(coord: Vector2i)` per newly covered tile. The visual layer (TileMapLayer or a dedicated CoverageVisualizer node) subscribes to `tile_covered` and updates the tile's visual state. This keeps rendering entirely separate from tracking logic.

10. **Read-only access**: External systems (HUD, Level Complete Screen) read `covered_count` and `total_walkable` as properties. No external system writes to Coverage Tracking except Undo/Restart via the snapshot API.

### Signals

```gdscript
signal tile_covered(coord: Vector2i)           # Emitted once per newly covered tile
signal tile_uncovered(coord: Vector2i)         # Emitted per tile reverting to uncovered (undo / restore_coverage_snapshot)
signal coverage_updated(covered: int, total: int)  # Emitted after each slide_completed and after restore_coverage_snapshot
signal level_completed                         # Emitted when covered_count == total_walkable
```

### States and Transitions

| State             | Entry Condition                               | Exit Condition                      | Behavior                                                                              |
| ----------------- | --------------------------------------------- | ----------------------------------- | ------------------------------------------------------------------------------------- |
| **Uninitialized** | Scene loaded before `initialize_level()`      | `initialize_level()` called         | No tiles tracked; all queries return 0; `level_completed` never fires                 |
| **Tracking**      | `initialize_level()` called; tiles enumerated | `level_completed` fired; or reset   | Processes `spawn_position_set` + `slide_completed`; emits `tile_covered` per new tile |
| **Complete**      | `covered_count == total_walkable`             | `reset_coverage()` or level restart | `level_completed` emitted; no more tiles to cover; state frozen                       |

```
Uninitialized ──[initialize_level()]──► Tracking ──[all tiles covered]──► Complete
Complete ──[reset_coverage()]──► Tracking  (restart / undo resets here)
Tracking ──[restore_coverage_snapshot()]──► Tracking  (undo to earlier state)
```

### Interactions with Other Systems

| System                                | Direction                             | Interface                                                                                                                                                         |
| ------------------------------------- | ------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Grid System**                       | Coverage Tracking → Grid System       | Calls `grid.get_all_walkable_tiles() -> Array[Vector2i]` at initialization to enumerate the coverage target set.                                                  |
| **Level Coordinator**                 | Level Coordinator → Coverage Tracking | Calls `apply_tiles_covered(..., tiles_covered)` after move snapshot and move count update; `spawn_position_set(pos)` still pre-covers the start tile during init. |
| **Undo/Restart**                      | Bidirectional                         | Undo/Restart reads `get_coverage_snapshot()`, writes `restore_coverage_snapshot(snapshot)`, calls `reset_coverage()`.                                             |
| **HUD**                               | Coverage Tracking → HUD               | HUD subscribes to `coverage_updated(covered, total)` to display live coverage count or percentage.                                                                |
| **Level Coordinator**                 | Coverage Tracking → Level Coordinator | `level_completed` begins the rating→save→transition chain; Level Coordinator wires this connection to StarRatingSystem at scene init (see level-coordinator.md).  |
| **CoverageVisualizer** (visual layer) | Coverage Tracking → Visual            | Subscribes to `tile_covered(coord)` to apply the "covered" visual style to that grid tile.                                                                        |

## Formulas

### Coverage Percentage

```
coverage_percent = float(covered_count) / float(total_walkable) * 100.0
```

| Variable         | Type    | Range                 | Description                                       |
| ---------------- | ------- | --------------------- | ------------------------------------------------- |
| `covered_count`  | `int`   | 0 to `total_walkable` | Number of walkable tiles visited so far           |
| `total_walkable` | `int`   | 1 to 225              | Total walkable tiles in the level (max 15×15=225) |
| return           | `float` | 0.0–100.0             | Percentage of level covered; 100.0 = complete     |

_Note: `total_walkable` is never 0 in a valid level. If it is 0, Coverage Tracking logs an error and does not emit `level_completed` (a level with no walkable tiles cannot be completed)._

### Covered Count Update (per slide)

```
for tile in tiles_covered:
    if not coverage_map[tile]:          # Only count newly covered tiles
        coverage_map[tile] = true
        covered_count += 1
        tile_covered.emit(tile)
```

| Variable        | Type                         | Description                                                     |
| --------------- | ---------------------------- | --------------------------------------------------------------- |
| `tiles_covered` | `Array[Vector2i]`            | All tiles traversed in one completed move                       |
| `coverage_map`  | `Dictionary[Vector2i, bool]` | Per-tile coverage state                                         |
| `covered_count` | `int`                        | Running total of covered tiles; never decremented (except Undo) |

### Snapshot for Undo

```
func get_coverage_snapshot() -> Dictionary:
    return coverage_map.duplicate(true)   # deep copy

func restore_coverage_snapshot(snapshot: Dictionary) -> void:
    coverage_map = snapshot.duplicate(true)
    covered_count = 0
    for val in coverage_map.values():
        if val:
            covered_count += 1
```

_The snapshot is a full deep copy — no reference aliasing. `covered_count` is recomputed from scratch on restore to stay consistent._

## Edge Cases

| Scenario                                                                            | Expected Behavior                                                                                                                                                                      | Rationale                                                                                               |
| ----------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| `tiles_covered` in `apply_tiles_covered()` contains an already-covered tile         | Silently skip; `covered_count` does not increment twice                                                                                                                                | Cat revisiting previously covered tiles is valid and expected — coverage is idempotent                  |
| `tiles_covered` contains a coord that is not in `coverage_map`                      | Log an error ("tile not in coverage map — possible grid inconsistency"); skip that tile                                                                                                | Should never happen if the grid is consistent; defensive guard                                          |
| `spawn_position_set` fires before `initialize_level()` completes                    | `coverage_map` not yet built; log a warning; mark the tile after map is ready via `call_deferred`                                                                                      | Initialization ordering edge case; use `call_deferred` or ensure Level Manager calls in the right order |
| `apply_tiles_covered()` called while in `Complete` state                            | Ignore — no new tiles can be covered; no `level_completed` re-emitted                                                                                                                  | Could happen if a move dispatch was in flight when completion was reached; safely ignored               |
| Full restart before `initialize_level()` is called                                  | `reset_coverage()` is a no-op; does not crash                                                                                                                                          | Defensive; Level Manager may call reset in error recovery path                                          |
| `restore_coverage_snapshot()` called with a snapshot from a different level         | No crash, but coverage state will be incorrect; Undo system is responsible for matching snapshots to their level                                                                       | Undo system must not cross level boundaries                                                             |
| `total_walkable == 0` (malformed level)                                             | Log an error; `level_completed` never fires; player is soft-locked. Level Design guidelines and BFS Solver prevent this from shipping                                                  | Same guard as Grid System's zero-walkable edge case                                                     |
| Level completed on the first move (e.g., 1-tile level)                              | `tile_covered` emitted for starting tile on `spawn_position_set`; `covered_count == total_walkable`; `level_completed` fires after the first completed move — or at spawn if total = 1 | Degenerate but handled; BFS solver marks `minimum_moves = 0` for these                                  |
| Multiple completed moves in the same frame (cannot occur with current architecture) | Not possible — `is_accepting_input = false` during SLIDING prevents back-to-back moves in the same frame                                                                               | Documented for safety; architecture prevents it                                                         |

## Dependencies

| System                 | Direction                              | Nature                                                                                                                        | Hard/Soft                                                                                     |
| ---------------------- | -------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| **Grid System**        | Coverage Tracking → Grid System        | Calls `get_all_walkable_tiles()` at level init to build the tile set; no ongoing dependency                                   | **Hard** — cannot know which tiles to track without the grid                                  |
| **Level Coordinator**  | Level Coordinator → Coverage Tracking  | Calls `apply_tiles_covered()` after the move snapshot and move count update; no direct reference to Sliding Movement node     | **Hard** — coverage cannot advance without the coordinator dispatch                           |
| **Undo/Restart**       | Bidirectional                          | Undo reads snapshot; Coverage Tracking exposes snapshot API; `reset_coverage()` called on restart                             | **Hard** — without snapshot support, Undo cannot correctly restore coverage state             |
| **HUD**                | Coverage Tracking → HUD                | HUD subscribes to `coverage_updated`; Coverage Tracking has no reference to HUD                                               | **Soft** — game logic functions without HUD; only display breaks                              |
| **Level Coordinator**  | Coverage Tracking → Level Coordinator  | `level_completed` initiates the rating→save→transition chain via StarRatingSystem; Level Coordinator wires this at scene init | **Soft** — game logic reaches 100% without this; but player has no path to the results screen |
| **CoverageVisualizer** | Coverage Tracking → CoverageVisualizer | Subscribes to `tile_covered(coord)` and `tile_uncovered(coord)` for visual updates                                            | **Soft** — game logic is unaffected; only visual feedback breaks                              |

## Tuning Knobs

Coverage Tracking has no runtime tuning knobs — it is a deterministic state tracker. The following are design-time authoring guidelines:

| Parameter                     | Value / Guideline   | Notes                                                                                               |
| ----------------------------- | ------------------- | --------------------------------------------------------------------------------------------------- |
| Coverage completion threshold | 100% (all tiles)    | Not tunable; level completion is always 100% coverage by definition                                 |
| Starting tile pre-covered     | Always true         | Matches BFS Solver initial state; cannot be changed without breaking the minimum-move contract      |
| Coverage visualization style  | Owner: Art Director | Color, glow intensity, and tile transition animation are owned by the visual layer, not this system |

## Visual/Audio Requirements

Coverage Tracking itself produces no visuals or audio — it only emits signals. All visual and audio feedback is owned by downstream systems:

| Event                                 | Owner                               | Description                                                                                                                            | Priority |
| ------------------------------------- | ----------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| Tile first covered (`tile_covered`)   | CoverageVisualizer                  | Tile transitions from "uncovered" to the room's trail tile (`visited_paw` where available, else visited; or yellow Simple UI fallback) | Required |
| Coverage updated (`coverage_updated`) | HUD                                 | Live percentage or count update in HUD display                                                                                         | Required |
| Level completed (`level_completed`)   | Level Complete Screen + SFX Manager | Completion flourish animation + completion musical sting                                                                               | Required |
| Starting tile pre-covered             | CoverageVisualizer                  | Tile under cat spawn position shows as covered immediately on level load                                                               | Required |

_Note: The visual distinction between "covered" and "uncovered" tiles is one of NekoDash's primary feedback mechanisms. The tile color ramp (e.g., pale grey uncovered → warm gold covered) is a critical art direction decision to be resolved before the first art sprint. Coverage Tracking only provides the data model; the visual layer owns the presentation._

## UI Requirements

Coverage Tracking exposes data that surfaces in two UI locations:

- **HUD** (`coverage_updated` signal): Displays current coverage as a fraction (e.g., "12 / 20 tiles") or percentage. The exact format is owned by the HUD GDD. Coverage Tracking exposes `covered_count: int` and `total_walkable: int` as read properties.
- **Level Complete Screen** (`level_completed` signal): Serves as the trigger for the completion flow. Coverage Tracking does not own any completion UI.

Coverage Tracking has no other UI obligations.

## Acceptance Criteria

| #     | Criterion                                                                                                                                                            |
| ----- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| CT-1  | After `initialize_level()`, `coverage_map` contains exactly `total_walkable` entries, all set to `false`; `covered_count == 0`.                                      |
| CT-2  | After `spawn_position_set(pos)`, `coverage_map[pos] == true`; `covered_count == 1`; `tile_covered` was emitted with `pos`.                                           |
| CT-3  | After a slide covering tiles `[A, B, C]` (none previously covered), `covered_count` increases by 3; `tile_covered` emitted 3 times; `coverage_updated` emitted once. |
| CT-4  | A slide that revisits already-covered tiles increments `covered_count` only for the newly covered subset; no duplicate `tile_covered` emissions.                     |
| CT-5  | When `covered_count == total_walkable`, `level_completed` is emitted exactly once.                                                                                   |
| CT-6  | `level_completed` is not emitted a second time if additional slides arrive after completion (e.g., from any race condition).                                         |
| CT-7  | `get_coverage_snapshot()` returns a deep copy — mutating the snapshot does not affect the live `coverage_map`.                                                       |
| CT-8  | `restore_coverage_snapshot(snapshot)`: after restoration, `covered_count` matches the number of `true` values in the snapshot; `coverage_map` equals the snapshot.   |
| CT-9  | `reset_coverage()`: after call, `covered_count == 0`; all entries in `coverage_map` are `false`.                                                                     |
| CT-10 | Performance: `slide_completed` handler completes in ≤ 1ms for a 14-tile slide path on target mobile hardware.                                                        |

## Open Questions

| #    | Question                                                                                                                                                                                                                                                                                          | Priority | Owner                                       | Resolution               |
| ---- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ------------------------------------------- | ------------------------ |
| OQ-1 | Should `level_completed` be emitted synchronously within the move pipeline (same frame), or deferred to the next frame to allow animation to settle first? Currently: synchronous. If the completion animation and slide-landing animation conflict visually, defer. Revisit at first art sprint. | Medium   | Gameplay Programmer + Art Director          | Provisional: synchronous |
| OQ-2 | Should `coverage_updated` emit on every `tile_covered` (per tile), or only once at end of each coordinator-dispatched coverage update? Currently: once per move for performance. If HUD needs per-tile animation, change to per-tile.                                                             | Low      | Resolve during HUD GDD                      | Provisional: per-move    |
| OQ-3 | Is Coverage Tracking a standalone `Node` in the scene tree, an `Autoload` singleton, or a child of a Level Manager node? Since it holds per-level state, it should NOT be a singleton. Provisional: child of the Level scene root.                                                                | Medium   | Lead Programmer + Scene Architecture review | Provisional: scene child |

---

## CoverageVisualizer Implementation Spec

`CoverageVisualizer` is a visual-only sibling node in the gameplay scene that subscribes to
Coverage Tracking's signals and updates tile appearance. It contains **no game logic**.

### Node Type

`TileMapLayer` (preferred) or `Node2D` with a texture array — implementation choice made
at the first art sprint. The interface is the same either way.

### Responsibilities

| Responsibility                            | Owned By              |
| ----------------------------------------- | --------------------- |
| Rendering covered / uncovered tile states | CoverageVisualizer ✅ |
| Handling undo visual rollback             | CoverageVisualizer ✅ |
| Pre-covering the starting tile on spawn   | CoverageVisualizer ✅ |
| Coverage game-state tracking              | Coverage Tracking ✗   |
| Tile grid dimensions                      | Grid System ✗         |

### Interface

```gdscript
## Called by Level Coordinator; pre-allocates visual state for the level grid
func initialize_level(grid_width: int, grid_height: int) -> void

## Wired to CoverageTracking.tile_covered by Level Coordinator
func _on_tile_covered(coord: Vector2i) -> void

## Wired to CoverageTracking.tile_uncovered by Level Coordinator
func _on_tile_uncovered(coord: Vector2i) -> void

## Wired to SlidingMovement.spawn_position_set by Level Coordinator
func _on_spawn_position_set(pos: Vector2i) -> void
```

### Behaviour Rules

1. `initialize_level()`: sets all tiles to uncovered visual state with no animation.
2. `_on_tile_covered(coord)`: transitions tile to covered state. In the current home-room
   implementation this uses the active room's trail tile (`visited_paw` where available,
   falling back to `visited`); when `Simple UI` is on it falls back to
   `assets/art/tiles/grids/grid_yellow.png`.
3. `_on_tile_uncovered(coord)`: transitions tile to uncovered state. Called when Undo
   triggers `restore_coverage_snapshot()`. Instant at MVP.
4. `_on_spawn_position_set(pos)`: marks starting tile as covered immediately (no animation)
   to match Coverage Tracking's pre-covered initial state.
5. CoverageVisualizer **never** emits signals that affect game state.
6. CoverageVisualizer maintains its own visual-state array (not a reference to
   `coverage_map`). It is driven entirely by signals.
