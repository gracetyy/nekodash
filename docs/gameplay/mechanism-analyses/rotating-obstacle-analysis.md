# Mechanism Analysis: Rotating Obstacle

## 1. Technical Implementation
- **Slide resolver change**: Moderate. The `ObstacleSystem` needs to handle 1x2 and 2x1 footprints. When a cat bumps into this obstacle, it triggers a `rotate()` function that flips its orientation.
- **Grid System tile type**: Requires the obstacle to occupy multiple grid cells. The `walkable` property of these cells must be updated atomically.
- **New node/system required**: Requires a `RotatingObstacle` node that extends `StaticObstacle` but adds rotation logic and state.
- **Signal contract changes**: Listens for `slide_blocked` signals specifically originating from the cat's collision with *this* object.
- **Hard vs. soft dependency**: Hard dependency on `GridSystem` for tile occupation updates.

## 2. Level Solvability & BFS Impact
- **State space expansion**: Adds a rotation state (0 or 1) for each rotating obstacle.
- **State count multiplier**: `2^N` where N is the number of rotating obstacles.
- **BFS tractability threshold**: Moderate. Since rotation is triggered by collision, the state space only changes when the player actively interacts with the obstacle. This keeps the effective search space manageable for 1-4 obstacles.
- **Solver reuse**: Requires updating the BFS `slide()` function to simulate the rotation on bump.
- **Per-level re-verification cost**: Standard.

## 3. Level Design Impact
- **Design space opened**: Enables "valve-style" puzzles where the player must hit an object from a specific side to open a path elsewhere, then loop back.
- **Design space closed**: Static path planning is replaced by dynamic reconfiguration.
- **Placement rule compatibility**: Medium. The 1x2 footprint requires careful placement so it doesn't overlap other permanent obstacles.
- **Incremental wall-addition workflow**: Compatible.
- **Difficulty scaling**: Mid-to-late game. Introduces a "multi-state" layer to the puzzle.

## 4. Game Design & Player Experience
- **Pillar 1 — Every Move Is a Choice**: Fully predictable. The rotation happens *after* the bump, so the player can plan the *next* move based on the new orientation.
- **Pillar 2 — Joyful at Every Moment**: The rotation animation (especially if it looks like a spinning rack or a lazy susan) is satisfying and physical.
- **Pillar 3 — Complete Your Own Way**: High agency. The player "shapes" the level.
- **Cognitive load**: Medium. Players must visualize the "other" orientation.
- **First-encounter teachability**: Very high. A level where a horizontal obstacle blocks the only exit; hitting it turns it vertical and clears the way.
- **Frustration vs. challenge balance**: Low risk.

## 5. Audio & Visual Feedback
- **Unique SFX requirement**: A "creaky wood" or "spinning bearing" sound. A distinct "clack" when it locks into the new position.
- **Animation requirement**: A smooth 90-degree tween.
- **Visual legibility on mobile**: High. The 1x2 footprint must be visually distinct from 1x1 walls. Use of shadows or a distinct "base" can help.
- **Thematic fit**: "The Cluttered Apartment." A Lazy Susan, a pivoting office chair, or a standing coat rack.
- **Haptic opportunity**: A rotational vibration (long, low-frequency pulse).

## 6. Undo / Restart Compatibility
- **Snapshot delta**: `MoveSnapshot` must store the `current_orientation` for every rotating obstacle.
- **Undo atomicity**: Fully compatible. Reversing a move rotates it back.
- **Restart idempotency**: Resets to initial orientation.
- **Signal connection order**: Rotation logic must trigger after the slide resolution is finalized.

## 7. Save / Persistence
- **New persisted fields**: None (mid-level state only).
- **Mid-level transient state**: None.
- **Best-moves record validity**: No impact.

## 8. Star Rating & Move Economy
- **Move count inflation**: Moderate. Opening/closing paths often requires "setup" moves.
- **BFS minimum recalculation**: Mandatory.
- **Skill expression ceiling**: High. Advanced players will use the rotation to "block" themselves into specific tiles for coverage.
- **Star threshold formula compatibility**: Compatible.

## 9. Mobile UX
- **Touch interaction model**: Standard swipe.
- **Screen real estate**: No new HUD.
- **Tap state / active feedback**: The obstacle could "wobble" if tapped to show it's interactive.
- **Accessibility**: No issues.

## 10. World Fit & Narrative Coherence
- **Thematic grounding**: A swivel chair in the office (World 3) or a rotating spice rack in the kitchen (World 2).
- **World assignment**: World 2 or 3.
- **Skin / cosmetic interaction**: None.

## 11. Post-MVP Scope Risk
- **GDD amendment surface**: Moderate. Requires `ObstacleSystem` to support non-square footprints and state.
- **Combinatorial interaction risk**: Moderate. What happens if two rotating obstacles are next to each other and one's rotation is "blocked" by the other? (Design should probably prevent overlapping footprints).
- **Reversibility**: High.
- **Prototype validation requirement**: Recommended to test the "bump-to-rotate" feel.
