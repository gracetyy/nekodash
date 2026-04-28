# Mechanism Analysis: Warp Tile (Teleporter)

## 1. Technical Implementation
- **Slide resolver change**: Moderate. `resolve_slide()` needs to detect a `WARP` tile during its traversal loop. When hit, the cat's current position jumps to the destination tile, and momentum is reset (velocity becomes zero).
- **Grid System tile type**: Requires a new `WARP` tile type with a `destination_coords` metadata field.
- **New node/system required**: No. Can be integrated into `GridSystem`.
- **Signal contract changes**: Might need a `teleported(from, to)` signal for VFX/SFX triggers.
- **Hard vs. soft dependency**: Hard dependency on `resolve_slide()`.

## 2. Level Solvability & BFS Impact
- **State space expansion**: Minimal. Teleporters are static.
- **State count multiplier**: 1x. The number of reachable states remains the same, but the edges in the graph change.
- **BFS tractability threshold**: No impact. In fact, it might make BFS faster by shortening paths.
- **Solver reuse**: Requires a minor update to the BFS `slide()` function to handle the jump.
- **Per-level re-verification cost**: Standard.

## 3. Level Design Impact
- **Design space opened**: Enables "portal-style" logic. Allows connecting distant parts of the grid without a direct path. Good for large grids (8x8+).
- **Design space closed**: Linear distance is no longer a constraint.
- **Placement rule compatibility**: High. Warp tiles can be placed anywhere.
- **Incremental wall-addition workflow**: Compatible.
- **Difficulty scaling**: Scalable. Easy levels have one pair; hard levels have multiple pairs with intersecting paths.

## 4. Game Design & Player Experience
- **Pillar 1 — Every Move Is a Choice**: Fully predictable. Visual pairing (color/symbol) ensures the player knows where they will end up. Momentum cancellation prevents "infinite loop" confusion.
- **Pillar 2 — Joyful at Every Moment**: The "poof" animation and sudden relocation are satisfying and magical.
- **Pillar 3 — Complete Your Own Way**: Open. Warp tiles are just another tool in the movement kit.
- **Cognitive load**: Medium. Players must mentally map "Point A = Point B."
- **First-encounter teachability**: Trivial. A single path that goes through a warp tile to reach the only remaining exit.
- **Frustration vs. challenge balance**: Low risk. Teleporters are a well-understood gaming trope.

## 5. Audio & Visual Feedback
- **Unique SFX requirement**: A "magic swirl" or "digital zip" sound.
- **Animation requirement**: A "shrink-and-grow" or "particle dissolve" effect at the entry/exit tiles.
- **Visual legibility on mobile**: Critical. Pairs must be clearly color-coded (Blue pair, Orange pair) or use distinct symbols (Star, Moon) that are visible even on small tiles.
- **Thematic fit**: "The Magic Closet" or "Laundry Chute." Fits World 1 (The Hallway) as laundry chutes or World 3 (Dream) as portals.
- **Haptic opportunity**: A sharp, clean "pop" haptic on arrival.

## 6. Undo / Restart Compatibility
- **Snapshot delta**: None. Since warp tiles are static, standard position tracking is sufficient.
- **Undo atomicity**: Fully compatible.
- **Restart idempotency**: Fully compatible.
- **Signal connection order**: No special requirements.

## 7. Save / Persistence
- **New persisted fields**: None.
- **Mid-level transient state**: None.
- **Best-moves record validity**: No impact.

## 8. Star Rating & Move Economy
- **Move count inflation**: Negative. Teleporters usually reduce the number of moves needed to cross the board.
- **BFS minimum recalculation**: Mandatory.
- **Skill expression ceiling**: High. Strategic use of teleporters can bypass large sections of the grid to hit 3-star targets.
- **Star threshold formula compatibility**: Compatible.

## 9. Mobile UX
- **Touch interaction model**: Standard swipe.
- **Screen real estate**: No new HUD.
- **Tap state / active feedback**: Tapping a warp tile could briefly highlight its partner.
- **Accessibility**: No issues.

## 10. World Fit & Narrative Coherence
- **Thematic grounding**: Cardboard boxes with "holes," laundry chutes, or open doors leading to the same room.
- **World assignment**: World 1 (Introduction) or World 3 (Thematic).
- **Skin / cosmetic interaction**: None.

## 11. Post-MVP Scope Risk
- **GDD amendment surface**: Low. Small changes to `GridSystem` and `LevelDataFormat`.
- **Combinatorial interaction risk**: Moderate. What happens if a "Pushable Block" is pushed into a teleporter? (Current design says momentum cancels, so the block would just stop at the exit).
- **Reversibility**: High.
- **Prototype validation requirement**: Low. This is a standard mechanic.
