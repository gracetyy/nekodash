# New Mechanism Assessment Dimensions

> A reference framework for evaluating any proposed new mechanic in NekoDash. Apply all dimensions before committing a mechanic to a GDD.

---

## 1. Technical Implementation

How much new code does this require, and how cleanly does it integrate?

- **Slide resolver change** — Does `resolve_slide()` need a new condition, a recursive call, or a complete restructure?
- **Grid System tile type** — Does it need a new `tile_type` enum value (e.g., `KILL`, `STICKY`, `MOVABLE`)?
- **New node/system required** — Can it extend an existing GDD (Obstacle System, Grid System), or does it need a standalone system entry in the Systems Index?
- **Signal contract changes** — Does it require new signals, or modifications to existing ones such as `slide_completed` or `slide_blocked`?
- **Hard vs. soft dependency** — Is it a hard dependency on core systems (Grid, Sliding Movement), or a soft downstream subscriber?

---

## 2. Level Solvability & BFS Impact

Does the mechanic remain provably solvable, and at what computational cost?

- **State space expansion** — What new variables enter the BFS state tuple? (e.g., block positions, keys held, items knocked)
- **State count multiplier** — Estimate the worst-case state explosion: covered_set × new_variable_combinations
- **BFS tractability threshold** — Does it push beyond the ~25 walkable tile limit before BFS becomes intractable (>15 s)?
- **Solver reuse** — Can the existing `slide()` reference function be reused unchanged, or must it be forked?
- **Per-level re-verification cost** — Must every level using this mechanic be individually re-solved after any edit?

---

## 3. Level Design Impact

How does it change the designer's workflow and creative toolbox?

- **Design space opened** — Does it enable puzzle geometries that are currently impossible?
- **Design space closed** — Does it invalidate existing level archetypes or wall placement rules?
- **Placement rule compatibility** — Does the edge-row / edge-column obstacle placement principle still hold?
- **Incremental wall-addition workflow** — Can levels still be built one wall at a time with BFS verification after each step?
- **Difficulty scaling** — Does it naturally scale across Easy → Medium → Hard, or is it inherently a late-game mechanic?

---

## 4. Game Design & Player Experience

Does it strengthen or dilute the core pillars?

- **Pillar 1 — Every Move Is a Choice** — Is the outcome fully predictable before the player commits to a swipe? Mechanics that produce surprise outcomes after input break this.
- **Pillar 2 — Joyful at Every Moment** — Does it have a satisfying, expressive animation or feedback moment, even on failure?
- **Pillar 3 — Complete Your Own Way** — Does it give the player agency, or does it feel like the puzzle is fighting them?
- **Cognitive load** — How many simultaneous rules must the player track? Aim for one new rule per introduced mechanic.
- **First-encounter teachability** — Can it be introduced in a single tutorial level with zero explanatory text?
- **Frustration vs. challenge balance** — Does failure feel fair and instructive, or arbitrary?

---

## 5. Audio & Visual Feedback

Does it communicate clearly through sound and animation?

- **Unique SFX requirement** — Does it need new sound design, or can existing SFX (slide whoosh, wall bump, tile land) cover it?
- **Animation requirement** — Does it need a custom tween not already defined in the Sliding Movement GDD?
- **Visual legibility on mobile** — Is the mechanic's current state readable at 375 px width with a full grid visible?
- **Thematic fit** — Does it match the art direction of NekoDash?
- **Haptic opportunity** — Does it have a distinct moment deserving a unique haptic pulse on mobile?

---

## 6. Undo / Restart Compatibility

Can every player action be safely reversed?

- **Snapshot delta** — What new fields must `MoveSnapshot` capture? (e.g., block positions, door states, item states)
- **Undo atomicity** — Can all state changes from one "move" be reversed as a single, indivisible unit?
- **Restart idempotency** — Does `restart()` cleanly reset all mechanic state without a scene reload?
- **Signal connection order** — If the mechanic emits or consumes `slide_completed`, does it need a defined position in the Level Coordinator's connection order?

---

## 7. Save / Persistence

Does it touch the save file, and if so, how?

- **New persisted fields** — Does the mechanic add data to `nekodash_save.json`? If so, a schema version bump and migration function are required.
- **Mid-level transient state** — The save format does not persist mid-level state by design. Does this mechanic require anything that must survive an OS kill?
- **Best-moves record validity** — If the mechanic changes minimum move counts mid-development, are existing `best_moves` records still meaningful?

---

## 8. Star Rating & Move Economy

Does it play well with the 3-star scoring system?

- **Move count inflation** — Does it inherently raise the minimum move count, making 3-star play harder to achieve and teach?
- **BFS minimum recalculation** — Does every level using this mechanic require a dedicated BFS re-run to set accurate star thresholds?
- **Skill expression ceiling** — Does mastery of the mechanic reward tighter solutions, or does it add unavoidable overhead moves with no optimization path?
- **Star threshold formula compatibility** — Do the existing `star3 = min_moves`, `star2 = min_moves + ceil(min_moves × 0.5)` formulas still produce fair thresholds?

---

## 9. Mobile UX

Does it feel natural on a touchscreen?

- **Touch interaction model** — Is the mechanic's effect communicated through a swipe alone, or does it require a tooltip or extra UI element?
- **Screen real estate** — Does it add new HUD indicators that compete with the move counter and star tracker?
- **Tap state / active feedback** — Does every interactive moment have a visible response so the player knows their touch registered?
- **Accessibility** — Does it rely on precise timing or rapid input that would be difficult for players with motor impairments?

---

## 10. World Fit & Narrative Coherence

Does it belong in the cat's apartment?

- **Thematic grounding** — Can the mechanic be explained by a real apartment object without breaking immersion? (e.g., a wet tile, a yarn ball, a magnetic fridge strip)
- **World assignment** — Is it best introduced in World 1, 2, or 3, or reserved for post-MVP bonus levels?
- **Skin / cosmetic interaction** — Could mastery of this mechanic gate a skin unlock, or have a per-world visual variant?

---

## 11. Post-MVP Scope Risk

How much does it cost to add, maintain, or cut?

- **GDD amendment surface** — How many existing approved GDDs require edits to support it? (Grid System, Sliding Movement, Undo/Restart, Level Data Format, BFS Solver)
- **Combinatorial interaction risk** — When combined with other mechanics, does it produce untestable or undefined edge cases?
- **Reversibility** — If it ships and proves unpopular, how many systems must be unwound to remove it cleanly?
- **Prototype validation requirement** — Should it be prototyped on device before a full GDD is written?

---

## Quick-Reference Scoring Template

Use this table when comparing multiple mechanic candidates side by side. Rate each dimension L (Low concern) / M (Medium) / H (High concern).

| Dimension                    | Mechanic A | Mechanic B | Mechanic C |
| ---------------------------- | ---------- | ---------- | ---------- |
| Technical implementation     |            |            |            |
| BFS / solvability impact     |            |            |            |
| Level design impact          |            |            |            |
| Game design / pillars        |            |            |            |
| Audio & visual feedback      |            |            |            |
| Undo / restart compatibility |            |            |            |
| Save / persistence           |            |            |            |
| Star rating & move economy   |            |            |            |
| Mobile UX                    |            |            |            |
| World fit & narrative        |            |            |            |
| Post-MVP scope risk          |            |            |            |

A mechanic with all-L scores is a safe addition. Any H score in dimensions 1–3 (Technical, BFS, Undo) warrants a prototype before committing to a full GDD.
