## Scope Check: NekoDash — Post-Sprint 2

Generated: 2026-04-02

---

### Original Scope

From systems-index.md (approved 2026-03-30) — **22 planned systems** across 5 categories:

| #   | System                        | Priority   |
| --- | ----------------------------- | ---------- |
| 1   | Grid System                   | MVP-Core   |
| 2   | Input System                  | MVP-Core   |
| 3   | Save/Load System              | MVP-Core   |
| 4   | Scene Manager                 | MVP-Core   |
| 5   | Level Data Format             | MVP-Core   |
| 6   | Sliding Movement              | MVP-Core   |
| 7   | Obstacle System               | MVP-Core   |
| 8   | BFS Minimum Solver            | MVP-Core   |
| 9   | Coverage Tracking             | MVP-Core   |
| 10  | Move Counter                  | MVP-Core   |
| 11  | Undo/Restart                  | MVP-Core   |
| 12  | Star Rating System            | MVP-Polish |
| 13  | Level Progression             | MVP-Polish |
| 14  | HUD                           | MVP-Polish |
| 15  | Level Complete Screen         | MVP-Polish |
| 16  | World Map / Level Select      | MVP-Polish |
| 17  | Main Menu                     | MVP-Polish |
| 18  | SFX Manager                   | MVP-Polish |
| 19  | Music Manager                 | MVP-Polish |
| 20  | Cosmetic/Skin Database        | MVP-Skins  |
| 21  | Skin Unlock/Milestone Tracker | MVP-Skins  |
| 22  | Skin Select Screen            | MVP-Skins  |

Sprint 1–2 planned tasks: **18 total** (9 per sprint).
Expected calendar use: **10 days** (2 × 5-day sprints).

---

### Current Scope

**Implemented production systems (13 of 22 planned):**
`grid_system`, `input_system`, `save_manager`, `scene_manager`, `level_data`, `sliding_movement`, `coverage_tracking`, `move_counter`, `undo_restart`, `star_rating_system`, `level_progression`, `hud`, `level_complete_screen`

**Implemented dev tools (1 planned + 2 unplanned):**
level_solver.gd (BFS solver, planned S1-09), playtest_capture.gd, playtest_runner.gd

**Implemented unplanned production files:**
`level_coordinator.gd`, `level_catalogue.gd`, `cat_sprite.gd`, `grid_renderer.gd`, `coverage_visualizer.gd`

**Scenes created (2):** `gameplay.tscn`, `level_complete.tscn`

**Not yet implemented (9 of 22 planned):** Obstacle System, SFX Manager, Music Manager, World Map, Main Menu, Cosmetic/Skin Database, Skin Unlock/Milestone Tracker, Skin Select Screen — plus the BFS Solver is in tools/ (delivered) but the Obstacle System has a GDD and is MVP-Core yet has 0 commits.

---

### Scope Additions (not in original plan)

| Addition                                                                 | Source                                                 | When    | Justified?                                                                                                               | Effort |
| ------------------------------------------------------------------------ | ------------------------------------------------------ | ------- | ------------------------------------------------------------------------------------------------------------------------ | ------ |
| `level_coordinator.gd` orchestration layer                               | Sprint 1 unplanned; `feat: implement LevelCoordinator` | Apr 1   | **Yes** — obvious requirement; no GDD named it but it's the necessary glue layer                                         | M      |
| Gameplay prototype scene (`gameplay_scene.gd` + scene wiring)            | Sprint 1 unplanned, buffer capacity                    | Apr 1   | **Yes** — proved core hypothesis; validated M1 early                                                                     | M      |
| `grid_renderer.gd` (109 lines) + `cat_sprite.gd` (91 lines)              | `feat: enhance gameplay scene visuals`                 | Apr 2   | **Yes** — implementation detail always required; not named as systems in GDD                                             | S      |
| `coverage_visualizer.gd` (Node2D, signal-driven; spec said TileMapLayer) | S2-08 NTH; different architecture than spec            | Apr 2   | **Yes, spec change justified** — replaced a `GridRenderer` entanglement with a cleaner isolated component; R-11 resolved | S      |
| playtest_capture.gd + playtest_runner.gd (413 lines total)               | `feat: add auto playtest helper scripts for AI agents` | Apr 2   | **Unclear** — no sprint task, no GDD; valuable for AI-assisted dev workflow but zero player value                        | M      |
| 6 levels in catalogue instead of 3                                       | S2-09; Sprint 2 NTH                                    | Apr 2   | **Yes** — more content is good; BFS-verified; no risk                                                                    | S      |
| 4 playtest bug fixes (undo button, flash, label, visual rollback)        | Post-playtest; `fix: undo bugs`                        | Apr 2   | **Yes** — playtest-driven, all Severity-2 issues; raised ship quality                                                    | S      |
| SceneManager promoted from stub → real scene swapper mid-sprint          | Triggered by S2-06; not a named sprint task            | Apr 1–2 | **Yes, but should have been a task** — it was a hidden dependency of S2-06 that became visible at implementation time    | S      |
| `level_catalogue.gd` thin wrapper                                        | Part of S2-05 wiring                                   | Apr 1   | **Yes** — trivial, necessary                                                                                             | XS     |

