# Systems Index: NekoDash

> **Status**: Draft
> **Created**: 2026-03-30
> **Last Updated**: 2026-03-30
> **Source Concept**: design/gdd/game-concept.md

---

## Overview

NekoDash is a lean, single-player mobile puzzle game. Its mechanical scope is deliberately
narrow: one core verb (slide), one goal (cover all tiles), one feedback metric
(move count vs. minimum). This scope produces a tight systems footprint — 22 systems
across 6 categories, all required for the jam MVP. There is no networking, no procedural
generation, no AI, and no economy beyond cosmetic skins.

The two bottleneck systems are **Grid System** (10 dependents) and **Level Data Format**
(7 dependents). These must be designed and stabilized before everything else. The
single highest-risk system is **Sliding Movement** — the core verb must be validated
on mobile hardware in week 1, before any further design investment.

---

## Systems Enumeration

| #   | System Name                                                   | Category    | Priority   | Status   | Design Doc                                  | Depends On                                                                          |
| --- | ------------------------------------------------------------- | ----------- | ---------- | -------- | ------------------------------------------- | ----------------------------------------------------------------------------------- |
| 1   | Grid System                                                   | Core        | MVP-Core   | Approved | design/gdd/grid-system.md                   | —                                                                                   |
| 2   | Input System                                                  | Core        | MVP-Core   | Approved | design/gdd/input-system.md                  | —                                                                                   |
| 3   | Save / Load System                                            | Core        | MVP-Core   | Approved | design/gdd/save-load-system.md              | —                                                                                   |
| 4   | Scene Manager                                                 | Core        | MVP-Core   | Approved | design/gdd/scene-manager.md                 | —                                                                                   |
| 5   | SFX Manager                                                   | Audio       | MVP-Polish | Approved | design/gdd/sfx-manager.md                   | —                                                                                   |
| 6   | Cosmetic / Skin Database                                      | Progression | MVP-Skins  | Approved | design/gdd/cosmetic-skin-database.md        | —                                                                                   |
| 7   | Level Data Format                                             | Core        | MVP-Core   | Approved | design/gdd/level-data-format.md             | Grid System                                                                         |
| 8   | Sliding Movement                                              | Gameplay    | MVP-Core   | Approved | design/gdd/sliding-movement.md              | Grid System, Input System                                                           |
| 9   | Obstacle System _(static walls — MVP; dynamic — Full Vision)_ | Gameplay    | MVP-Core   | Approved | design/gdd/obstacle-system.md               | Grid System, Level Data Format                                                      |
| 10  | Music Manager                                                 | Audio       | MVP-Polish | Approved | design/gdd/music-manager.md                 | Scene Manager                                                                       |
| 11  | BFS Minimum Solver _(offline level design tool, not runtime)_ | Core        | MVP-Core   | Approved | design/gdd/bfs-minimum-solver.md            | Grid System, Level Data Format                                                      |
| 12  | Coverage Tracking                                             | Gameplay    | MVP-Core   | Approved | design/gdd/coverage-tracking.md             | Grid System, Sliding Movement                                                       |
| 13  | Move Counter                                                  | Gameplay    | MVP-Core   | Approved | design/gdd/move-counter.md                  | Sliding Movement, Level Data Format                                                 |
| 14  | Undo / Restart                                                | Gameplay    | MVP-Core   | Approved | design/gdd/undo-restart.md                  | Sliding Movement, Coverage Tracking, Move Counter                                   |
| 15  | Star Rating System                                            | Progression | MVP-Polish | Approved | design/gdd/star-rating-system.md            | Move Counter, Level Data Format                                                     |
| 16  | Level Progression                                             | Progression | MVP-Polish | Approved | design/gdd/level-progression.md             | Level Data Format, Save / Load System                                               |
| 17  | Skin Unlock / Milestone Tracker                               | Progression | MVP-Skins  | Approved | design/gdd/skin-unlock-milestone-tracker.md | Star Rating System, Level Progression, Save / Load System, Cosmetic / Skin Database |
| 18  | HUD                                                           | UI          | MVP-Polish | Approved | design/gdd/hud.md                           | Move Counter, Undo / Restart                                                        |
| 19  | Level Complete Screen                                         | UI          | MVP-Polish | Approved | design/gdd/level-complete-screen.md         | Star Rating System, Level Progression, Move Counter                                 |
| 20  | World Map / Level Select                                      | UI          | MVP-Polish | Approved | design/gdd/world-map.md                     | Level Progression, Level Data Format, Save / Load System                            |
| 21  | Main Menu                                                     | UI          | MVP-Polish | Approved | design/gdd/main-menu.md                     | Scene Manager, Save / Load System                                                   |
| 22  | Skin Select Screen                                            | UI          | MVP-Skins  | Approved | design/gdd/skin-select-screen.md            | Cosmetic / Skin Database, Skin Unlock / Milestone Tracker, Save / Load System       |

