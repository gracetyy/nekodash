# New Mechanic Ideas

## 1. 📦 Moving Obstacle (Periodic Patrol)

A furniture piece slides back and forth along a straight line on a fixed timer, independent of player input. When it moves, it updates the Grid System's walkability in real time — tiles it occupies become temporarily blocked. The cat cannot pass through its current position mid-slide, forcing the player to time their moves around the patrol cycle.

## 2. ☠️ Kill Tile (Hazard Floor)

A tile that instantly kills the cat upon contact during a slide. It looks walkable but triggers a death event the moment the cat traverses it, restarting the level. Visually it could be a wet floor puddle, a sparking socket, or a broken glass shard — each fitting a different world theme. The cat cannot survive crossing it under any condition.

## 3. 📦 Pushable Block (Sokoban-Style)

When the cat slides into a pushable block, instead of stopping, the cat pushes the block — the block then slides in the same direction until _it_ hits a wall or obstacle. The cat stops at the block's original position. The block becomes a permanent new obstacle at its landing spot, reshaping all future slide paths in that row or column.

## 4. 🏺 Fallable Item (Knock-Off)

A decorative item sits on top of a piece of furniture. When the cat bumps the furniture from a specific side, the item topples off the opposite edge and lands on the floor as a new permanent obstacle. The item's landing position is calculated like a mini-slide — it travels in the knock direction until hitting the nearest wall or existing obstacle.

## 5. 🗝️ Door + Key (Conditional Unlock)

A key sits on a specific tile; a locked door blocks a passage elsewhere on the grid. The cat picks up the key automatically by sliding over it. Once the key is collected, the door tile switches from `BLOCKING` to `WALKABLE`, opening a new route. The door remains impassable until the key tile is covered, enforcing a soft visit order.

## 6. 🛑 Stop-Slide Tile (Mid-Slide Checkpoint)

A special floor tile that interrupts the cat's slide early, even when the path ahead is clear. The cat pauses here and transitions back to `IDLE`, waiting for the next player input. It functions as an invisible mid-air stopping point — visually a yarn ball, a catnip patch, or a soft rug that the cat can't resist pausing on.

## 7. 🔁 Conveyor Belt (Forced Extra Slide)

A row or column of tiles acts as a conveyor. When the cat lands on a conveyor tile, it is automatically pushed one further step in the conveyor's direction (if that tile is walkable) without spending a move. Chaining multiple conveyor tiles creates a "free" multi-step carry. Landing at the end of the conveyor against a wall costs zero moves but covers extra tiles.

## 8. 🎯 Required Target Tile (Order-Sensitive Goal)

Instead of covering _all_ tiles freely, some tiles are numbered — the cat must cover them in sequence (1 → 2 → 3). Reaching tile #2 before tile #1 counts as a visit but doesn't mark it as completed until the sequence is respected. This transforms the coverage goal from "visit everything" into a constrained ordering problem.

## 9. 🪤 Trap Tile (Delayed Effect)

A tile that _appears_ walkable and is covered normally, but triggers an effect on the _next_ move after the cat leaves it — for example, spawning a temporary wall behind the cat, cutting off the path it just came from. The trap is indicated by a subtle visual marker (a glint or color shift) so the player can plan around it.

## 10. 👥 Two-Cat Co-op Tile (Echo Mechanic)

A special level variant where a second "ghost cat" starts at a mirrored position. Every input the player makes moves _both_ cats simultaneously in the same direction — like a co-op sliding puzzle. Both cats must together cover all tiles. The ghost cat obeys all the same wall-stop rules but stops independently based on its own obstacles. Only available in select bonus levels.

## 11. 🪞 Mirror / Warp Tile (Teleporter)

Stepping onto a warp tile instantly teleports the cat to a paired exit tile on the other side of the grid. The cat arrives with its momentum cancelled — it stops at the exit tile regardless of direction, and the player must choose the next move from there. Pairs are visually linked with a matching color or symbol.

