# Pushable Block (Sokoban-Style) - Analysis

## 1. Technical Implementation
- **Slide resolver change:** Significant change. `resolve_slide()` needs to handle collisions not just by stopping the cat, but by evaluating if the collided object is `PUSHABLE`. If it is, the resolver must recursively or sequentially calculate a second slide for the block in the same direction, and then stop the cat at the block's original tile.
- **Grid System tile type:** Requires a new entity type, likely a `MOVABLE_OBSTACLE` node that interacts with the `GridSystem` to update its blocking status dynamically as it moves.
- **New node/system required:** A `PushableManager` or extensions to the `ObstacleSystem` to handle blocks that can slide, tracking their coordinates and updating the grid state.
- **Signal contract changes:** Need new signals: `block_push_started` and `block_slide_completed` to sequence animations properly (cat hits block -> block slides -> cat stops).
- **Hard vs. soft dependency:** Hard dependency on `SlidingMovement` and `GridSystem` as it fundamentally changes how collisions are resolved.

## 2. Level Solvability & BFS Impact
- **State space expansion:** Massive. The BFS state tuple must now include the coordinates of every pushable block in the level `(cat_pos, covered_tiles, {block1_pos, block2_pos, ...})`.
- **State count multiplier:** Exponential. Every block adds `N` possible positions (where N is the grid size), multiplying the state space.
- **BFS tractability threshold:** Highly likely to break the 15-second tractability limit if more than 1 or 2 blocks are used in a single level, due to the combinatorial explosion of block positions and cat paths.
- **Solver reuse:** The `slide()` reference function must be rewritten to simulate block pushing and grid updating during the BFS search.
- **Per-level re-verification cost:** Very high. Changes to levels with blocks will require significantly more time to re-solve and verify.

## 3. Level Design Impact
- **Design space opened:** Huge. Dynamic routing, puzzle "phases" (before and after pushing), and multi-step setup puzzles.
- **Design space closed:** Pure static logic. It shifts the game slightly towards a Sokoban hybrid.
- **Placement rule compatibility:** Changes the edge-row/column rules, as players can create their own stopping points in the middle of open space.
- **Incremental wall-addition workflow:** Complicated. Moving a block changes the routing for the rest of the puzzle dynamically.
- **Difficulty scaling:** High skill ceiling. Early levels can use a single block to block a hazard or bridge a gap. Late levels can involve complex block routing.

## 4. Game Design & Player Experience
- **Pillar 1 — Every Move Is a Choice:** Fully supported. The player can accurately predict where the block will slide and where they will end up.
- **Pillar 2 — Joyful at Every Moment:** Highly satisfying. Pushing a heavy object feels tactile and rewarding.
- **Pillar 3 — Complete Your Own Way:** Enhances this pillar by allowing players to literally build their own stopping points and routes.
- **Cognitive load:** Medium-High. Players must plan multiple steps ahead, anticipating the block's final position and how it affects future slides.
- **First-encounter teachability:** Easy. "Cat hits box, box slides" is intuitive.
- **Frustration vs. challenge balance:** Can lean into challenge if multiple blocks are involved, as getting a block stuck against a wall in the wrong spot can soft-lock the puzzle.

## 5. Audio & Visual Feedback
- **Unique SFX requirement:** Needs a distinct "heavy scrape" or "thud" sound for the block sliding, different from the cat's slide.
- **Animation requirement:** Sequential animation (cat slide -> cat bump -> block slide).
- **Visual legibility on mobile:** Good, as long as blocks are visually distinct from static walls (e.g., cardboard boxes vs. concrete walls).
- **Thematic fit:** Excellent. Cats pushing boxes around is a core cat behavior.
- **Haptic opportunity:** A heavy "thump" haptic when the block hits its final destination.

## 6. Undo / Restart Compatibility
- **Snapshot delta:** Requires adding the array of all `pushable_block_positions` to the `MoveSnapshot` struct.
- **Undo atomicity:** Complex. The undo action must reverse both the cat's position and the block's position simultaneously to be atomic.
- **Restart idempotency:** Idempotent, provided blocks are reset to their initial coordinates.
- **Signal connection order:** The `UndoSystem` must ensure it updates the `GridSystem` with the reverted block positions before the cat is allowed to move again.

## 7. Save / Persistence
- **New persisted fields:** None.
- **Mid-level transient state:** None.
- **Best-moves record validity:** Valid, but any changes to block mechanics could invalidate old records.

## 8. Star Rating & Move Economy
- **Move count inflation:** Moderate. Pushing blocks often requires setup moves, inflating the minimum move count for the level.
- **BFS minimum recalculation:** Required and potentially expensive.
- **Skill expression ceiling:** Very high. Optimizing routes with blocks is a classic puzzle optimization problem.
- **Star threshold formula compatibility:** Should remain compatible, though minimum moves may be higher.

## 9. Mobile UX
- **Touch interaction model:** Standard swipe. No new UI needed.
- **Screen real estate:** No new UI.
- **Tap state / active feedback:** Visual movement of the block provides feedback.
- **Accessibility:** Good. Relies on logic, not timing.

## 10. World Fit & Narrative Coherence
- **Thematic grounding:** Very strong. Cardboard boxes, toy chests, or heavy food bowls.
- **World assignment:** World 2 or 3, as it introduces a significant complexity bump.
- **Skin / cosmetic interaction:** Different block types per world (e.g., Box in World 1, Suitcase in World 2).

## 11. Post-MVP Scope Risk
- **GDD amendment surface:** High. Requires updates to `GridSystem`, `SlidingMovement`, `Undo/Restart`, and the `BFS Solver`.
- **Combinatorial interaction risk:** High. How do blocks interact with hazards? Conveyor belts? Warp tiles? Each interaction needs explicit handling.
- **Reversibility:** Medium. It integrates deeply into the solver and snapshot systems, making it tricky to extract cleanly.
- **Prototype validation requirement:** **Mandatory**, particularly to test the BFS tractability threshold before committing to level design.