### Scope Removals (in original but dropped/deferred)

| Removed Item                           | Reason                                     | Impact                                                                                                                                                                                                                        |
| -------------------------------------- | ------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Obstacle System (MVP-Core, GDD exists) | Not yet started; no sprint task assigned   | **Moderate** — it's MVP-Core per the systems index; static walls exist but the `obstacle_system.gd` system node with its types, signals, and Level Data integration is absent. Levels currently only use grid boundary walls. |
| SFX Manager, Music Manager             | Not yet started; deferred to later sprints | Low now — no audio GDD implementation started                                                                                                                                                                                 |
| World Map, Main Menu                   | Not yet started                            | Low now — game navigates via SceneManager directly                                                                                                                                                                            |

---

### Bloat Score

| Metric                                | Value               |
| ------------------------------------- | ------------------- |
| Original sprint tasks planned (S1+S2) | 18                  |
| Planned sprint tasks completed        | 18                  |
| Unplanned items delivered             | 11                  |
| Total items delivered                 | 29                  |
| Items added (unplanned)               | +11 (+61%)          |
| Items removed / deferred              | 0 from sprint scope |
| **Net sprint scope change**           | **+61%**            |
| Original game design systems (22)     | 22                  |
| New systems added to GDD              | **0**               |
| **Net design scope change**           | **0%**              |

The two numbers tell different stories. Sprint task scope ballooned +61% — but **zero new systems were added to the 22-system game design**. Every unplanned addition was either an implementation artifact (coordinator, renderer), a bug fix, tooling, or use of surplus buffer capacity. The GDD scope is clean.

---

### Risk Assessment

- **Schedule Risk**: **Low** — Team velocity is running at 5× plan. The 8 remaining systems (World Map, Main Menu, audio, skins etc.) have approved GDDs. At current pace, the 6-week jam deadline is not threatened by scope creep; the risk is the opposite: under-planning Sprint 3, not overbuilding.
- **Quality Risk**: **Low-Medium** — The unplanned playtest tooling (`playtest_capture.gd`, `playtest_runner.gd`, 413 lines) has no tests and no GDD. If these scripts break silently, automated playtests will produce false-pass results. The risk is small but non-zero.
- **Integration Risk**: **Low** — `level_coordinator.gd` is the only unplanned system that other systems depend on, and it has dedicated integration tests. No unplanned system creates a new dependency web.
- **Obstacle System Gap Risk**: **Medium** — Obstacle System is listed as MVP-Core in the systems index but has 0 implementation. Current levels work without it (pure walls via grid boundary), but any level design that requires interior wall tiles, pushable blocks, or multi-type obstacles is blocked until it's implemented. This is a **planned gap**, not creep — but it needs a sprint slot.

---

### Recommendations

1. **Keep** — All unplanned deliveries to date. Every addition was either justified implementation detail, a quality-raising bug fix, or bonus content (levels 4–6). Nothing was gratuitous.

2. **Flag** — playtest_capture.gd + playtest_runner.gd. These are real, useful dev tools but they: (a) have no sprint task, (b) have no tests, (c) have 413 lines of code that could silently break. A decision is needed: either formally adopt them as maintained tooling (add to dev tooling GDD / write tests) or document them as "best-effort / throwaway scripts." **Owner: producer + technical-director. Deadline: Sprint 3 kickoff.**

3. **Schedule** — Obstacle System (MVP-Core) must get a Sprint 3 task slot. It is the only MVP-Core system with a GDD and zero implementation. All current 6 levels avoid it by using only boundary walls. This works for World 1 but any interesting level design in World 2+ will need it.

4. **Defer** — Audio (SFX Manager, Music Manager), Skin systems, World Map, and Main Menu are correctly deferred. They have GDDs, they're not blocking anything, and the team clearly has capacity to reach them in Sprint 3–5 at current velocity.

5. **Do not add** — Any new systems beyond the 22 GDDs. R-06 (jam deadline scope creep) is the one open risk in the register. The 22-system design is clean and complete. Adding a 23rd system — even a good idea — costs a GDD, design time, implementation time, and test time from a fixed jam deadline. Any new idea should go on the post-jam backlog.

---

### Verdict: **ON TRACK ✅**

Game design scope has **0% creep** — all 22 systems remain as originally planned, none added. Sprint execution scope ran +61% over plan, but every unplanned item used surplus buffer capacity and raised quality; none pushed out any planned work. The one genuine concern is the two playtest tools that are un-tested and un-owned — flag them for a decision. The Obstacle System gap needs a sprint slot before World 2 level authoring begins.