## 12. 🔄 Rotating Obstacle

A furniture piece (e.g., a spinning rack or lazy susan) occupies a 1×2 or 2×1 footprint and rotates 90° every time the cat bumps into it. The rotation changes which tiles it blocks, opening and closing routes each bump. It never moves position — only its orientation flips.

## 13. 🪟 One-Way Tile (Directional Permeable Wall)

A tile that only allows the cat to pass through from one specific direction. Approaching from the allowed direction, it acts as a normal walkable tile. Approaching from any other direction, it acts as a wall. Visually it looks like a half-open door or a slat that only lets the cat slide "into" the room.

## 14. 💤 Sleep Tile (Timed Forced Pause)

When the cat lands on a sleep tile, it takes a short involuntary nap (1-2 "turns"). The player must input two consecutive moves to "wake" the cat — the first input is consumed waking it up, and the second is the actual move. It essentially costs one extra move, adding pressure to the move budget and star rating.

## 15. 🧲 Magnet Tile (Pull)

When the cat enters the same row or column as a magnet tile, the cat is _pulled_ toward it on that axis before the player can input the next move. The pull resolves like a regular slide — the cat slides to the magnet tile and stops. The next player input then proceeds normally. The magnet tile itself is a permanent fixture.

## 16. 🪨 Crumble Tile (One-Time Walkable)

A fragile tile (cracked floor, thin ice, a paper mat) that collapses after the cat slides over it the first time. On the first pass it's walkable and counts as covered. After that, it becomes a permanent wall. Future slides in that row/column now stop one tile earlier, changing the routing for the rest of the puzzle.

## 17. 🐾 Split Map (Shared Control Co-op)

    Two entirely separate grid maps are displayed side by side on screen, each with its own cat starting at its own position. Every input the player makes moves both cats simultaneously in the same direction — one swipe slides both cats at once, each obeying their own grid's wall-stop rules independently. The objective is to cover all tiles across both maps before the move counter runs out, meaning the player must mentally solve two sliding puzzles in parallel with a single shared move budget. Tile coverage on either map counts toward the combined completion goal, but the level only completes when every walkable tile across both grids has been visited.

---

## Quick Glance Comparison

| #   | Idea              | Core Hook                                               | Puzzle Type Shift           |
| --- | ----------------- | ------------------------------------------------------- | --------------------------- |
| 1   | Moving Obstacle   | Real-time patrol cycle                                  | Timing & patience           |
| 2   | Kill Tile         | Instant death on contact                                | Risk avoidance routing      |
| 3   | Pushable Block    | Push reshapes the grid                                  | Dynamic obstacle placement  |
| 4   | Fallable Item     | Bump spawns new obstacle                                | Directional consequence     |
| 5   | Door + Key        | Collect to unlock route                                 | Ordered objective           |
| 6   | Stop-Slide Tile   | Force-stop mid open space                               | New stopping geometry       |
| 7   | Conveyor Belt     | Free extra slide                                        | Chain reactions             |
| 8   | Required Target   | Numbered visit order                                    | Sequence constraint         |
| 9   | Trap Tile         | Delayed wall spawn                                      | Anticipation planning       |
| 10  | Two-Cat Echo      | Mirrored dual control                                   | Cooperative coverage        |
| 11  | Warp Tile         | Teleport with momentum reset                            | Spatial jumps               |
| 12  | Rotating Obstacle | Bump changes blocker shape                              | Dynamic routing             |
| 13  | One-Way Tile      | Directional permeability                                | Asymmetric paths            |
| 14  | Sleep Tile        | Wastes one input                                        | Move budget pressure        |
| 15  | Magnet Tile       | Involuntary pull                                        | Forced detour               |
| 16  | Crumble Tile      | First pass = permanent wall                             | Destruction ordering        |
| 17  | Split Map         | One input controls two cats on two grids simultaneously | Parallel dual-board solving |
