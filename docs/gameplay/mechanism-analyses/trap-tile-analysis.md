# Mechanism Analysis: Trap Tile (Delayed Effect)

## 1. Technical Implementation
- **Slide resolver change**: `resolve_slide()` requires a post-slide hook. The trap triggers *after* the cat leaves the tile on the *next* move. This implies the Grid System needs to store "primed" traps.
- **Grid System tile type**: Requires a new `TRAP` tile type.
- **New node/system required**: Can be handled within the existing `GridSystem` and `ObstacleSystem`. The "trap wall" can be a dynamically toggled `StaticObstacle`.
- **Signal contract changes**: Requires listening to `move_started` to trigger the primed effect from the previous move.
- **Hard vs. soft dependency**: Hard dependency on `GridSystem` for state tracking and `SlidingMovement` for trigger timing.

## 2. Level Solvability & BFS Impact
- **State space expansion**: Adds a boolean flag for each trap tile (IsPrimed? or IsTriggered?).
- **State count multiplier**: `2^N` where N is the number of trap tiles. However, since traps usually trigger once and stay triggered, the practical expansion is manageable.
- **BFS tractability threshold**: Low impact unless a level is saturated with traps. Most levels will use 1-3 traps, keeping BFS well within the 15s limit.
- **Solver reuse**: Requires a small fork or update to the BFS `slide()` function to simulate the delayed wall spawning.
- **Per-level re-verification cost**: Standard. Any change to trap placement requires a full re-solve.

## 3. Level Design Impact
- **Design space opened**: Enables "bridge-burning" puzzles where the player must choose the order of visits carefully because paths will disappear.
- **Design space closed**: None significant, but designers must ensure traps don't create unsolvable islands (though BFS will catch this).
- **Placement rule compatibility**: High. Traps can be placed anywhere in the walkable grid.
- **Incremental wall-addition workflow**: Compatible.
- **Difficulty scaling**: Inherently a mid-to-late game mechanic (World 2+) as it requires multi-move anticipation.

## 4. Game Design & Player Experience
- **Pillar 1 — Every Move Is a Choice**: Fully predictable. The "subtle visual marker" ensures the player knows a trap is there. The delay allows for strategic "escape" moves.
- **Pillar 2 — Joyful at Every Moment**: The "clack" of a hidden wall popping up provides a satisfying sense of consequence.
- **Pillar 3 — Complete Your Own Way**: Encourages efficiency.
- **Cognitive load**: Adds one rule: "The tile I just left will become a wall after my next move."
- **First-encounter teachability**: Easy. A level where the only way to reach a corner is to pass through a trap that then blocks an exit, forcing a specific sequence.
- **Frustration vs. challenge balance**: Fair, as long as the visual indicator is clear.

## 5. Audio & Visual Feedback
- **Unique SFX requirement**: Needs a "mechanical click" when stepped on (priming) and a "heavy thud/slide" when the wall appears (triggering).
- **Animation requirement**: Needs a tween for the wall rising from the floor or a piece of furniture sliding into place.
- **Visual legibility on mobile**: The "glint" must be high-contrast (e.g., a pulsing yellow border or a cracked texture).
- **Thematic fit**: Fits perfectly—loose floorboards, a rug that bunches up, or a spring-loaded cat tree.
- **Haptic opportunity**: A light tap when priming, a heavy thud when triggering.

## 6. Undo / Restart Compatibility
- **Snapshot delta**: `MoveSnapshot` must store the state of all traps (Inactive, Primed, Triggered).
- **Undo atomicity**: Fully compatible. Reversing a move should un-trigger or un-prime the trap.
- **Restart idempotency**: Resets all traps to Inactive.
- **Signal connection order**: Trap logic should execute immediately after `move_started` is processed.

## 7. Save / Persistence
- **New persisted fields**: None (mid-level state only).
- **Mid-level transient state**: If a player kills the app mid-move, the level restarts anyway, so no persistence is needed.
- **Best-moves record validity**: No impact.

## 8. Star Rating & Move Economy
- **Move count inflation**: Minimal. It restricts paths rather than requiring extra moves.
- **BFS minimum recalculation**: Mandatory to account for the dynamic obstacles.
- **Skill expression ceiling**: High. Players can use traps to create new stopping points that were previously unavailable.
- **Star threshold formula compatibility**: Compatible.

## 9. Mobile UX
- **Touch interaction model**: Standard swipe.
- **Screen real estate**: No new HUD needed.
- **Tap state / active feedback**: The tile should change color/state immediately upon being stepped on.
- **Accessibility**: No timing requirements.

## 10. World Fit & Narrative Coherence
- **Thematic grounding**: "The Unstable Apartment." Very coherent with World 2 (The Messy Room).
- **World assignment**: World 2.
- **Skin / cosmetic interaction**: A "Daring Explorer" skin could be gated by trap-heavy levels.

## 11. Post-MVP Scope Risk
- **GDD amendment surface**: Moderate. Requires updates to `GridSystem` and `LevelCoordinator`.
- **Combinatorial interaction risk**: Low, but interacting with "Pushable Blocks" might get complex if a block is pushed onto a trap.
- **Reversibility**: High. Easy to remove by deleting the tile type and logic.
- **Prototype validation requirement**: Recommended to test the "Delayed Effect" timing to ensure it feels intuitive.
