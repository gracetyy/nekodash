# Fallable Item (Knock-Off) - Analysis

## 1. Technical Implementation
- **Slide resolver change:** Moderate change. `resolve_slide()` needs to detect a "side bump" on specific furniture items. If bumped from the correct axis, it triggers a secondary "mini-slide" for the item to resolve its landing position, while the cat stops normally.
- **Grid System tile type:** Requires a dynamic grid update. The landing tile transitions from `WALKABLE` to `BLOCKING` (or a new `OBSTACLE` state) mid-turn.
- **New node/system required:** An `ItemKnockSystem` or an extension to interactable furniture nodes that tracks the item's state (on table vs. on floor) and calculates its trajectory.
- **Signal contract changes:** Need `item_knocked` and `item_landed` signals to manage animations and grid updates sequentially.
- **Hard vs. soft dependency:** Soft dependency. The cat's core sliding logic remains mostly the same, it just triggers a side-effect on the grid upon collision.

## 2. Level Solvability & BFS Impact
- **State space expansion:** High. The BFS state tuple must track the state of each fallable item `(item1_fallen: bool, item2_fallen: bool)`. Since they only fall once and create a permanent obstacle, the state is binary per item, but the grid state changes based on it.
- **State count multiplier:** $2^N$ where N is the number of fallable items in the level. Better than pushable blocks, but still significant.
- **BFS tractability threshold:** Likely tractable if limited to 1-3 items per level, as the state space expansion is bounded compared to freely moving blocks.
- **Solver reuse:** The `slide()` reference function must be modified to simulate the item falling and updating the internal grid representation during the search.
- **Per-level re-verification cost:** Moderate. More expensive than static levels, but much less than Sokoban blocks.

## 3. Level Design Impact
- **Design space opened:** "Unlocking" new stopping points dynamically. Forces players to consider the *direction* of their approach to a wall, not just the collision itself.
- **Design space closed:** Static routing. Once the item falls, paths are permanently altered.
- **Placement rule compatibility:** Adds complexity. Designers must ensure the item's landing spot doesn't inadvertently soft-lock the level.
- **Incremental wall-addition workflow:** Manageable, but the designer must visualize the grid in both the "pre-fall" and "post-fall" states.
- **Difficulty scaling:** Good. Can be used as a mandatory step to reach an area, or as an optional "shortcut" creator.

## 4. Game Design & Player Experience
- **Pillar 1 — Every Move Is a Choice:** Supported. The player can see the item and the direction it will fall, allowing predictable planning.
- **Pillar 2 — Joyful at Every Moment:** Extremely high. Knocking things off tables is the quintessential cat experience. Highly satisfying visually and audibly.
- **Pillar 3 — Complete Your Own Way:** Gives agency to modify the puzzle geometry.
- **Cognitive load:** Medium. The player must think about the grid geometry before and after the action.
- **First-encounter teachability:** Very easy. A simple animation of the item teetering when approached can hint at the mechanic.
- **Frustration vs. challenge balance:** Can be frustrating if knocking the item creates an unsolvable state, forcing an undo. Needs careful level design to ensure falls are generally beneficial or neutral.

## 5. Audio & Visual Feedback
- **Unique SFX requirement:** Needs a "rattle/teeter" sound on approach, and a "smash/crash" sound on landing.
- **Animation requirement:** Teetering animation on the table, falling arc tween, and a shattered/landed state.
- **Visual legibility on mobile:** Good, though distinguishing between "table with item" and "empty table" must be clear.
- **Thematic fit:** Perfect. Unmatched thematic coherence for a cat game.
- **Haptic opportunity:** A sharp, satisfying "crack" haptic when the item hits the floor.

## 6. Undo / Restart Compatibility
- **Snapshot delta:** Requires adding the `(item1_fallen: bool, ...)` array to the `MoveSnapshot` struct.
- **Undo atomicity:** The undo action must revert the item from the floor back to the table and clear the grid block in a single step along with the cat's movement.
- **Restart idempotency:** Idempotent. Reset item states to `false`.
- **Signal connection order:** The `UndoSystem` must revert the item's grid blocking status before validating the next cat move.

## 7. Save / Persistence
- **New persisted fields:** None.
- **Mid-level transient state:** None.
- **Best-moves record validity:** Valid.

## 8. Star Rating & Move Economy
- **Move count inflation:** Low to moderate. Usually requires a specific setup move to approach the table from the correct angle.
- **BFS minimum recalculation:** Required, but manageable.
- **Skill expression ceiling:** High. Planning the optimal time to drop the item to reuse paths.
- **Star threshold formula compatibility:** Compatible.

## 9. Mobile UX
- **Touch interaction model:** Standard swipe.
- **Screen real estate:** No new UI.
- **Tap state / active feedback:** The falling animation provides excellent active feedback.
- **Accessibility:** Good. No timing required.

## 10. World Fit & Narrative Coherence
- **Thematic grounding:** Flawless. Vases, mugs, potted plants.
- **World assignment:** Can be introduced early (World 1 or 2) as a core feature of being a cat.
- **Skin / cosmetic interaction:** Different items to knock over (Glass vase, coffee mug, stack of books).

## 11. Post-MVP Scope Risk
- **GDD amendment surface:** Medium. Updates to `Undo/Restart`, `BFS Solver`, and `Level Data Format` (to define item fall direction).
- **Combinatorial interaction risk:** Medium. What happens if the item falls on a hazard? Or on a conveyor belt? (Usually, it should just become a static obstacle at its landing point).
- **Reversibility:** Medium. Easy to remove from levels, but requires stripping out the state tracking from the snapshot and solver systems.
- **Prototype validation requirement:** Highly recommended to tune the "mini-slide" calculation (does it fall 1 tile, or slide until hitting a wall?) and verify the BFS tractability with $2^N$ state expansion.
