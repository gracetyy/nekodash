# Gameplay Mechanism Analysis: Conveyor Belt (Forced Extra Slide)

## 1. Technical Implementation
- **Slide resolver change**: High impact. `resolve_slide()` must handle recursive or iterative "extra steps" if a slide ends on a conveyor tile. This changes the slide from a single tween to a potentially multi-stage motion.
- **Grid System tile type**: Requires a new `tile_type` (e.g., `CONVEYOR`) with an associated `direction` attribute.
- **New node/system required**: Integrated into `Sliding Movement`.
- **Signal contract changes**: `slide_completed` only fires *after* the conveyor push finishes.
- **Hard vs. soft dependency**: Hard dependency on slide resolution.

## 2. Level Solvability & BFS Impact
- **State space expansion**: None. Conveyor belts are static grid properties.
- **State count multiplier**: 1x.
- **BFS tractability threshold**: No change to state count, but the transition function (`slide()`) becomes more complex.
- **Solver reuse**: Solver must be updated to handle the "push" logic.
- **Per-level re-verification cost**: Low.

## 3. Level Design Impact
- **Design space opened**: Enables "asymmetric travel" (e.g., you can go from A to B in 1 move, but B to A takes 3 moves). Creates one-way loops and "express routes".
- **Design space closed**: Can make some areas "inaccessible" if conveyor placement isn't careful.
- **Placement rule compatibility**: High.
- **Incremental wall-addition workflow**: Still valid.
- **Difficulty scaling**: Medium to Hard. Players must mentally "project" their final position across multiple steps.

## 4. Game Design & Player Experience
- **Pillar 1 — Every Move Is a Choice**: Outcomes are predictable, but harder to visualize. Clear direction arrows on the tile are mandatory.
- **Pillar 2 — Joyful at Every Moment**: High potential for fun "whoosh" moments. The cat being carried along feels satisfyingly passive.
- **Pillar 3 — Complete Your Own Way**: Can feel like "fighting" the player if used to force them away from their goal.
- **Cognitive load**: Medium. Players must remember "Landing on X pushes me to Y".
- **First-encounter teachability**: Easy. A single arrow pointing to a wall.
- **Frustration vs. challenge balance**: Fair, as long as the visual indicators are unmistakable.

## 5. Audio & Visual Feedback
- **Unique SFX requirement**: A "mechanical hum" or "sliding whir" for the conveyor push.
- **Animation requirement**: A "smooth carry" animation where the cat stays in its idle or sliding pose but moves tile-by-tile.
- **Visual legibility on mobile**: Critical. Must have high-contrast arrows indicating direction.
- **Thematic fit**: A bit of a stretch in a cozy apartment, but could be a "robot vacuum trail", a "slippery floor", or "wind from a fan".
- **Haptic opportunity**: A persistent "vibration" during the conveyor carry.

## 6. Undo / Restart Compatibility
- **Snapshot delta**: None.
- **Undo atomicity**: One move + conveyor push = one undo step.
- **Restart idempotency**: Clean reset.
- **Signal connection order**: Standard.

## 7. Save / Persistence
- **New persisted fields**: None.
- **Mid-level transient state**: None.
- **Best-moves record validity**: No issues.

## 8. Star Rating & Move Economy
- **Move count inflation**: Actually *decreases* move counts for long distances, which is a rare and powerful lever for designers.
- **BFS minimum recalculation**: Mandatory.
- **Skill expression ceiling**: High. Pro players will use conveyors for multi-tile "free" movement.
- **Star threshold formula compatibility**: Formulas remain fair.

## 9. Mobile UX
- **Touch interaction model**: Standard swipe.
- **Screen real estate**: No impact.
- **Tap state / active feedback**: Visual feedback on the conveyor belt while it's moving the cat.
- **Accessibility**: No timing required.

## 10. World Fit & Narrative Coherence
- **Thematic grounding**: Moderate. Can be translated as "slippery spilled water" (World 1), "treadmill" (World 2), or "automatic carpet" (World 3).
- **World assignment**: World 2 or 3.
- **Skin / cosmetic interaction**: None.

## 11. Post-MVP Scope Risk
- **GDD amendment surface**: Moderate. Affects slide logic and tile definitions.
- **Combinatorial interaction risk**: High. What if a conveyor pushes you into a Kill Tile? (Dead). Into a Door? (Stop). Into another Conveyor? (Looping/Chaining). Chaining must have a cycle detection or limit to prevent infinite loops.
- **Reversibility**: Moderate.
- **Prototype validation requirement**: High. Infinite loops and recursive pushes must be tested.
