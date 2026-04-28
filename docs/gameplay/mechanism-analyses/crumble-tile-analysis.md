# Crumble Tile (One-Time Walkable) Analysis

## 1. Technical Implementation
- **Slide Resolver Change**: After the cat passes over or lands on a crumble tile, it must be marked as "broken".
- **Grid System Tile Type**: New `CRUMBLE` type.
- **New Node/System**: Handled by the `GridSystem`.
- **Signal Contract**: `tile_stepped_on` or `tile_covered` triggers the state change.
- **Dependency**: Hard dependency on the Grid System's walkability logic.

## 2. Level Solvability & BFS Impact
- **State Space Expansion**: **High.** Requires a bitmask of all crumble tiles in the level.
- **State Count Multiplier**: $2^N$ where $N$ is the number of crumble tiles.
- **BFS Tractability**: Significant risk of intractability if $N > 10$.
- **Solver Reuse**: Solver must track the state of every crumble tile.

## 3. Level Design Impact
- **Design Space**: Creates "bridge-burning" puzzles. Routes disappear as you use them.
- **Placement Rules**: Critical for creating bottlenecks and forced ordering.
- **Difficulty Scaling**: Scales linearly with the number of crumble tiles.

## 4. Game Design & Player Experience
- **Pillar 1 (Every Move Is a Choice)**: Highly predictable.
- **Pillar 2 (Joyful)**: High stakes. Satisfying "crack" sound.
- **Pillar 3 (Your Own Way)**: Constrains choices significantly, but rewards perfect planning.

## 5. Audio & Visual Feedback
- **SFX**: Cracking, ceramic shattering.
- **Animation**: Visual cracks appear as you pass; tile falls away or becomes "rubble".
- **Thematic Fit**: Thin rugs, cracked floor tiles, paper bags.

## 6. Undo / Restart Compatibility
- **Snapshot Delta**: Bitmask of crumbled tiles.
- **Undo Atomicity**: Undo must restore the tile to its "intact" state.

## 7. Save / Persistence
- **Fields**: None.

## 8. Star Rating & Move Economy
- **Move Inflation**: None.
- **Recalculation**: Required.

## 9. Mobile UX
- **Interaction**: Standard swipe.
- **Visuals**: Must be extremely clear if a tile is walkable vs. broken.

## 10. World Fit & Narrative Coherence
- **Thematic Grounding**: Fragile objects in an apartment.

## 11. Post-MVP Scope Risk
- **Risk**: Medium-High due to BFS state explosion.