---

## Categories

| Category        | Description                              | Systems                                                                                      |
| --------------- | ---------------------------------------- | -------------------------------------------------------------------------------------------- |
| **Core**        | Foundation systems everything depends on | Grid System, Input System, Save/Load, Scene Manager, Level Data Format, BFS Solver           |
| **Gameplay**    | The systems that make the game fun       | Sliding Movement, Coverage Tracking, Move Counter, Obstacle System, Undo/Restart             |
| **Progression** | How the player grows over time           | Star Rating System, Level Progression, Skin Unlock/Milestone Tracker, Cosmetic/Skin Database |
| **UI**          | Player-facing information displays       | HUD, Main Menu, World Map/Level Select, Level Complete Screen, Skin Select Screen            |
| **Audio**       | Sound and music systems                  | Music Manager, SFX Manager                                                                   |

---

## Priority Tiers

| Tier            | Definition                                                                        | Systems                                                                                                                                                                                                                               |
| --------------- | --------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **MVP-Core**    | Required for the core loop to function. Cannot test "is this fun?" without these. | Grid System, Input System, Save/Load, Scene Manager, Level Data Format, Sliding Movement, Coverage Tracking, Move Counter, Obstacle System (static), BFS Solver, Undo/Restart                                                         |
| **MVP-Polish**  | Required for a complete, shippable jam submission.                                | Star Rating System, Level Progression, SFX Manager, Music Manager, HUD, Level Complete Screen, World Map/Level Select, Main Menu                                                                                                      |
| **MVP-Skins**   | Required for the skin/unlock feature (in MVP per concept doc).                    | Cosmetic/Skin Database, Skin Unlock/Milestone Tracker, Skin Select Screen                                                                                                                                                             |
| **Full Vision** | Post-jam expansion.                                                               | Dynamic Obstacle variants (moving walls, teleporters, timed), Rewarded Ads integration, IAP Skin Shop, Leaderboards, **Procedural Level Generator**, **Skin Ability System**, **Undo-Penalty Star Formula**, **Save File Anti-Cheat** |

---

## Post-Jam Backlog

Tracked design changes that go beyond MVP scope. Each item has a note in the relevant GDD's Open Questions section.

| Item                               | Affects                                                                                                                                 | GDD(s) to update when designed                                          |
| ---------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| **Procedural level generation**    | BFS Minimum Solver (must run in-engine), Level Data Format (no fixed `res://` paths), Level Progression, World Map                      | `bfs-minimum-solver.md`, `level-data-format.md`, `level-progression.md` |
| **Skins with gameplay abilities**  | Cosmetic / Skin Database (new `SkinAbility` resource), Sliding Movement, Star Rating System, Move Counter, HUD                          | New **Skin Ability System** GDD required before implementation          |
| **Undo count impacts star rating** | Star Rating System (formula change), Move Counter (expose undo count), Level Data format (new threshold fields?), Level Complete Screen | `star-rating-system.md` — see OQ-2                                      |
| **Save file anti-cheat**           | Save / Load System (HMAC checksum or obfuscation)                                                                                       | `save-load-system.md` — see OQ-4                                        |

---

## Dependency Map

Systems are sorted by dependency order — design and build from top to bottom.
Each layer can only begin once all layers above it are stable.

### Foundation Layer (no dependencies)

1. **Grid System** — Defines tile coords, tile type enum, walkable/blocked state; every other system builds on this
2. **Input System** — Swipe/tap-and-drag recognition; cardinal direction resolution; OS edge-swipe mitigation
3. **Save / Load System** — Godot FileAccess wrapper; serializes/deserializes game state; no gameplay dependencies
4. **Scene Manager** — Screen state machine; manages transitions; Music Manager listens to it for world changes
5. **SFX Manager** — Audio playback API; gameplay systems call into it; depends on nothing
6. **Cosmetic / Skin Database** — Static data catalog of all skins, asset refs, and unlock conditions

