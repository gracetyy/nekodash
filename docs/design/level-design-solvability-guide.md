# Level Design Solvability Guide

> **Purpose**: Systematic approach for agents and designers to create solvable
> NekoDash levels without manual trial-and-error.
>
> **Audience**: Any agent or contributor authoring levels.
>
> **Last Updated**: 2026-03-31
> **Source**: Lessons from `prototypes/sliding-movement/` + `design/gdd/bfs-minimum-solver.md`

---

## 1. The Problem

NekoDash levels are sliding puzzles: the cat slides in a cardinal direction until
hitting a wall or grid boundary, and the player must cover every walkable tile.
Not every wall placement produces a solvable level. The first prototype grid —
a 7×7 with 4 interior walls at `(3,2), (2,4), (4,4), (3,5)` — was **unsolvable**
because the wall layout created tile pockets that could be entered but not exited
in a way that allowed full coverage. This was only discovered after manual testing.

This document provides algorithmic tools to **verify solvability before testing**
and heuristic rules to **design solvable levels from the start**.

---

## 2. Formal Definition

A NekoDash level is **solvable** if there exists a sequence of cardinal direction
inputs such that the cat, starting at `cat_start`, visits every walkable tile at
least once (100% coverage).

### State Space Model

```
State = (position: Vector2i, covered: Set[Vector2i])
```

- **Initial state**: `(cat_start, {cat_start})`
- **Transition**: For each direction `d` in `{UP, DOWN, LEFT, RIGHT}`:
  - Compute `landing = slide(position, d)` — the cat slides until blocked
  - If `landing == position`: no transition (blocked immediately)
  - Otherwise: `tiles_traversed` = all tiles from `position + d` to `landing` inclusive
  - New state: `(landing, covered ∪ tiles_traversed)`
- **Goal**: `covered == all_walkable_tiles`

A level is solvable iff BFS/DFS over this state space reaches the goal state.

---

## 3. The BFS Solvability Algorithm

This is the definitive check. If BFS says unsolvable, the level **cannot ship**.

### Algorithm (pseudocode)

```
func is_solvable(grid, cat_start, walkable_tiles) -> {solvable: bool, min_moves: int}:
    # Represent coverage as a bitmask for efficiency
    N = len(walkable_tiles)
    assert N <= 63  # GDScript int limit

    # Build tile-to-bit-index mapping (row-major order)
    tile_to_bit = {}
    for i, tile in enumerate(sorted(walkable_tiles, key=row_major)):
        tile_to_bit[tile] = i

    goal_mask = (1 << N) - 1
    initial_mask = 1 << tile_to_bit[cat_start]
    initial_state = (cat_start, initial_mask)

    queue = deque([initial_state])
    visited = {state_hash(initial_state): 0}  # state -> depth

    while queue:
        pos, covered = queue.popleft()
        depth = visited[state_hash(pos, covered)]

        if covered == goal_mask:
            return {solvable: true, min_moves: depth}

        for direction in [UP, DOWN, LEFT, RIGHT]:
            landing = slide(pos, direction, grid)
            if landing == pos:
                continue

            new_covered = covered
            step = pos + direction
            while step != landing + direction:
                if step in tile_to_bit:
                    new_covered |= (1 << tile_to_bit[step])
                step += direction

            key = state_hash(landing, new_covered)
            if key not in visited:
                visited[key] = depth + 1
                queue.append((landing, new_covered))

    return {solvable: false, min_moves: -1}
```

### Complexity

| Walkable Tiles | Worst-Case States | Practical Time |
| -------------- | ----------------- | -------------- |
| ≤ 15           | ~1M               | < 1 second     |
| 16–25          | ~800M             | 1–5 seconds    |
| 26–35          | ~44B              | 5–60 seconds   |
| > 35           | Intractable       | Do not attempt |

In practice, far fewer states are explored because: (a) the cat can only stop at
wall-adjacent positions, not arbitrary tiles; (b) coverage is monotonically
increasing; (c) many states are pruned by the visited set.

