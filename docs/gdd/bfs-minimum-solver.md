# BFS Minimum Solver

> **Status**: Approved
> **Author**: Grace + GitHub Copilot
> **Last Updated**: 2026-03-31
> **Implements Pillar**: Pillar 2 — Always Know How Close to Perfect You Are

## Overview

The BFS Minimum Solver is an offline Godot **editor tool** — not a runtime game system — that computes the minimum number of moves required to solve any given NekoDash level. It performs a breadth-first search over the complete puzzle state space (cat position × tile coverage), finds the shortest path from the initial state to full coverage, and writes the result as `minimum_moves: int` into the `LevelData` resource file. Because BFS guarantees that the first solution found is optimal, the result is mathematically exact. This value then drives the Move Counter HUD display ("Target: N moves") and the Star Rating System's 3-star threshold. Every shipped level must have `minimum_moves > 0`; a level whose solver returns `-1` (no solution) must not ship. The solver runs on developer machines as part of level authoring and optionally as a CI validation step — never on player devices.

## Player Fantasy

The BFS Minimum Solver has no direct player fantasy — the player never sees the algorithm. Its emotional contribution is the **honesty of the challenge**: when the HUD says "Target: 8 moves," that number is exact and trustworthy. A player who achieves the minimum knows they played perfectly. This directly serves **Pillar 2 — Always Know How Close to Perfect You Are**: if the minimum were guessed, approximated, or wrong, the entire scoring system breaks down. The solver is the invisible guarantee that the displayed target is achievable and that 3-star play means genuine mastery, not luck. Without it, NekoDash's central tension — "can I do it in exactly N moves?" — collapses.

## Detailed Design

### Core Rules

1. The BFS Minimum Solver is implemented as a **Godot editor plugin** (`@tool` script) exposed via the Editor > Tools menu as "Solve All Levels". It can also be run headless from the command line: `godot --headless --script tools/solve_levels.gd`.
2. The solver operates on `LevelData` resources. It loads each `.tres` file from `data/levels/`, runs BFS, and writes `minimum_moves` back using `ResourceSaver.save()`.
3. **State representation**: A BFS state is the pair `(cat_position: Vector2i, covered_mask: int)`. `covered_mask` is a bitmask where bit `i` is set when walkable tile `i` has been visited. The `move_count` is implicit in BFS depth.
4. **Tile indexing**: Before BFS, all WALKABLE tiles are enumerated in row-major order (`col + row * grid_width`) and assigned bit indices 0 through `N-1`. A `pos_to_index: Dictionary` and `index_to_pos: Array[Vector2i]` are built once per level to translate between `Vector2i` and bitmask positions.
5. **Bitmask constraint**: The bitmask uses GDScript's native `int` (64-bit signed). Bit 63 may cause sign issues, so the effective limit is **≤ 63 walkable tiles**. Levels exceeding this limit abort with an error. See Tuning Knobs for the recommended practical limit (35 tiles).
6. **Initial state**: `cat_position = cat_start`, `covered_mask = 1 << index_of(cat_start)` (the starting tile is already covered before any move).
7. **Goal state**: `covered_mask == (1 << N) - 1` — all N walkable tiles covered.
8. **BFS queue**: Standard FIFO. Each state is only enqueued once (visited set is checked before enqueuing). BFS guarantees the first solution found is the minimum-move solution.
9. **Slide resolution**: The cat slides in a direction until the next tile in that direction is BLOCKING or out of bounds. All tiles traversed during a slide — including the landing tile — are marked covered. A slide that does not move the cat (immediate wall) is discarded and not enqueued.
10. **Result**: If the goal state is reached, `minimum_moves = state.move_count` is written to the resource file. If the queue empties without reaching the goal, the level is unsolvable; an error is logged and `minimum_moves` is left at 0 (or set to -1 to flag the problem — see Open Questions).
11. The solver also validates `star_3_moves == minimum_moves` and logs a warning if the level file has a different value.

### State Space and Performance Limits

