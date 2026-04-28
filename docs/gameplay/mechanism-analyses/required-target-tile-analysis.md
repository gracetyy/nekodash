# Gameplay Mechanism Analysis: Required Target Tile (Order-Sensitive Goal)

## 1. Technical Implementation
- **Slide resolver change**: Low impact. `resolve_slide()` doesn't change, but the "level win" condition (Coverage Tracking) needs a major update.
- **Grid System tile type**: Requires a new `tile_type` (e.g., `NUMBERED_TARGET`) with an associated `sequence_index` attribute.
- **New node/system required**: `Coverage Tracking` GDD needs to be amended to handle sequence validation.
- **Signal contract changes**: New signal `sequence_broken` or `target_activated`.
- **Hard vs. soft dependency**: Hard dependency on the Level Completion logic.

## 2. Level Solvability & BFS Impact
- **State space expansion**: Adds a `next_required_index` integer to the BFS state tuple.
- **State count multiplier**: Worst-case: `N * covered_set`, where N is the number of sequenced tiles.
- **BFS tractability threshold**: Moderate risk. If there are 5 numbered tiles, the state space expands by 5x. For a 25-tile grid, this is still likely tractable, but requires optimization.
- **Solver reuse**: Solver must be updated to track the sequence index and only mark "completed" when the index matches.
- **Per-level re-verification cost**: Moderate. Solving might take a few seconds longer.

## 3. Level Design Impact
- **Design space opened**: Transforms coverage puzzles into "pathing" puzzles. Enables much tighter, more prescriptive solutions. Excellent for "Hard" levels.
- **Design space closed**: Reduces player freedom by enforcing a specific sequence.
- **Placement rule compatibility**: High.
- **Incremental wall-addition workflow**: Still valid.
- **Difficulty scaling**: High. Naturally scales difficulty without adding more walls or tiles.

## 4. Game Design & Player Experience
- **Pillar 1 — Every Move Is a Choice**: Predictable, but requires more long-term planning. The player must see the whole sequence (1-2-3) and plan the entire path before swiping.
- **Pillar 2 — Joyful at Every Moment**: Activating a target in sequence should feel very satisfying (a "ding" that increases in pitch).
- **Pillar 3 — Complete Your Own Way**: Less agency in *what* to do, but agency remains in *how* to move between numbers.
- **Cognitive load**: High. Tracking 11+ covered tiles *plus* a sequence of 3-5 numbers is demanding.
- **First-encounter teachability**: Can be taught with just two tiles (1 and 2) in a clear path.
- **Frustration vs. challenge balance**: Can be frustrating if the player covers #2 by accident while trying to reach #1. "Accidental sequence breaking" is the biggest risk.

## 5. Audio & Visual Feedback
- **Unique SFX requirement**: A "shepard tone" style rising sequence of dings. A distinct "error/buzz" sound for visiting a target out of order.
- **Animation requirement**: Numbered tiles should "light up" or change color when activated.
- **Visual legibility on mobile**: High. Use large, clear numbers (1, 2, 3).
- **Thematic fit**: Numbered bowls, numbered toys, or different colored cushions.
- **Haptic opportunity**: A light "tick" for each target, and a dual-pulse for the final target.

## 6. Undo / Restart Compatibility
- **Snapshot delta**: `MoveSnapshot` must capture the current `next_required_index`.
- **Undo atomicity**: Fully atomic.
- **Restart idempotency**: Clean reset.
- **Signal connection order**: Standard.

## 7. Save / Persistence
- **New persisted fields**: None.
- **Mid-level transient state**: None.
- **Best-moves record validity**: No issues.

## 8. Star Rating & Move Economy
- **Move count inflation**: High. Enforcing a sequence almost always increases the path length.
- **BFS minimum recalculation**: Mandatory.
- **Skill expression ceiling**: High. Efficiency in pathing between numbers is the core skill.
- **Star threshold formula compatibility**: Formulas remain fair.

## 9. Mobile UX
- **Touch interaction model**: Standard swipe.
- **Screen real estate**: No impact.
- **Tap state / active feedback**: Numbers must be clearly visible and change state when "activated".
- **Accessibility**: No timing required.

## 10. World Fit & Narrative Coherence
- **Thematic grounding**: "Training" the cat. "Eat from bowl 1, then bowl 2". Or "Step on the piano keys in order".
- **World assignment**: World 3 or Challenge levels.
- **Skin / cosmetic interaction**: None.

## 11. Post-MVP Scope Risk
- **GDD amendment surface**: High. Affects `Coverage Tracking`, `Level Data Format`, `BFS Solver`, and `HUD` (to show current sequence progress).
- **Combinatorial interaction risk**: High. What if you're forced to cover #2 while on your way to #1 because of a Conveyor Belt? (This makes the level unsolvable or requires very clever design).
- **Reversibility**: Moderate.
- **Prototype validation requirement**: High. The "feel" of accidental sequence breaking must be evaluated.