---

## 4. Quick Reject: Necessary Conditions (O(N) checks)

Before running the expensive BFS, apply these cheap filters to reject obviously
unsolvable layouts. All must pass; any failure means unsolvable.

### 4.1 Slide-Line Coverage Test

**Rule**: Every walkable tile must lie on at least one "slide line" — a straight
horizontal or vertical sequence of walkable tiles between two blocking surfaces
(walls or boundaries).

```
For each walkable tile T:
    reachable_by_slide = false
    for direction in [LEFT→RIGHT, UP→DOWN]:
        # Find the slide line containing T in this axis
        scan backward from T until wall/boundary → line_start
        scan forward from T until wall/boundary → line_end
        if line_start != line_end:  # at least 2 tiles in this line
            reachable_by_slide = true
            break
    if not reachable_by_slide:
        FAIL: tile T is isolated (single-tile pocket)
```

**Cost**: O(N × grid_dimension). Instant.

**What it catches**: Single-tile dead-end pockets completely surrounded by walls
on 3 sides with the 4th side being a wall-adjacent tile that the cat can't stop on.

**What it misses**: Tiles that are on slide lines but still unreachable due to
ordering constraints (the full BFS catches these).

### 4.2 Reachable Positions Test

**Rule**: Every possible "landing position" (position where the cat can stop)
must form a connected graph under the slide transition function. If the cat can
never reach certain landing positions, tiles near those positions are uncoverable.

```
# Build the slide-reachability graph (ignoring coverage)
landing_positions = set()
for each walkable tile T:
    for direction in [UP, DOWN, LEFT, RIGHT]:
        land = slide(T, direction)
        if land != T:
            landing_positions.add(land)

# BFS from cat_start over landing graph
reachable = bfs_over_landings(cat_start)

# Check: are all walkable tiles covered by at least one slide
# between two reachable landing positions?
for each walkable tile T:
    if T is not between any pair of reachable landings on the same axis:
        FAIL: tile T can never be traversed
```

**Cost**: O(N²) worst case. Very fast for levels under 35 tiles.

**What it catches**: Disconnected regions — groups of tiles the cat physically
cannot reach from the spawn point.

### 4.3 Parity / Symmetry Heuristic

This is a soft heuristic, not a hard rule. Levels with high wall symmetry around
the center tend to create mirrored dead zones where the cat must visit both sides
but can only exit through the center.

**Check**: If interior walls form a symmetric pattern (reflection or rotation),
manually verify the level or increase scrutiny with BFS.

---

## 5. Design Heuristics: How to Create Solvable Levels

These rules-of-thumb produce levels that are _likely_ solvable. Always confirm
with the BFS solver before shipping.

### 5.1 Start Simple, Add Walls Incrementally

```
1. Begin with an empty rectangular interior (all walkable, border walls only)
   → This is always trivially solvable
2. Add ONE interior wall
3. Run BFS to verify solvable
4. If solvable and interesting (min_moves > trivial): keep
5. If unsolvable: remove and try a different position
6. Repeat from step 2 until desired complexity
```

**Why**: Each wall addition is validated independently. You never have to debug
which of 4 simultaneous walls broke solvability.

### 5.2 Wall Placement Principles

| Principle                           | Explanation                                                                                                                                                           |
| ----------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Walls create stopping points**    | A wall's primary effect is giving the cat a place to land. Place walls where you want the cat to be able to stop mid-grid.                                            |
| **Avoid pocket traps**              | Never place walls that create a 1-tile alcove with only one entry direction — the cat can slide in but may not be able to traverse the tiles needed to exit.          |
| **Borders are free walls**          | The grid boundary already acts as walls on all 4 sides. Interior walls near borders are redundant for stopping (though they narrow corridors, which changes routing). |
| **Asymmetry aids solvability**      | Asymmetric wall placement creates more distinct slide paths, reducing the chance of dead-end coverage loops.                                                          |
| **L-shapes and T-shapes work well** | Wall configurations that block in one axis but leave the perpendicular axis open create routing "forks" that enable solution paths.                                   |
| **Avoid center bisection**          | A wall line that fully bisects the grid horizontally or vertically can make one half unreachable from the other.                                                      |

