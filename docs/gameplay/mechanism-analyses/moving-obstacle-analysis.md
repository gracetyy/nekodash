# Moving Obstacle (Periodic Patrol) - Analysis

## 1. Technical Implementation
- **Slide resolver change:** Requires a fundamental paradigm shift in the movement system. Currently, NekoDash is strictly turn-based and deterministic based on static grid states. A real-time patrol introduces a timer-driven loop independent of player input. The `resolve_slide()` function would need to be refactored from a discrete tile-hop calculation into a continuous collision check (potentially using raycasting or frequent polling) to account for mid-slide collisions with a moving object.
- **Grid System tile type:** Does not require a new static tile type, but necessitates a "Dynamic Obstacle" layer in the Grid System. This layer must update tile walkability in real-time (per frame or per tick) to ensure the cat cannot "tunnel" through a moving obstacle during a high-speed slide.
- **New node/system required:** A `PatrolCoordinator` system is required to manage the movement cycles of all patrol objects, ensuring they stay synced with the visual animations and the logical grid state.
- **Signal contract changes:** Existing signals like `slide_completed` and `slide_blocked` would need to be augmented with `slide_interrupted_by_kill` to handle cases where the cat is hit mid-motion.
- **Hard vs. soft dependency:** Hard dependency. Implementing this requires a significant rewrite of the core `SlidingMovement` and `GridSystem` logic to move from a discrete state machine to a hybrid real-time/turn-based model.

## 2. Level Solvability & BFS Impact
- **State space expansion:** Extreme. The BFS state tuple, which currently tracks `(cat_position, covered_tiles)`, would now need to include `(patrol_timer_tick, patrol_positions)`. 
- **State count multiplier:** The multiplier is proportional to the Least Common Multiple (LCM) of all patrol cycle durations in the level. If one obstacle has a 4-tick cycle and another has 6, the state space expands by at least 12x. 
- **BFS tractability threshold:** Likely to exceed the 15-second "tractability" limit even on small grids. To mitigate this, the solver would need to "discretize" time into move-units, but even then, the number of "waiting" states (where the cat stays still to let an obstacle pass) would balloon the search tree.
- **Solver reuse:** The existing `slide()` reference function is incompatible. A new temporal-aware solver is required.
- **Per-level re-verification cost:** Extremely high. Verification would likely shift from a pure BFS proof to a more relaxed "valid path exists" check, potentially losing the "minimum moves" guarantee.

## 3. Level Design Impact
- **Design space opened:** Introduces "rhythm" and "timing" as core gameplay elements. Allows for "safe zones" where players must wait for a window to cross a busy corridor.
- **Design space closed:** Pure, contemplative logic puzzles. The addition of a timer removes the "infinite thinking time" comfort of a pure turn-based game, as the state is technically changing while the player watches.
- **Placement rule compatibility:** Generally compatible, but patrol paths must be clearly visually telegraphed (e.g., floor tracks or distinct path markers) to avoid trial-and-error frustration.
- **Incremental wall-addition workflow:** Broken. Designers can no longer rely on simple geometry to guarantee solvability; they must balance patrol speeds and distances.
- **Difficulty scaling:** Scales rapidly. Small timing windows make levels exponentially harder, potentially alienating casual players.

## 4. Game Design & Player Experience
- **Pillar 1 — Every Move Is a Choice:** **Risk of violation.** If the cat's slide speed and the obstacle's speed are not perfectly tuned, the player may feel they "timed it right" but still got hit due to input latency or rounding errors.
- **Pillar 2 — Joyful at Every Moment:** Can be tedious. Waiting for a slow-moving furniture piece to clear a path is "dead time" that contradicts the snappy feel of a sliding puzzler.
- **Pillar 3 — Complete Your Own Way:** Forces a "one true path" based on the global timer, reducing the feeling of creative solution-finding.
- **Cognitive load:** Very High. Players must process spatial logic AND temporal patterns simultaneously.
- **First-encounter teachability:** High visual clarity (it moves, don't touch it), but low "mechanical" clarity (exactly when is it safe to swipe?).
- **Frustration vs. challenge balance:** High risk of frustration. Moving obstacles in grid-based games often feel "fiddly" rather than "clever."

## 5. Audio & Visual Feedback
- **Unique SFX requirement:** Requires a persistent mechanical hum/whir while moving and a "clunk" at the end of its track.
- **Animation requirement:** Smooth, non-snapping interpolation between grid cells is mandatory to communicate its real-time position.
- **Visual legibility on mobile:** Good, as motion naturally draws the eye. 
- **Thematic fit:** High. A Robot Vacuum (Roomba) or a motorized toy is a perfect fit for a modern apartment.
- **Haptic opportunity:** Light rhythmic pulses on the device while the obstacle is moving nearby.

## 6. Undo / Restart Compatibility
- **Snapshot delta:** `MoveSnapshot` must now capture the `global_timer` or `patrol_phase` of every moving object.
- **Undo atomicity:** Undoing a move must perfectly roll back the global timer to the exact millisecond/tick of the previous turn's start, which is technically challenging to sync with animations.
- **Restart idempotency:** High. Resetting the level simply resets all patrol timers to zero.
- **Signal connection order:** Complex. The `UndoSystem` must force a reset of the `PatrolCoordinator` before the cat is allowed to accept new input.

## 7. Save / Persistence
- **New persisted fields:** None (since mid-level state isn't saved).
- **Mid-level transient state:** None.
- **Best-moves record validity:** Valid, but "Best Time" might become a more relevant metric for these levels.

## 8. Star Rating & Move Economy
- **Move count inflation:** Likely. Players may need to make "waste moves" (sliding against a nearby wall) just to pass time until a patrol window opens.
- **BFS minimum recalculation:** Extremely difficult. Finding the *optimal* path through a moving grid is a much harder computational problem.
- **Skill expression ceiling:** High for speedrunners, but potentially low for logic purists.
- **Star threshold formula compatibility:** Poor. The `min_moves` becomes a moving target based on the initial state of the patrol.

## 9. Mobile UX
- **Touch interaction model:** Standard swipe. However, "swipe-on-release" latency can make precise timing difficult.
- **Screen real estate:** No extra UI needed.
- **Tap state / active feedback:** Visual movement is the feedback.
- **Accessibility:** **Major Concern.** Players with slower reaction times or motor impairments may find timing-based levels impossible to complete.

## 10. World Fit & Narrative Coherence
- **Thematic grounding:** Strong. Robot vacuums, spinning fans, or automated pet feeders.
- **World assignment:** Late-game (World 3) or special "Chaos" levels.
- **Skin / cosmetic interaction:** The patrol obstacle itself could have skins (e.g., a "Roomba with a Cat Hat").

## 11. Post-MVP Scope Risk
- **GDD amendment surface:** Massive. Impact spans `GridSystem`, `SlidingMovement`, `Undo/Restart`, `LevelData`, and `BFS Solver`.
- **Combinatorial interaction risk:** High. What if a pushable block is pushed *into* a patrol path? Does it stop the patrol, or get pushed by it?
- **Reversibility:** Low. Once the core engine is modified to handle real-time logic, it is difficult to "un-real-time" the systems.
- **Prototype validation requirement:** **Mandatory.** A technical prototype must prove that timing feels "fair" on mobile devices before any levels are designed.

