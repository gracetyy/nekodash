# Magnet Tile (Pull) Analysis

## 1. Technical Implementation
- **Slide Resolver Change**: Requires a "post-slide check". After a standard slide completes, the `GridSystem` must check if the cat is now aligned with a magnet. If so, a new slide is triggered.
- **Grid System Tile Type**: New `MAGNET` type.
- **New Node/System**: The pull logic should reside in the `GridSystem` or a dedicated `EnvironmentalEffectManager`.
- **Signal Contract**: `slide_completed` might be emitted twice (once for the player's move, once for the magnet pull).
- **Dependency**: Hard dependency on `resolve_slide`.

## 2. Level Solvability & BFS Impact
- **State Space Expansion**: None. The pull is deterministic based on position.
- **State Count Multiplier**: 1x.
- **BFS Tractability**: No change to complexity.
- **Solver Reuse**: The `slide()` function in the solver must be updated to recursively apply magnet pulls until a stable position is reached.

## 3. Level Design Impact
- **Design Space**: Allows for "remote" movement. You can reach a tile by sliding into its row/column rather than directly into it.
- **Placement Rules**: Best placed on edges or in "trap" corners.
- **Difficulty Scaling**: Complex interactions when multiple magnets are in range.

## 4. Game Design & Player Experience
- **Pillar 1 (Every Move Is a Choice)**: Predictable if the range is clear.
- **Pillar 2 (Joyful)**: Satisfying "snap" to the magnet.
- **Pillar 3 (Your Own Way)**: Allows for creative routing.
- **Cognitive Load**: Medium. Player must visualize two slides at once.

## 5. Audio & Visual Feedback
- **SFX**: Metallic hum, mechanical "clink".
- **Animation**: Faster slide speed for the pull to distinguish it from player-initiated moves.
- **Thematic Fit**: Magnetic toys, fridge magnets.

## 6. Undo / Restart Compatibility
- **Snapshot Delta**: None.
- **Undo Atomicity**: One undo should reverse both the magnet pull and the player's move.

## 7. Save / Persistence
- **Fields**: None.

## 8. Star Rating & Move Economy
- **Move Inflation**: Can actually reduce moves (shortcuts).

## 9. Mobile UX
- **Interaction**: Standard swipe.
- **Visuals**: Needs clear indicators of the magnet's "pull lines" (e.g., magnetic field pulses).

## 10. World Fit & Narrative Coherence
- **Thematic Grounding**: Kitchen magnets or magnetic cat toys.

## 11. Post-MVP Scope Risk
- **Risk**: Low. One of the safer mechanics to implement technically.
