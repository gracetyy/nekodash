# Sleep Tile (Timed Forced Pause) Analysis

## 1. Technical Implementation
- **Slide Resolver Change**: The `resolve_slide()` function itself remains largely untouched for movement, but the `InputSystem` and `CatController` need a significant state check. If the cat is in a `SLEEPING` state, the input must be intercepted.
- **Grid System Tile Type**: A new `tile_type` (e.g., `SLEEP`) is required.
- **New Node/System**: Can be handled within the existing `GridSystem` and `CatController`. A `SleepManager` could handle the visual effects (Zzz particles).
- **Signal Contract**: May need a `cat_woke_up` or `cat_fell_asleep` signal for UI/SFX coordination.
- **Dependency**: Soft dependency on the Input System to block movement.

## 2. Level Solvability & BFS Impact
- **State Space Expansion**: The BFS state tuple must now include `is_sleeping` (boolean) and `sleep_turns` (int). 
- **State Count Multiplier**: High. Every walkable tile potentially has $(N+1)$ states where $N$ is the max sleep duration.
- **BFS Tractability**: Risk of state explosion if many sleep tiles are used in large levels.
- **Solver Reuse**: The `slide()` reference function needs to be aware of the "skip turn" mechanic to calculate optimal move counts.

## 3. Level Design Impact
- **Design Space**: Opens "timing" puzzles without real-time elements. Forces players to consider the move budget more carefully.
- **Placement Rules**: Works anywhere, but most effective in bottlenecks where the extra move cost matters.
- **Difficulty Scaling**: Easy (1 turn sleep) to Hard (multiple turns or multiple sleep tiles in a path).

## 4. Game Design & Player Experience
- **Pillar 1 (Every Move Is a Choice)**: Fully predictable. The player knows landing there costs a turn.
- **Pillar 2 (Joyful)**: Highly joyful if the animation is cute (cat curling up, snoring).
- **Pillar 3 (Your Own Way)**: Often felt as a penalty, so it must be balanced with alternate routes that don't have sleep tiles but take more moves.
- **Cognitive Load**: Low. Simple "wait one turn" rule.
- **Teachability**: Extremely high.

## 5. Audio & Visual Feedback
- **SFX**: Snoring, sudden "mew" when waking up.
- **Animation**: Sleeping pose, stretch animation on wake-up.
- **Thematic Fit**: Perfect for World 1 (Home).

## 6. Undo / Restart Compatibility
- **Snapshot Delta**: `MoveSnapshot` must include `sleep_turns`.
- **Undo Atomicity**: Reversing a "wake up" move should put the cat back to sleep with the previous turn count.

## 7. Save / Persistence
- **Fields**: No mid-level persistence needed as per current design.

## 8. Star Rating & Move Economy
- **Move Inflation**: Directly increases `min_moves`.
- **Recalculation**: Required. The solver must account for the wasted turn.

## 9. Mobile UX
- **Interaction**: Swiping to wake up feels interactive and tactile ("poking" the cat).

## 10. World Fit & Narrative Coherence
- **Thematic Grounding**: Real cats sleep in inconvenient spots (sunbeams, soft rugs).

## 11. Post-MVP Scope Risk
- **Risk**: Medium. BFS performance is the main technical concern.