| Walkable Tiles (N) | Theoretical State Bound | Practical Solve Time (dev machine) |
| ------------------ | ----------------------- | ---------------------------------- |
| ≤ 15               | \~1M states             | < 1 second ✅                      |
| 16–25              | \~800M states           | 1–5 seconds ✅                     |
| 26–35              | \~44B states            | 5–60 seconds ⚠️                    |
| > 35               | Intractable             | ❌ Abort                           |

In practice, BFS explores far fewer states than the theoretical bound because: a) the cat can only stop at walls, not arbitrary tiles; b) coverage is monotonically increasing (no backtracking on progress); c) sliding puzzles have strong connectivity constraints.

**Level design budget recommendation**: target 12–28 walkable tiles per MVP level.

### States and Transitions

The BFS Minimum Solver has no runtime game states — it is a tool that runs to completion. The relevant lifecycle is:

| Phase          | Description                                                                                                             |
| -------------- | ----------------------------------------------------------------------------------------------------------------------- |
| **Initialize** | Load `LevelData`, build tile index, create initial BFS state, populate visited set                                      |
| **Expand**     | Dequeue front state; for each of 4 directions: compute slide landing, mark tiles covered, check visited, enqueue if new |
| **Goal Check** | On dequeue: if `covered_mask == goal_mask`, return `move_count`                                                         |
| **Exhausted**  | Queue empty without solution → level unsolvable, return -1                                                              |
| **Write**      | Set `level_data.minimum_moves`, call `ResourceSaver.save()`                                                             |

### Interactions with Other Systems

| System                 | Direction                    | Interface                                                                                                                                                                                              |
| ---------------------- | ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Level Data Format**  | Solver reads + writes        | Reads `grid_width`, `grid_height`, `walkability_tiles`, `cat_start`; writes `minimum_moves` back via `ResourceSaver.save()`                                                                            |
| **Grid System**        | Solver reads (via LevelData) | Does not call Grid System's runtime API; reimplements `is_walkable()` locally for offline use. Grid System's `Vector2i(col,row)` coordinate convention and out-of-bounds = BLOCKING rule are respected |
| **Move Counter**       | Indirect (runtime)           | Reads `minimum_moves` from the baked `.tres` file at game runtime — no direct solver call                                                                                                              |
| **Star Rating System** | Indirect (runtime)           | Reads `star_3_moves` which should equal `minimum_moves` — solver validates this at write time                                                                                                          |

## Formulas

### Slide Resolution

```
func slide(start: Vector2i, direction: Vector2i) -> Vector2i:
    pos = start
    loop:
        next = pos + direction
        if not is_walkable(next):    # BLOCKING or out-of-bounds
            return pos
        pos = next
```

| Variable     | Type       | Description                                                     |
| ------------ | ---------- | --------------------------------------------------------------- |
| `start`      | `Vector2i` | Cat's current position before the slide                         |
| `direction`  | `Vector2i` | One of: `(0,-1)` up, `(0,1)` down, `(-1,0)` left, `(1,0)` right |
| `next`       | `Vector2i` | Candidate next position each step                               |
| return value | `Vector2i` | Landing position; equals `start` if nothing to slide onto       |

Out-of-bounds always returns BLOCKING per Grid System convention — no explicit bounds check needed.

### Coverage Mask Update (per slide)

```
new_mask = current_mask
step = start + direction
while step != landing + direction:    # walk from (start + dir) to landing inclusive
    if step in pos_to_index:
        new_mask |= (1 << pos_to_index[step])
    step += direction
```

All tiles traversed from the first tile after `start` up to and including `landing` have their bits set.

### Tile Index Formula

```
bit_index = enumeration_order(col, row)   # row-major: lower row first, lower col first
```

Built at solver initialization by iterating `row in range(height)` then `col in range(width)` and assigning sequential indices to all WALKABLE tiles. Matches Level Data Format row-major convention.

### Goal Mask

```
goal_mask = (1 << N) - 1    # All N bits set
```

