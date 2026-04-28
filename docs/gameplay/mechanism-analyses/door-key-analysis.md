# Gameplay Mechanism Analysis: Door + Key (Conditional Unlock)

## 1. Technical Implementation
- **Slide resolver change**: Moderate impact. The `resolve_slide()` function needs to check the current `walkable` state of the "Door" tile. The "Door" tile is a dynamic obstacle whose state changes from `BLOCKING` to `WALKABLE` mid-level.
- **Grid System tile type**: Requires a new `tile_type` for the "Door" (e.g., `LOCKED_DOOR`) and "Key" (e.g., `KEY_ITEM`). 
- **New node/system required**: Can extend the existing `Obstacle System`. A `KeyManager` or `ConditionalUnlockManager` might be needed as a soft downstream subscriber to track collected keys.
- **Signal contract changes**: Requires a `key_collected` signal and a `door_unlocked` signal. `resolve_slide()` must be able to react to the state change.
- **Hard vs. soft dependency**: Soft dependency on core sliding logic, but requires the Grid System to support dynamic tile state updates.

## 2. Level Solvability & BFS Impact
- **State space expansion**: Adds a boolean `is_key_collected` to the BFS state tuple.
- **State count multiplier**: Worst-case: `2 * covered_set`. Each tile coverage state can now exist in two versions: "key not held" and "key held".
- **BFS tractability threshold**: Low risk. Doubling the state space for 25 walkable tiles still keeps the total state count well within tractable limits.
- **Solver reuse**: The solver needs to be updated to include the key state in its state representation and transition logic.
- **Per-level re-verification cost**: Standard re-solve is required, but it shouldn't significantly increase solving time.

## 3. Level Design Impact
- **Design space opened**: Enables "soft visit order" puzzles where players must reach a specific part of the grid before another becomes accessible.
- **Design space closed**: No major closures; it adds a layer of complexity to existing archetypes.
- **Placement rule compatibility**: High. Doors can be placed anywhere, though usually in "bottleneck" positions to be effective.
- **Incremental wall-addition workflow**: Still valid. Designers can verify solvability at each step.
- **Difficulty scaling**: Inherently a late-game or Hard difficulty mechanic due to the added cognitive layer of sequencing.

## 4. Game Design & Player Experience
- **Pillar 1 — Every Move Is a Choice**: Outcome is fully predictable. The player knows picking up the key will open the door.
- **Pillar 2 — Joyful at Every Moment**: Picking up the key can trigger a satisfying "click" or jingle, and the door opening can have a small "poof" or "sliding away" animation.
- **Pillar 3 — Complete Your Own Way**: Enforces a specific order for that segment, but the route to the key and from the door can still be flexible.
- **Cognitive load**: Low to Medium. "Get key -> Open door" is a very common gaming trope that is intuitive for most players.
- **First-encounter teachability**: Can be taught in a simple level with one key and one door blocking the only path to a final tile.
- **Frustration vs. challenge balance**: Feels fair. The objective is clear.

## 5. Audio & Visual Feedback
- **Unique SFX requirement**: Needs a "Key Pickup" sound and a "Door Unlock/Open" sound.
- **Animation requirement**: Key should have a subtle "floating/bobbing" tween. Door needs a "disappearing" or "opening" animation.
- **Visual legibility on mobile**: High. Keys and Doors are easily distinguishable icons.
- **Thematic fit**: Fits perfectly (e.g., a "closed pet gate" and a "latch key").
- **Haptic opportunity**: A sharp "pop" on key pickup and a satisfying "rumble" when a door opens.

## 6. Undo / Restart Compatibility
- **Snapshot delta**: `MoveSnapshot` must capture the `is_key_collected` boolean and the current state of any doors.
- **Undo atomicity**: Fully atomic. Undoing a move that picked up a key will reset the key to the tile and re-lock the door.
- **Restart idempotency**: `restart()` resets the key to its original position and the door to its locked state.
- **Signal connection order**: `LevelCoordinator` handles the sequence.

## 7. Save / Persistence
- **New persisted fields**: None required for mid-level state (as per ADR-0003). However, if key collection persists across levels (rare for this genre), it would need schema updates.
- **Mid-level transient state**: Not persisted.
- **Best-moves record validity**: If added to an existing level, it will change the minimum move count, requiring a record reset for that level.

## 8. Star Rating & Move Economy
- **Move count inflation**: Inherently raises the minimum moves because the player *must* detour to the key.
- **BFS minimum recalculation**: Mandatory for levels with this mechanic.
- **Skill expression ceiling**: Mastery involves finding the most efficient route that picks up the key and then utilizes the door.
- **Star threshold formula compatibility**: Formulas remain fair.

## 9. Mobile UX
- **Touch interaction model**: Swipe to move over the key. No extra UI elements needed.
- **Screen real estate**: Minimal impact.
- **Tap state / active feedback**: Visual feedback on the door and key tiles is essential.
- **Accessibility**: No timing required.

## 10. World Fit & Narrative Coherence
- **Thematic grounding**: Very strong. Pet gates, locked cabinets, or even a toy that "unlocks" a cat's interest.
- **World assignment**: Best for World 2 or World 3 to keep World 1 simple.
- **Skin / cosmetic interaction**: Could unlock a "Locksmith Cat" skin.

## 11. Post-MVP Scope Risk
- **GDD amendment surface**: Requires updates to `Grid System`, `Obstacle System`, `Level Data Format`, and `BFS Solver`.
- **Combinatorial interaction risk**: Medium. What happens if a Conveyor Belt pushes you *over* a key? (Should still collect it).
- **Reversibility**: Moderate. Once integrated into the solver and grid, removing it involves cleaning up several systems.
- **Prototype validation requirement**: Recommended to test the feel of the transition from blocking to walkable.