### Core Layer (depends on Foundation only)

7. **Level Data Format** — depends on: Grid System
8. **Sliding Movement** — depends on: Grid System, Input System
9. **Obstacle System** — depends on: Grid System, Level Data Format
10. **Music Manager** — depends on: Scene Manager

### Feature Layer (depends on Core)

11. **BFS Minimum Solver** _(offline tool)_ — depends on: Grid System, Level Data Format
12. **Coverage Tracking** — depends on: Grid System, Sliding Movement
13. **Move Counter** — depends on: Sliding Movement, Level Data Format

### Progression Layer (depends on Feature)

14. **Undo / Restart** — depends on: Sliding Movement, Coverage Tracking, Move Counter
15. **Star Rating System** — depends on: Move Counter, Level Data Format
16. **Level Progression** — depends on: Level Data Format, Save / Load System

### Unlock Layer (depends on Progression)

17. **Skin Unlock / Milestone Tracker** — depends on: Star Rating System, Level Progression, Save/Load System, Cosmetic/Skin Database

### Presentation Layer (wraps everything below)

18. **HUD** — depends on: Move Counter, Undo/Restart
19. **Level Complete Screen** — depends on: Star Rating System, Level Progression, Move Counter
20. **World Map / Level Select** — depends on: Level Progression, Level Data Format, Save/Load System
21. **Main Menu** — depends on: Scene Manager, Save/Load System
22. **Skin Select Screen** — depends on: Cosmetic/Skin Database, Skin Unlock/Milestone Tracker, Save/Load System

---

## Recommended Design Order

Design these systems in this order. Systems within the same numbered group are
independent and can be designed in parallel.

| Order | System                           | Priority   | Layer        | Recommended Agent                               | Est. Effort |
| ----- | -------------------------------- | ---------- | ------------ | ----------------------------------------------- | ----------- |
| 1     | Grid System                      | MVP-Core   | Foundation   | godot-gdscript-specialist + game-designer       | S           |
| 2     | Input System                     | MVP-Core   | Foundation   | godot-gdscript-specialist + ux-designer         | S           |
| 3     | Level Data Format                | MVP-Core   | Core         | game-designer + godot-gdscript-specialist       | M           |
| 4     | BFS Minimum Solver               | MVP-Core   | Feature      | ai-programmer + godot-gdscript-specialist       | M           |
| 5     | Sliding Movement                 | MVP-Core   | Core         | gameplay-programmer + godot-gdscript-specialist | M           |
| 6     | Coverage Tracking                | MVP-Core   | Feature      | gameplay-programmer                             | S           |
| 7     | Move Counter                     | MVP-Core   | Feature      | gameplay-programmer                             | S           |
| 8     | Obstacle System _(static walls)_ | MVP-Core   | Core         | game-designer + gameplay-programmer             | S           |
| 9     | Save / Load System               | MVP-Core   | Foundation   | godot-gdscript-specialist                       | S           |
| 10    | Scene Manager                    | MVP-Core   | Foundation   | godot-gdscript-specialist                       | S           |
| 11    | Undo / Restart                   | MVP-Core   | Progression  | gameplay-programmer                             | S           |
| 12    | Star Rating System               | MVP-Polish | Progression  | game-designer                                   | S           |
| 13    | Level Progression                | MVP-Polish | Progression  | game-designer                                   | S           |
| 14    | SFX Manager                      | MVP-Polish | Foundation   | sound-designer + godot-gdscript-specialist      | S           |
| 15    | Music Manager                    | MVP-Polish | Core         | audio-director + godot-gdscript-specialist      | S           |
| 16    | HUD                              | MVP-Polish | Presentation | ui-programmer + ux-designer                     | S           |
| 17    | Level Complete Screen            | MVP-Polish | Presentation | ui-programmer + game-designer                   | S           |
| 18    | World Map / Level Select         | MVP-Polish | Presentation | ui-programmer + level-designer                  | M           |
| 19    | Main Menu                        | MVP-Polish | Presentation | ui-programmer + art-director                    | S           |
| 20    | Cosmetic / Skin Database         | MVP-Skins  | Foundation   | game-designer                                   | S           |
| 21    | Skin Unlock / Milestone Tracker  | MVP-Skins  | Unlock       | game-designer                                   | S           |
| 22    | Skin Select Screen               | MVP-Skins  | Presentation | ui-programmer + art-director                    | S           |