`N` = total walkable tile count for this level. The BFS terminates when `state.covered_mask == goal_mask`.

### State Hash Key

```
hash_key = "%d,%d|%d" % [position.x, position.y, covered_mask]
```

Used as Dictionary key for the visited set. String keys are acceptable for an offline tool; GDScript's Dictionary handles this without collision.

## Edge Cases

| Scenario                                                   | Expected Behavior                                                                                                | Rationale                                                                                                              |
| ---------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| Level is unsolvable (isolated tile unreachable by sliding) | BFS exhausts queue; solver returns -1; logs error with level path; `minimum_moves` stays 0                       | Level design error — must not ship; caught at authoring time                                                           |
| Level with 0 WALKABLE tiles                                | Solver aborts immediately with error; `minimum_moves` stays 0                                                    | Same malformed-level guard as Level Data Format                                                                        |
| Level with 1 WALKABLE tile (trivial)                       | Initial state is already the goal; `minimum_moves = 0`                                                           | Valid (though silly); 0-move levels are allowed by format but disallowed by level design guidelines (see Tuning Knobs) |
| Slide in a direction hits a wall immediately (no movement) | That direction produces no successor state; skipped                                                              | Prevents the same-position state from polluting the queue                                                              |
| `N > 63` walkable tiles                                    | Solver aborts with error: "Level has N walkable tiles (max 63 for bitmask)"                                      | GDScript `int` sign-safety limit; larger levels need a different coverage representation (see Open Questions)          |
| `cat_start` tile not WALKABLE                              | Solver uses fallback start position (first WALKABLE tile in row-major order); same fallback as Level Data Format | Consistent error handling                                                                                              |
| Two `.tres` files with the same `level_id`                 | Solver processes both independently; each is saved separately                                                    | Level ID uniqueness is an authoring concern, not a solver concern                                                      |
| State space too large (times out)                          | Solver logs a warning at 1M states explored with current depth; continues. No hard timeout for offline use.      | Developer should redesign the level to reduce walkable tile count                                                      |
| Level already has correct `minimum_moves`                  | Solver still runs and overwrites — result should be identical                                                    | Deterministic; re-running is safe. Avoids stale values from level edits                                                |

## Dependencies

| System                | Direction                           | Nature                                                                                                                                                                                                   | Hard/Soft                                                                       |
| --------------------- | ----------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| **Level Data Format** | Solver reads + writes LevelData     | Loads `.tres` via `ResourceLoader`; reads `grid_width`, `grid_height`, `walkability_tiles`, `cat_start`; writes `minimum_moves` via `ResourceSaver`                                                      | **Hard** — solver cannot function without the level file schema                 |
| **Grid System**       | Solver references (convention only) | Respects Grid System's `Vector2i(col,row)` coordinate convention and out-of-bounds = BLOCKING rule. Does _not_ call the runtime `GridSystem` node — reimplements `is_walkable()` locally for offline use | **Soft** (runtime) — the convention must match, but no runtime API call is made |

## Tuning Knobs

The BFS algorithm has no runtime tuning. The following design-time guidelines control solver performance and level authoring:

| Parameter                                 | Recommended Value | Hard Limit   | Rationale                                                          |
| ----------------------------------------- | ----------------- | ------------ | ------------------------------------------------------------------ |
| Max walkable tiles per level              | 28                | 35           | Above 35, solve time exceeds 60 seconds on a modern dev machine    |
| Min walkable tiles per level              | 8                 | 1            | Below 8, puzzles are trivially simple; 1-tile edge case is allowed |
| Min `minimum_moves` for any shipped level | 3                 | —            | Fewer than 3 moves is not a meaningful puzzle                      |
| Target solve time per level               | < 5 seconds       | < 60 seconds | Authoring comfort; > 60s should trigger a level redesign           |

_These are guidelines checked at authoring time, not enforced by the solver. The solver runs regardless and logs warnings._

## Visual/Audio Requirements

