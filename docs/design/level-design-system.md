# NekoDash Level Design System

## Core Mechanic Recap

The cat slides in one direction until hitting a wall or obstacle. The player must cover every walkable tile. This is a coverage puzzle, not a pathfinding puzzle.

## Design Principles

### 1. Open Space, Not Corridors

Every level is a **large rectangular room** with obstacles placed as **isolated pillar islands** inside it. The interior should be mostly walkable — obstacles are sparse (never more than ~15% of interior tiles).

**DO**: Big open room with 1–3 pillars scattered inside.
**DON'T**: Narrow corridors, S-curves, zigzag paths, maze-like layouts.

### 2. Edge-Row Obstacle Placement

Obstacles must be placed on **edge rows or columns of the interior** (the first/last walkable row or column). This ensures slides from corners directly hit the obstacle, creating usable stopping points.

In a 7×7 grid (5×5 interior, rows 1–5, cols 1–5):

- Edge rows: 1 and 5
- Edge cols: 1 and 5
- Good positions: (3,1), (1,3), (4,5), (5,2), etc.
- Bad positions: (3,3) — center has no corner slide path hitting it

Exception: In a 5×5 grid (3×3 interior), the center IS an edge position because the interior is only 3 tiles wide.

### 3. No Two Obstacles Share a Row or Column

Each obstacle must be on a **unique row AND unique column**. This forces the player to approach different obstacles from different directions and prevents redundant stopping points.

### 4. Asymmetric Placement

Avoid symmetric or regular patterns. Place obstacles in a loose triangle or scattered arrangement. Symmetry makes solutions obvious; asymmetry requires thought.

### 5. Cat Starts at (1,1)

The cat always starts at the top-left walkable tile. This is the convention across all levels.

## Difficulty Progression

Difficulty scales through two knobs:

| Knob           | Effect                                      |
| -------------- | ------------------------------------------- |
| Grid size      | More tiles to cover = more moves required   |
| Obstacle count | More stopping points = more route decisions |

### World 1 Progression

| Level | Grid | Interior | Obstacles | Target BFS |
| ----- | ---- | -------- | --------- | ---------- |
| L1    | 4×3  | 2×1      | 0         | 1          |
| L2    | 4×4  | 2×2      | 0         | 3          |
| L3    | 5×5  | 3×3      | 1         | 4–5        |
| L4    | 6×6  | 4×4      | 2         | 6–9        |
| L5    | 6×6  | 4×4      | 2         | 8–10       |
| L6    | 6×6  | 4×4      | 3         | 9–12       |
| L7    | 7×7  | 5×5      | 3         | 10–12      |
| L8    | 7×7  | 5×5      | 3         | 11–13      |

### Star Threshold Formula

For obstacle levels (L4+):

```
star_3_moves = minimum_moves + 1
star_2_moves = minimum_moves + floor(minimum_moves × 0.4)
star_1_moves = minimum_moves + floor(minimum_moves × 1.0)
```

For tutorial levels (L1–L3): `star_3_moves = minimum_moves` (perfect play = 3 stars). Star 2 and star 1 thresholds are hand-tuned.

## Reference: Prototype Level (Gold Standard)

The sliding-movement prototype (`prototypes/sliding-movement/proto_grid.gd`) defines the quality bar:

```
7×7 grid, 5×5 open interior, 3 obstacles, BFS = 12

# # # # # # #
# .  .  W  .  .  #    (3,1) — top edge row
# .  .  .  .  .  #
# W  .  .  .  .  #    (1,3) — left edge col
# .  .  .  .  .  #
# .  .  .  W  .  #    (4,5) — bottom edge row
# # # # # # #
```

Why this works:

- From (1,1) RIGHT → hits (3,1) → lands at (2,1) — opens top row access
- From (1,1) DOWN → hits (1,3) → lands at (1,2) — opens left column access
- From bottom-right, slides LEFT → hits (4,5) → creates bottom access
- Obstacles form a loose **triangle** across the space
- Each obstacle is on a different edge row/col — no overlap

## Verification Checklist

Before a level ships:

1. **BFS solvable** — run `tools/solve_all_levels.gd`, must show `[OK]`
2. **Open space feel** — interior is square-ish (aspect ≤ 1.5:1), mostly walkable
3. **No corridor shapes** — no interior dimension < 3 tiles
4. **Obstacle diversity** — no two obstacles share a row or column
5. **Difficulty fits curve** — BFS value fits the target range for its position
6. **Star thresholds set** — formula applied, star_2 has ≥ 2 moves of headroom above star_3

## Anti-Patterns

| Anti-Pattern                             | Why It Fails                                         |
| ---------------------------------------- | ---------------------------------------------------- |
| Corridor layout                          | Feels like walking a single road; no route decisions |
| Interior obstacles (not on edge row/col) | Unreachable — no slide from corner hits them         |
| Symmetric obstacle placement             | Solution is obvious; no thinking required            |
| Two obstacles on same row                | Redundant stopping axis; wastes design space         |
| Obstacle adjacent to border wall         | Obstacle is invisible — wall already stops there     |
| Too many obstacles (>15% of interior)    | Space feels cluttered, not open                      |