> Effort estimates: **S** = 1 design session, **M** = 2–3 design sessions.
> A "session" produces one complete, reviewed GDD.

---

## Circular Dependencies

None found. The dependency graph is strictly acyclic (DAG) — all layers are
one-directional.

---

## High-Risk Systems

Prototype or validate these early regardless of design order.

| System                 | Risk Type | Risk Description                                                                                     | Mitigation                                                                                                   |
| ---------------------- | --------- | ---------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| **Sliding Movement**   | Design    | Core verb doesn't feel satisfying on mobile touchscreen; the whole game collapses if this is wrong   | Prototype in week 1 using `/prototype sliding-movement` before designing anything else                       |
| **Input System**       | Technical | iOS/Android OS edge swipes intercept game input; swiping from screen edges is unplayable             | Test export to a real device in week 1; use tap-and-drag rather than pure swipe if needed                    |
| **BFS Minimum Solver** | Technical | Large grids with many obstacle states produce degenerate minimum solutions or excessive compute time | Pre-compute at level-design time, not runtime; human-review every level's minimum before publishing          |
| **Level Data Format**  | Scope     | Schema designed too late → level files and BFS solver both require rework mid-development            | Design concurrently with Grid System as a first-week artifact; freeze the schema before authoring any levels |

---

## Progress Tracker

| Metric                      | Count   |
| --------------------------- | ------- |
| Total systems identified    | 22      |
| Design docs started         | 16      |
| Design docs reviewed        | 16      |
| Design docs approved        | 16      |
| MVP-Core systems designed   | 11 / 11 |
| MVP-Polish systems designed | 5 / 8   |
| MVP-Skins systems designed  | 0 / 3   |

---

## Next Steps

- [x] Design Grid System (`design/gdd/grid-system.md`) — Approved
- [x] Design Input System (`design/gdd/input-system.md`) — Approved
- [x] Design Level Data Format (`design/gdd/level-data-format.md`) — Approved
- [x] Design BFS Minimum Solver (`design/gdd/bfs-minimum-solver.md`) — Approved
- [x] Design Sliding Movement (`design/gdd/sliding-movement.md`) — Approved
- [x] Design Coverage Tracking (`design/gdd/coverage-tracking.md`) — Approved
- [x] Design Move Counter (`design/gdd/move-counter.md`) — Approved
- [x] Design Obstacle System (`design/gdd/obstacle-system.md`) — Approved
- [x] Design Save / Load System (`design/gdd/save-load-system.md`) — Approved
- [x] Design Scene Manager (`design/gdd/scene-manager.md`) — Approved
- [x] Design Undo / Restart (`design/gdd/undo-restart.md`) — Approved
- [x] **MVP-Core COMPLETE** — All 11 core systems designed. Begin MVP-Polish tier.
- [x] Design Star Rating System (`design/gdd/star-rating-system.md`) — Approved
- [x] Design Level Progression (`design/gdd/level-progression.md`) — Approved
- [x] Design SFX Manager (`design/gdd/sfx-manager.md`) — Approved
- [x] Design Music Manager (`design/gdd/music-manager.md`) — Approved
- [x] Design HUD (`design/gdd/hud.md`) — Approved
- [x] Design Level Complete Screen (`design/gdd/level-complete-screen.md`) — Approved
- [x] Design World Map / Level Select (`design/gdd/world-map.md`) — Approved
- [x] Design Main Menu (`design/gdd/main-menu.md`) — Approved
- [x] Design Cosmetic / Skin Database (`design/gdd/cosmetic-skin-database.md`) — Approved
- [x] Design Skin Unlock / Milestone Tracker (`design/gdd/skin-unlock-milestone-tracker.md`) — Approved
- [x] Design Skin Select Screen (`design/gdd/skin-select-screen.md`) — Approved
- [x] **ALL 22/22 SYSTEMS DESIGNED** — Full pre-production design phase complete.
- [ ] Run `/gate-check pre-production` to validate MVP-Core before beginning Polish tier
- [ ] Run `/prototype sliding-movement` early to validate the core verb on mobile
- [ ] Run `/design-review` on each completed GDD
- [ ] Run `/gate-check pre-production` when all MVP-Core systems are designed
- [ ] Run `/sprint-plan new` to map design sessions to calendar weeks
