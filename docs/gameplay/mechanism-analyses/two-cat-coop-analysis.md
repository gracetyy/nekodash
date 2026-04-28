# Mechanism Analysis: Two-Cat Co-op Tile (Echo Mechanic)

## 1. Technical Implementation
- **Slide resolver change**: High. `resolve_slide()` must now handle two separate entities. The movement logic needs to calculate the final destination for both cats simultaneously. If one cat is blocked, it stops, while the other continues until it hits an obstacle.
- **Grid System tile type**: Requires a new `ECHO_START` position or a special level attribute.
- **New node/system required**: Requires a second `Cat` instance and a `CoopCoordinator` (or major update to `LevelCoordinator`) to manage dual input distribution.
- **Signal contract changes**: `slide_completed` must only fire when *both* cats have finished their move.
- **Hard vs. soft dependency**: Hard dependency. It fundamentally changes the core sliding loop.

## 2. Level Solvability & BFS Impact
- **State space expansion**: Massive. State tuple = `(Cat1Pos, Cat2Pos, CoverageBitmask)`.
- **State count multiplier**: `GridWidth * GridHeight` (approximately 25-100x multiplier).
- **BFS tractability threshold**: High risk. A 5x5 grid with two cats effectively becomes a search space similar to a much larger single-cat grid. Levels using this mechanic must be kept small (e.g., 4x4 or 5x5 max).
- **Solver reuse**: Cannot be reused. Needs a dedicated `CoopSolver`.
- **Per-level re-verification cost**: Very High. Re-solving will be significantly slower.

## 3. Level Design Impact
- **Design space opened**: Introduces "spatial coordination" puzzles. Players must use obstacles to "de-sync" the cats so they can reach different areas.
- **Design space closed**: Traditional "single path" optimization is replaced by "dual coverage."
- **Placement rule compatibility**: Medium. Mirror symmetry is suggested, but not strictly required.
- **Incremental wall-addition workflow**: Difficult. BFS re-runs will take seconds or minutes instead of milliseconds.
- **Difficulty scaling**: Inherently Hard. Reserved for bonus or World 3+ levels.

## 4. Game Design & Player Experience
- **Pillar 1 — Every Move Is a Choice**: Yes, but the outcome is much harder to visualize. Predictability remains, but cognitive load is tripled.
- **Pillar 2 — Joyful at Every Moment**: High. Watching two cats slide in tandem is inherently charming.
- **Pillar 3 — Complete Your Own Way**: Can feel restrictive if the level is too tightly tuned.
- **Cognitive load**: Very High. Players must track two positions and two sets of potential obstacles for every swipe.
- **First-encounter teachability**: Requires a very simple "Introduction to Echo" level where the two cats start next to each other.
- **Frustration vs. challenge balance**: High risk of frustration if cats get "stuck" in a way that is hard to reverse mentally.

## 5. Audio & Visual Feedback
- **Unique SFX requirement**: The "ghost cat" should have a shimmering, higher-pitched slide sound or a "meow echo."
- **Animation requirement**: A "desync" animation if one cat hits a wall before the other.
- **Visual legibility on mobile**: High risk. Two cats + coverage markers on a small screen can get cluttered. The ghost cat must be semi-transparent or a distinct color (e.g., blue-tinted).
- **Thematic fit**: "The Imaginary Friend." Fits World 3 (The Dream/Nighttime Room).
- **Haptic opportunity**: Dual vibrations if both hit walls at the same time.

## 6. Undo / Restart Compatibility
- **Snapshot delta**: `MoveSnapshot` must capture `cat1_pos` and `cat2_pos`.
- **Undo atomicity**: Compatible. One undo reverses both cats.
- **Restart idempotency**: Resets both cats to their start positions.
- **Signal connection order**: `LevelCoordinator` must wait for both `slide_finished` signals before proceeding.

## 7. Save / Persistence
- **New persisted fields**: If bonus levels have different completion states, `nekodash_save.json` needs a `coop_unlocked` flag.
- **Mid-level transient state**: None.
- **Best-moves record validity**: Independent.

## 8. Star Rating & Move Economy
- **Move count inflation**: High. Coordinating two cats usually takes more moves than one.
- **BFS minimum recalculation**: Mandatory and expensive.
- **Skill expression ceiling**: Extremely High. Master players will find ways to use one cat as a "brake" for the other.
- **Star threshold formula compatibility**: May need a different multiplier (e.g., `star2 = min_moves + 2`) rather than a percentage.

## 9. Mobile UX
- **Touch interaction model**: Standard swipe.
- **Screen real estate**: No new HUD, but grid visibility is paramount.
- **Tap state / active feedback**: Tapping the screen could highlight both cats to remind the player of the dual-control.
- **Accessibility**: Higher cognitive load may be an issue for some players.

## 10. World Fit & Narrative Coherence
- **Thematic grounding**: A mirror in the hallway or a "nightmare" version of the room.
- **World assignment**: World 3 or Post-Game Bonus levels.
- **Skin / cosmetic interaction**: Could unlock "Twin" skins.

## 11. Post-MVP Scope Risk
- **GDD amendment surface**: High. Affects `SlidingMovement`, `LevelCoordinator`, `BFS Solver`, and `LevelDataFormat`.
- **Combinatorial interaction risk**: High. Interacting with "Teleporters" or "Pushable Blocks" with two cats could create complex edge cases.
- **Reversibility**: Low. Once the architecture supports two cats, removing it is easy, but the initial cost is high.
- **Prototype validation requirement**: Mandatory. Must verify if BFS is actually tractable for 5x5 grids before committing.