### 5.2.1 Final-Slot Validation Rule

When a level moves into its final slot, treat the file as new content.

- A copied layout still needs a fresh BFS pass in the destination file.
- If the copied layout becomes unsolvable in its new slot, replace it with another already-validated layout.
- The shipping file is the only authoritative source; do not trust the source slot once the move is made.

### 5.3 Spawn Position Selection

The spawn position determines which tiles are reachable first and which coverage
orderings are possible.

| Guideline                             | Rationale                                                                                                                                                                      |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Corners are strong spawns**         | From a corner the cat can only go 2 directions, which constrains the opening and makes the puzzle more tractable for the player.                                               |
| **Center spawns increase difficulty** | 4 possible opening directions = more decision branching. Good for harder levels.                                                                                               |
| **Spawn must be on a slide line**     | If the cat spawns at a position where all 4 directions are immediately blocked, the puzzle is unsolvable (0 valid moves). Always verify the spawn position has ≥1 valid slide. |

### 5.4 Difficulty Scaling via Grid Parameters

| Parameter            | Easy      | Medium    | Hard      |
| -------------------- | --------- | --------- | --------- |
| Grid size (interior) | 3×3 – 4×4 | 4×4 – 5×5 | 5×5 – 7×7 |
| Interior walls       | 0–1       | 2–3       | 3–6       |
| Walkable tiles       | 8–14      | 14–20     | 20–28     |
| Min moves (target)   | 3–6       | 7–12      | 13–25     |
| Spawn position       | Corner    | Edge      | Center    |

---

## 6. Worked Example: Building the Prototype Level

This is the actual process used to fix the unsolvable prototype grid.

### Failed Layout (Unsolvable)

```
7×7 grid, border walls, 4 interior walls:
  (3,2), (2,4), (4,4), (3,5)

 . . . . . . .       . = wall
 . _ _ _ _ _ .       _ = walkable
 . _ _ W _ _ .       W = interior wall
 . _ _ _ _ _ .       S = spawn (1,1)
 . _ W _ W _ .
 . _ _ W _ _ .
 . . . . . . .

Spawn: (1,1), Coverage max reached: 15/21
Problem: The wall at (3,2) blocks vertical slide paths through
column 3. Combined with walls at (2,4) and (4,4), tiles in the
bottom rows of columns 2 and 4 become part of a coverage trap —
the cat can enter but the exit slide always misses uncovered tiles.
```

### Fix Process

```
1. Removed all 4 interior walls → empty grid (trivially solvable, boring)
2. Added wall at (3,1) → solvable, creates a stop point in row 1
3. Added wall at (1,3) → solvable, creates vertical routing choice
4. Added wall at (4,5) → solvable, asymmetric — creates interesting
   bottom-right routing
5. BFS verification: solvable in 13 moves
   Solution path: R D R U L R D U L D L D R

Final layout (22 walkable tiles, 3 interior walls):
 . . . . . . .
 . _ _ W _ _ .       W at (3,1)
 . _ _ _ _ _ .
 . W _ _ _ _ .       W at (1,3)
 . _ _ _ _ _ .
 . _ _ _ W _ .       W at (4,5)
 . . . . . . .
```

### Why It Works

- **Wall at (3,1)**: Creates a stop at (2,1) coming from the right, and a stop
  at (4,1) coming from the left. Breaks the trivial "zigzag" pattern.
- **Wall at (1,3)**: Forces vertical routing through column 1 to split into
  above/below segments. The cat must approach from column 2+ to cover tiles
  below (1,3).
- **Wall at (4,5)**: Asymmetric with the other walls. Creates a pocket in the
  bottom-right that requires careful approach order.
- **Asymmetry**: No two walls share a row or column → no bisection, no mirrored
  dead zones.

