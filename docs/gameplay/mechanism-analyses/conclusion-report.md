# Gameplay Mechanism Synthesis: Conclusion Report

## 1. Executive Summary

This report synthesizes the analysis of 16 proposed gameplay mechanisms for *NekoDash*. After evaluating each against the project's technical, design, and player experience dimensions, the following "Best Candidate" list has been identified for the initial release:

*   **Foundation Trio (World 1):** *Kill Tile*, *Stop-Slide Tile*, and *One-Way Tile*. These are low-risk, high-teachability mechanics that establish the core puzzle vocabulary.
*   **Thematic High-Impact:** *Fallable Item*. This mechanic captures the "quintessential cat experience" with minimal technical friction, providing excellent joyful feedback (Pillar 2).
*   **Strategic Depth:** *Warp Tile* and *Magnet Tile*. These expand the design space by allowing non-linear movement without significantly bloating the BFS solver's complexity.

**Critical Risks:** *Moving Obstacles* and *Two-Cat Co-op* present extreme technical and computational risks. It is recommended to cut or defer these to post-MVP to maintain the game's performance targets and solver tractability.

---

## 2. Comparison Table (Scoring Matrix)

Ratings: **L** (Low concern), **M** (Medium), **H** (High concern).

| Mechanism | Tech | BFS | LD | GDP | AV | Undo | Mob | Fit | Risk |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **1. Moving Obstacle** | H | H | H | M | L | H | H | L | H |
| **2. Kill Tile** | L | L | L | L | L | L | L | L | L |
| **3. Pushable Block** | M | H | L | L | L | M | L | L | H |
| **4. Fallable Item** | M | M | L | L | L | M | L | L | M |
| **5. Door + Key** | M | L | M | L | L | L | L | L | M |
| **6. Stop-Slide Tile** | L | L | L | L | L | L | L | L | L |
| **7. Conveyor Belt** | M | L | M | M | L | L | L | M | M |
| **8. Required Target** | M | M | M | M | L | L | L | M | M |
| **9. Trap Tile** | M | M | M | L | L | L | L | L | M |
| **10. Two-Cat Co-op** | H | H | H | H | M | M | H | M | H |
| **11. Warp Tile** | L | L | L | L | L | L | L | L | L |
| **12. Rotating Obstacle**| M | M | M | L | L | L | L | M | M |
| **13. One-Way Tile** | L | L | L | L | L | L | L | L | L |
| **14. Sleep Tile** | L | M | M | L | L | M | L | L | M |
| **15. Magnet Tile** | L | L | M | L | L | L | L | L | L |
| **16. Crumble Tile** | L | H | M | M | L | M | L | L | H |

---

## 3. Prioritization Roadmap

### **MVP Candidates (Quick Wins)**
*High design impact, low technical risk, and zero to low BFS state expansion.*
*   **Kill Tile (Puddles):** Essential hazard for basic routing.
*   **Stop-Slide Tile (Yarn Ball/Rug):** Opens massive design space for "island" puzzles.
*   **One-Way Tile (Cat Flap):** Foundational for asymmetric routing.
*   **Warp Tile (Laundry Chute):** Simplifies traversal in larger grids while feeling "magical."
*   **Magnet Tile (Magnetic Toys):** Safe "remote movement" mechanic.

### **World-Specific Progression**
*   **World 1 (The Hallway):** Focus on *Stop-Slide*, *One-Way*, and *Kill Tiles* to teach the core loop.
*   **World 2 (The Kitchen/Messy Room):** Introduce *Fallable Items* (vases), *Rotating Obstacles* (spice racks), and *Trap Tiles* (loose floorboards).
*   **World 3 (The Office/Bedroom):** Introduce *Pushable Blocks* (boxes), *Door + Key* (pet gates), and *Required Target Tiles* (numbered bowls).

### **Post-MVP / DLC Content**
*Mechanics with high complexity, state explosion, or significant UI/UX shifts.*
*   **Two-Cat Co-op (Echo Cat):** High state expansion ($Grid^2$) requires dedicated solver optimization.
*   **Crumble Tile:** Significant BFS risk ($2^N$ states) requires strict limits on tile count per level.
*   **Sleep Tile:** Adds turn-skipping logic that complicates move economy.
*   **Moving Obstacle:** **RECONSIDER.** The shift to real-time logic violates the turn-based pillar and creates accessibility barriers. Recommended to pivot toward a turn-based "Patrol" instead.

---

## 4. Conclusion

The core strength of *NekoDash* lies in its "contemplative logic" (Pillar 1) and "tactile joy" (Pillar 2). To preserve these, the team should prioritize mechanics that augment the grid's geometry (*Stop-Slide*, *One-Way*, *Warp*) rather than those that exponentially increase the search space (*Pushable Blocks*, *Crumble Tiles*).

**Final Recommendation:**
Begin implementation with the **World 1 Trio** (Kill, Stop-Slide, One-Way) to stabilize the core systems. Follow immediately with **Fallable Items**, as it provides the strongest thematic link to being a cat. Defer any mechanic with a **High BFS Concern** until the base 30 levels are verified and the solver's performance baseline is established.