None. The solver is a developer tool with no visual or audio output. Its only output is the updated `minimum_moves` field in `.tres` files and terminal/editor log messages.

Terminal output format (per level):

```
[LevelSolver] w1_l1: minimum_moves = 8 (solved in 0.3s, 14K states explored)
[LevelSolver] w1_l2: minimum_moves = 12 (solved in 1.1s, 320K states explored)
[LevelSolver] ERROR: w1_l3 is unsolvable!
```

## UI Requirements

The solver surfaces to developers through the Godot Editor menu:

- **Editor > Tools > Solve All Levels** — batch-solves all `.tres` files in `data/levels/`
- **Editor > Tools > Solve Current Level** — solves only the currently selected `.tres` resource (stretch goal)

No in-game UI. The player-visible output (`minimum_moves`) is displayed by the Move Counter HUD, not the solver itself.

## Acceptance Criteria

| #    | Criterion                                                                                                                                                              |
| ---- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AC-1 | Running "Solve All Levels" on the MVP level set produces a `minimum_moves > 0` for every level, logged to the editor console.                                          |
| AC-2 | For a hand-verified 3×3 test level where the minimum is known to be 4 moves, the solver returns exactly 4.                                                             |
| AC-3 | A level with an isolated unreachable tile returns -1 and logs an error — it does not crash.                                                                            |
| AC-4 | Running the solver twice on the same level produces the same `minimum_moves` value (deterministic).                                                                    |
| AC-5 | A level with `N ≤ 28` walkable tiles completes in < 5 seconds on a developer machine.                                                                                  |
| AC-6 | A level with `N > 63` walkable tiles logs an error and does not attempt to run BFS.                                                                                    |
| AC-7 | After running the solver, `ResourceSaver.save()` successfully updates the `.tres` file; loading the file in a fresh Godot session shows the new `minimum_moves` value. |
| AC-8 | The solver logs a warning if `level_data.star_3_moves != minimum_moves` after solving.                                                                                 |
| AC-9 | "Solve All Levels" processes all MVP levels without crashing the Godot editor.                                                                                         |

## Open Questions

| #    | Question                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | Priority        | Owner                                                                                                                                           |
| ---- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| OQ-1 | Should unsolvable levels set `minimum_moves = -1` (explicit sentinel) or leave it as 0 (same as "not yet solved")? -1 makes the error state distinguishable but requires Level Data Format to allow negative values.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | Medium          | Resolve before first level authoring sprint                                                                                                     |
| OQ-2 | Should levels with N > 35 walkable tiles use an A\* heuristic search instead of pure BFS, or should the level design guideline simply prevent this case?                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | Medium          | Resolve if any late-game levels need > 35 tiles                                                                                                 |
| OQ-3 | Should the solver also validate that `minimum_moves >= 3` per level (design quality check) and refuse to save if below threshold?                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    | Low             | Resolve during first QA pass                                                                                                                    |
| OQ-4 | Should the solver run automatically as a CI step (e.g., via `godot --headless`) to catch unsolvable levels on every commit?                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | Medium          | Resolve during DevOps setup                                                                                                                     |
| OQ-5 | **Post-jam: procedural level generation compatibility.** If levels are generated at runtime, the BFS solver can no longer be an offline editor tool — it must run in-engine. This requires: **(a)** The solver becomes a GDScript class instantiated at runtime (not an EditorScript); **(b)** `LevelData` objects are generated in memory instead of loaded from `.tres` files — Level Progression, World Map, and LevelCatalogue must support `LevelData` instances without `res://` paths; **(c)** The solver's 63-tile bitmask limit (OQ-2) becomes a hard constraint on procedural grid sizes; **(d)** A PCG algorithm must guarantee solvability before handing a level to the solver (or accept retry-until-solvable). The current editor-tool architecture is incompatible with runtime PCG without significant refactoring. | High (Post-jam) | Design a "Procedural Level Generator" system GDD in Full Vision that specifies output format compatible with the existing `LevelData` contract. |