---

## 7. Agent Workflow: Step-by-Step

When an agent needs to create a new level:

```
1. CHOOSE grid dimensions
   - World 1: 5×5 (3×3 interior)
   - World 2: 6×6 (4×4 interior)
   - World 3+: 7×7 (5×5 interior)

2. CHOOSE spawn position
   - Default: (1, 1) — top-left corner
   - Vary per level for diversity

3. PLACE walls incrementally
   - Start with 0 interior walls
   - Add one wall at a time
   - After each wall: run the BFS solvability check (section 3)
   - If unsolvable: undo last wall, try a different position
   - Target: 1-4 interior walls for MVP levels

4. VERIFY with BFS
   - Record minimum_moves
   - Reject if min_moves < 3 (too trivial)
   - Reject if min_moves > 25 (too hard for target difficulty)

5. SET star thresholds
   - star_3_moves = minimum_moves (exact)
   - star_2_moves = minimum_moves + ceil(minimum_moves * 0.5)
   - star_1_moves = minimum_moves + minimum_moves (2× minimum)

6. RECORD in LevelData .tres file
   - Grid dimensions, walkability, cat_start, minimum_moves, star thresholds
```

---

## 8. Common Unsolvable Patterns to Avoid

### Pattern 1: The Pocket Trap

```
_ W _        The tile marked X can be entered from the left
_ X W        but the cat slides past it vertically and cannot
_ _ _        stop on it without overshooting.
```

**Fix**: Remove one of the adjacent walls to create an exit path.

### Pattern 2: The Bisector

```
_ _ _ _ _
_ _ _ _ _
W W _ W W    Full horizontal bisection — top and bottom are
_ _ _ _ _    disconnected (cat can only cross at column 2)
_ _ _ _ _
```

**Fix**: Remove at least one wall from the bisecting line to create
a second crossing point.

### Pattern 3: The Corner Lock

```
_ _ _ .
_ W _ .      The tile at top-right corner can only be reached
_ _ W .      by sliding right from (1,0) or down from (3,0).
. . . .      But both walls block the exit paths needed to
             then cover remaining tiles.
```

**Fix**: Move one wall away from the corner to open a routing option.

### Pattern 4: Symmetric Mirrors

```
_ W _ W _
_ _ _ _ _     Mirror-symmetric walls create identical coverage
_ _ _ _ _     constraints on both sides. The cat must solve both
_ _ _ _ _     halves but often can't re-enter the second half
_ W _ W _     after completing the first.
```

**Fix**: Break symmetry. Move one wall to create asymmetric routing.

---

## 9. Reference: Slide Resolution Function

Every solvability check needs this function. Copy it exactly — it must match
the production `SlidingMovement.resolve_slide()` behavior.

```gdscript
func slide(start: Vector2i, direction: Vector2i, grid: Dictionary) -> Vector2i:
    var pos: Vector2i = start
    while true:
        var next: Vector2i = pos + direction
        if not grid.has(next) or not grid[next]:  # out-of-bounds or wall
            return pos
        pos = next
    return pos  # unreachable
```

`grid` is `Dictionary[Vector2i, bool]` where `true` = walkable, missing/`false` = wall.

---

## 10. Key Takeaways

1. **Never trust a hand-designed level without BFS verification.** The prototype
   proved that "looks solvable" ≠ solvable. Run the algorithm.
2. **Add walls one at a time and verify after each.** This is the only reliable
   manual workflow. Placing multiple walls at once multiplies the chance of
   creating unsolvable interactions.
3. **Asymmetry is your friend.** Symmetric wall placement is the #1 cause of
   unsolvable levels in NekoDash's sliding mechanic.
4. **Cheap filters first, BFS second.** The slide-line and reachable-positions
   checks (section 4) reject obviously broken layouts in microseconds, saving
   the full BFS for plausible candidates.
5. **The BFS solver is the source of truth.** It is both the solvability check
   and the minimum-moves calculator. Use it for both.
