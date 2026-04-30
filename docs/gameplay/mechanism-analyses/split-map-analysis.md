# Gameplay Mechanism Analysis: #17 Split Map (Shared Control Co-op)

## Overview
The **Split Map** mechanism introduces parallel processing to NekoDash. Two independent grids are controlled by a single swipe input, forcing the player to synchronize the movement of two cats to achieve 100% tile coverage across both boards within a shared move budget.

---

## 1. Technical Implementation
**Rating: H (High Complexity)**

*   **Architectural Shift**: Requires a move from a singleton `Grid` and `Cat` model to a multi-instance model. The `LevelCoordinator` must be refactored to manage multiple `Grid` instances and track their combined completion state.
*   **Slide Resolver**: `resolve_slide()` itself can remain largely the same if encapsulated within a `Cat` or `Grid` object, but the `InputSystem` must now broadcast to multiple listeners, and the `LevelCoordinator` must wait for *both* cats to finish sliding before allowing the next move.
*   **Signal Contracts**: New signals like `all_slides_completed` will be needed to prevent input during simultaneous movement.
*   **Dependencies**: High impact on `LevelCoordinator` and `SceneManager`.

## 2. Level Solvability & BFS Impact
**Rating: H (Critical Risk)**

*   **State Space Explosion**: This is the most significant technical hurdle. In a standard level, the state is `(cat_pos, covered_set)`. In a Split Map level, it becomes `(cat1_pos, cat2_pos, covered1_set, covered2_set)`.
*   **Multiplier**: The state count is essentially the *product* of two independent levels. If Map A has 500 states and Map B has 500 states, the combined state space is 250,000.
*   **Tractability**: BFS solvers will likely exceed the 15s limit for even moderately sized grids. To remain solvable, these levels must be kept small (e.g., two 4x4 grids) or highly constrained.
*   **Solver Fork**: The solver must be heavily modified to handle dual-cat state tuples.

## 3. Level Design Impact
**Rating: H (High Complexity)**

*   **Design Space**: Opens up "desync" puzzles where the player must use walls on one map to "park" one cat while the other cat continues to a specific tile.
*   **Difficulty Scaling**: Difficulty is non-linear. A simple change on Map A might make Map B impossible to solve optimally.
*   **Workflow**: Designers cannot build maps in isolation; they must test the interaction constantly. This breaks the "one wall at a time" incremental workflow unless the solver is extremely fast.

## 4. Game Design & Player Experience
**Rating: M (Medium / High Cognitive Load)**

*   **Pillar 1 (Predictability)**: The outcome remains predictable, but the cognitive load required to predict *two* outcomes simultaneously is significantly higher. 
*   **Cognitive Load**: High. Players must look back and forth between two grids. This may lead to "eye fatigue" or frustration if one map is nearly finished while the other is far behind.
*   **Teachability**: Can be taught visually by showing two small boards, but the "shared move budget" concept must be clearly indicated in the HUD.

## 5. Audio & Visual Feedback
**Rating: M (Medium)**

*   **Visual Real Estate**: Displaying two grids on a mobile screen (especially in portrait mode) is a major challenge. Grids will need to be smaller, potentially impacting legibility of tile decorations.
*   **Feedback Overload**: Two "thuds" (wall bumps) and two "whooshes" happening simultaneously or slightly offset might create audio clutter. SFX may need to be spatialized (Left/Right) to help the player distinguish which cat hit a wall.
*   **Animations**: Simultaneous tweens must be perfectly synced to maintain the feeling of "shared control."

## 6. Undo / Restart Compatibility
**Rating: M (Medium)**

*   **Snapshot Delta**: `MoveSnapshot` must be expanded to include `pos1, pos2, covered1, covered2`. This increases the memory footprint per undo step, though not significantly for modern devices.
*   **Atomicity**: Undo remains atomic; one swipe moves both, one undo reverts both. This is clean and matches player expectations.

## 7. Save / Persistence
**Rating: L (Low)**

*   **Persistence**: Mid-level state isn't saved. The level data format (`.tres` or `.json`) will need a new structure to define two grids within one level resource.
*   **Best Moves**: No change to logic, but 3-star thresholds will be much harder to calculate without a high-performance solver.

## 8. Star Rating & Move Economy
**Rating: H (High Sensitivity)**

*   **Inflation**: Move counts will naturally be higher. 
*   **Optimization**: Mastering Split Map requires "wasted move" minimization—finding paths where both cats make progress simultaneously. This is a high skill ceiling but very difficult for casual players to optimize for 3 stars.

## 9. Mobile UX
**Rating: H (Hardware Constraint)**

*   **Aspect Ratio**: On a 19.5:9 phone, two square grids vertically stacked might fit, but on older 16:9 devices, they will be tiny. 
*   **Input**: Swiping anywhere on screen moves both, which is consistent, but the "active area" for the player's eyes is now split, which can be draining.

## 10. World Fit & Narrative Coherence
**Rating: L (Low)**

*   **Thematic Grounding**: Fits well as a "Bonus" or "Dream World" mechanic. Could be represented as a cat looking into a mirror or a "Split Screen" TV effect in the apartment.
*   **World Assignment**: Best reserved for a "Special" world or post-game challenge levels due to its complexity.

## 11. Post-MVP Scope Risk
**Rating: H (High Risk)**

*   **Scope Creep**: This isn't just a new tile; it's a new *mode*. It touches almost every core system (Input, Grid, Coordinator, Solver, UI).
*   **Cutting**: If this mechanic is poorly received, removing it is difficult because it requires a specific level data structure that is incompatible with standard levels.
*   **Recommendation**: **Mandatory Prototype Required.** The performance of the BFS solver and the visual legibility on mobile must be validated before any GDD work begins.

---

## Final Assessment Score

| Dimension                    | Score |
| ---------------------------- | ----- |
| Technical implementation     | H     |
| BFS / solvability impact     | H     |
| Level design impact          | H     |
| Game design / pillars        | M     |
| Audio & visual feedback      | M     |
| Undo / restart compatibility | M     |
| Save / persistence           | L     |
| Star rating & move economy   | H     |
| Mobile UX                    | H     |
| World fit & narrative        | L     |
| Post-MVP scope risk          | H     |

**Conclusion**: The Split Map mechanic is a high-risk, high-reward feature. While it offers a unique "Aha!" moment and high skill expression, the technical and UX hurdles are significant. It should be considered an "Advanced" mechanic for a post-launch update or a dedicated "Challenge Mode" rather than a core World 1-3 mechanic.
