# Kill Tile (Hazard Floor) - Analysis

## 1. Technical Implementation
- **Slide resolver change:** Minimal change required. The `resolve_slide()` function already checks for obstacles to stop the cat. This would add a "traversal check" where, during the loop that moves the cat tile-by-tile, it checks if the current tile's type is `HAZARD`. If true, it immediately triggers a `death` event instead of continuing or stopping.
- **Grid System tile type:** Requires a new `tile_type` enum value (e.g., `HAZARD`).
- **New node/system required:** No new standalone system needed. It integrates directly into the existing `GridSystem` and `SlidingMovement` logic. A `HazardManager` could be added for visual/audio variety, but is not strictly necessary for logic.
- **Signal contract changes:** Requires a new `cat_died` signal in the `LevelCoordinator` or `SlidingMovement` system to trigger the restart/death sequence.
- **Hard vs. soft dependency:** Soft dependency. It builds upon existing tile logic without restructuring core movement.

## 2. Level Solvability & BFS Impact
- **State space expansion:** Zero. Since the cat dies upon contact, these tiles are effectively "inverse walls" or "holes" that cannot be part of a valid state. They do not add new variables to the state tuple.
- **State count multiplier:** 1x. It actually *reduces* the searchable state space by pruning any paths that touch a hazard tile.
- **BFS tractability threshold:** Improves tractability. By making certain tiles impassable, it narrows the search tree.
- **Solver reuse:** The `slide()` reference function can be easily updated to return a `null` or `DEATH` state if a hazard is crossed, allowing the BFS to discard that branch.
- **Per-level re-verification cost:** Low. Standard BFS verification remains efficient.

## 3. Level Design Impact
- **Design space opened:** "Narrow bridge" puzzles, "one-way" style routing (by placing hazards strategically), and high-stakes traversal. It forces players to move *around* areas rather than through them.
- **Design space closed:** Reduces the amount of "safe" space. Overuse can make levels feel claustrophobic.
- **Placement rule compatibility:** Fully compatible with edge-row/column rules. Hazards act as "invisible walls" during a slide.
- **Incremental wall-addition workflow:** Fully compatible. Designers can swap a wall for a hazard to change the "failure feel" without breaking the logic flow.
- **Difficulty scaling:** Excellent. Early levels can have large, obvious puddles. Late-game levels can use them to create tight, single-solution corridors.

## 4. Game Design & Player Experience
- **Pillar 1 — Every Move Is a Choice:** Fully supported. The player can see the hazard and knows that sliding over it results in death. The outcome is 100% predictable.
- **Pillar 2 — Joyful at Every Moment:** Death must be "cute" or "funny" rather than punishing. A "wet cat" animation or a "shocked" expression keeps the tone light.
- **Pillar 3 — Complete Your Own Way:** Hazards restrict paths, potentially limiting creative solutions, but they define the "boundaries" of the puzzle clearly.
- **Cognitive load:** Low. "Don't touch the bad tile" is a universal gaming convention.
- **First-encounter teachability:** Very high. A single puddle in a simple path is self-explanatory.
- **Frustration vs. challenge balance:** Low frustration as long as the visual cues are clear. If a hazard looks like a regular tile, frustration spikes.

## 5. Audio & Visual Feedback
- **Unique SFX requirement:** Requires a "splash", "crackle", or "tinkle" sound depending on the hazard type, followed by a failure jingle.
- **Animation requirement:** Needs a "death" or "failure" state for the cat sprite (e.g., puff of smoke, soaked fur).
- **Visual legibility on mobile:** High. Use high-contrast colors (blue for water, yellow for sparks) against the floor tiles.
- **Thematic fit:** Perfect. Wet floors, spilled juice, broken glass, or loose wires are all common in a messy apartment.
- **Haptic opportunity:** Sharp, double-pulse haptic on death to signal failure.

## 6. Undo / Restart Compatibility
- **Snapshot delta:** None. Death triggers a full level restart, so there is no "undoing" a death in a turn-based sense (the move never "finishes" successfully).
- **Undo atomicity:** N/A (Restart only).
- **Restart idempotency:** Perfectly idempotent. `restart()` simply resets the cat to the start position.
- **Signal connection order:** The `cat_died` signal should be handled with high priority by the `LevelCoordinator` to halt all other logic.

## 7. Save / Persistence
- **New persisted fields:** None.
- **Mid-level transient state:** None.
- **Best-moves record validity:** No impact. Hazards don't change move counts; they just restrict valid paths.

## 8. Star Rating & Move Economy
- **Move count inflation:** None.
- **BFS minimum recalculation:** No special recalculation needed beyond standard solver update.
- **Skill expression ceiling:** No direct impact, though they can be used to block "shortcuts" that would otherwise trivialize a level.
- **Star threshold formula compatibility:** Fully compatible.

## 9. Mobile UX
- **Touch interaction model:** Standard swipe. No new UI.
- **Screen real estate:** Zero overhead.
- **Tap state / active feedback:** Visual death animation is the feedback.
- **Accessibility:** Highly accessible as it doesn't require timing.

## 10. World Fit & Narrative Coherence
- **Thematic grounding:** Strong. "Cat hates water" is a classic trope.
- **World assignment:** 
    - World 1: Spilled Water / Juice.
    - World 2: Broken Glass / Ornaments.
    - World 3: Exposed Wires / Sparking Sockets.
- **Skin / cosmetic interaction:** Some skins could have unique death animations (e.g., a "Diver Cat" skin that just swims in the water puddles - though it still counts as a fail for gameplay consistency).

## 11. Post-MVP Scope Risk
- **GDD amendment surface:** Low. Small updates to `GridSystem` and `SlidingMovement`.
- **Combinatorial interaction risk:** Low. Interacts predictably with other mechanics (e.g., a pushable block might cover a hazard - see "Pushable Block" analysis).
- **Reversibility:** High. Easily removed by changing the tile type back to `WALKABLE`.
- **Prototype validation requirement:** Recommended to test "traversal death" vs "destination death" (do you die if you *end* on it, or *pass through* it?). The prompt specifies "upon contact during a slide," which implies traversal death.
