# Gameplay Mechanism Analysis: One-Way Tile (Directional Permeable Wall)

## 1. Technical Implementation
- **Slide resolver change**: Medium. `resolve_slide()` currently checks if a tile is `BLOCKING`. For One-Way Tiles, it must also check the entry direction. If the cat enters from the "back" side, it's treated as a wall; from the "front", it's walkable.
- **Grid System tile type**: New `tile_type` or a metadata property on `WALKABLE` tiles. A dedicated `ONE_WAY` type with a `direction` property (Up, Down, Left, Right) is most explicit.
- **New node/system required**: Can be integrated into the existing `GridSystem`. No new standalone system is strictly necessary, but `LevelData` needs to support directional metadata for this tile type.
- **Signal contract changes**: None. Existing `slide_completed` and `slide_blocked` suffice.
- **Hard vs. soft dependency**: Hard dependency on `GridSystem` and `SlidingMovement`.

## 2. Level Solvability & BFS Impact
- **State space expansion**: Zero. Since the tile's behavior is static (it doesn't change state after being used), it does not add new variables to the BFS state tuple.
- **State count multiplier**: 1x.
- **BFS tractability threshold**: No impact. Levels with One-Way Tiles are as easy for the BFS to solve as standard levels.
- **Solver reuse**: Requires a minor update to the BFS `slide()` reference function to respect directional permeability.
- **Per-level re-verification cost**: Low. standard automated verification on save.

## 3. Level Design Impact
- **Design space opened**: Enables asymmetric routing. A player can go from A to B but not return the same way, creating "point of no return" sections within a puzzle.
- **Design space closed**: None. It complements existing wall placement.
- **Placement rule compatibility**: High. One-Way Tiles can be placed anywhere on the grid, including internal "filter" points.
- **Incremental wall-addition workflow**: Fully compatible.
- **Difficulty scaling**: Can be an early-game mechanic (World 1). Simple to understand but adds depth to routing.

## 4. Game Design & Player Experience
- **Pillar 1 — Every Move Is a Choice**: Outcomes are 100% predictable. The directional indicator (e.g., an arrow or a slat) clearly shows where passage is possible.
- **Pillar 2 — Joyful at Every Moment**: Passing through a "cat flap" or "slat" can have a satisfying "shloop" sound and a slight visual wobble of the obstacle.
- **Pillar 3 — Complete Your Own Way**: Increases agency by allowing designers to create "shortcuts" that only work in one direction.
- **Cognitive load**: Very low. Players are familiar with one-way doors from many other genres.
- **First-encounter teachability**: Excellent. A single level with a one-way tile blocking the only path to the goal will teach the mechanic instantly.
- **Frustration vs. challenge balance**: Low frustration; it feels like a logical boundary rather than a trap.

## 5. Audio & Visual Feedback
- **Unique SFX requirement**: Yes. A unique "shloop" or "clap" sound when passing through, and a standard "bump" sound when hitting the blocked side.
- **Animation requirement**: Subtle. The tile visual (e.g., a swinging flap) should animate slightly when the cat passes through.
- **Visual legibility on mobile**: High. A clear arrow or a "V" shaped slat indicates directionality even at small scales.
- **Thematic fit**: Perfect. Cat flaps, half-open doors, or leaning furniture items are very "cat-in-an-apartment."
- **Haptic opportunity**: A light "tap" when passing through, standard "thud" when hitting the back.

## 6. Undo / Restart Compatibility
- **Snapshot delta**: None. No state change to record.
- **Undo atomicity**: Fully atomic.
- **Restart idempotency**: Fully idempotent.
- **Signal connection order**: No special requirements.

## 7. Save / Persistence
- **New persisted fields**: None.
- **Mid-level transient state**: None.
- **Best-moves record validity**: No impact.

## 8. Star Rating & Move Economy
- **Move count inflation**: Minimal. It primarily constrains *where* you can go, not how many moves it takes to get there.
- **BFS minimum recalculation**: Standard.
- **Skill expression ceiling**: High. Finding the correct "order of entry" into filtered areas becomes a key skill.
- **Star threshold formula compatibility**: High.

## 9. Mobile UX
- **Touch interaction model**: Swipe-only.
- **Screen real estate**: No HUD impact.
- **Tap state / active feedback**: Visual feedback (flap wiggle) when passing through.
- **Accessibility**: No timing or rapid input required.

## 10. World Fit & Narrative Coherence
- **Thematic grounding**: Cat flap (World 1), a slightly open closet door (World 2), or a tilted book on a shelf (World 3).
- **World assignment**: World 1. It's a foundational mechanic.
- **Skin / cosmetic interaction**: None.

## 11. Post-MVP Scope Risk
- **GDD amendment surface**: Low. Only `GridSystem` and `SlidingMovement` need updates.
- **Combinatorial interaction risk**: Low. It interacts predictably with other tiles (Conveyor, Stop-Slide).
- **Reversibility**: High. Easily removed by converting tiles back to standard walls or walkable floor.
- **Prototype validation requirement**: Low. This is a very standard puzzle mechanic.
