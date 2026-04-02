# Milestone 2: Submission Ready

**Target Date**: 2026-04-14
**Status**: 🔶 In Progress — Sprint 3 begins 2026-04-02
**Sprints Allocated**: Sprint 3 · Sprint 4 (estimate: 2 sprints, 2–3 calendar days each)

---

## Description

M2 delivers a **complete, shippable jam submission**. Every system in the MVP scope
is implemented and integrated. The player can launch the game from a main menu,
play any unlocked level through a world map, complete all levels across World 1,
hear audio feedback, and have their progress saved to disk across restarts.

M1 delivered the core loop. M2 delivers the **frame around the loop** — navigation,
persistence, audio, obstacles, and polished level content — so the game is
indistinguishable from a finished jam entry.

> **Scope discipline**: The MVP-Skins tier (Cosmetic/Skin Database, Skin Unlock
> Tracker, Skin Select Screen) is **not required** for M2. It is a bounded Sprint 4
> bonus target if capacity allows after all M2 exit criteria are met.

---

## Exit Criteria

All criteria must be ✅ before M2 is declared GO.

### Core Systems

- [ ] **SaveManager — disk persistence**: `save_game()` and `load_game()` read/write a
      `ConfigFile` to `user://save.cfg`; level completion records and star ratings survive
      app restart; stub warning removed
- [ ] **Obstacle System — static walls**: `ObstacleTileData` or equivalent blocks sliding
      movement; at least 2 World 1 levels redesigned to include static obstacles; BFS
      solver updated to respect obstacle tiles; minimum_moves values re-verified

### Navigation & UI

- [ ] **World Map scene**: `res://scenes/ui/world_map.tscn` exists and is reachable;
      level nodes show unlock state and star count loaded from SaveManager; tapping a
      level node navigates to gameplay; back button navigates to Main Menu
- [ ] **World Map button functional**: "World Map" button on Level Complete screen
      transitions correctly to `world_map.tscn` (Bug #3 fixed)
- [ ] **Main Menu scene**: `res://scenes/ui/main_menu.tscn` exists as game entry point;
      "Play" navigates to World Map; scene displays game title and logo/icon

### Level Content

- [ ] **w1_l4–w1_l6 redesigned**: each redesigned level offers at least one meaningful
      route fork — a choice point where a suboptimal path is reachable but the optimal
      path requires a deliberate sequence; BFS minimum_moves re-verified after redesign
- [ ] **At least 8 total levels**: existing 6 levels + 2 new levels that showcase the
      Obstacle System (these may be World 1 extras or World 2 introductory levels)

### Audio

- [ ] **SFX Manager operational**: `SfxManager` autoload exists; plays at minimum:
      `slide_move` (movement), `level_complete` (win), `star_earned` (rating), `button_tap`
      (UI); audio bus routing documented
- [ ] **Music Manager stub or production**: `MusicManager` autoload exists; plays at
      minimum one background track for gameplay; pauses on app focus lost

### Polish & Bug Fixes

- [ ] **Star icons enlarged and recolored**: star icons on Level Complete screen are
      ≥48×48 logical px and display in gold/yellow when earned, grey when unearned
      (Bug #5 fixed)
- [ ] **Star rating thresholds balanced**: `minimum_moves` in level `.tres` files
      reviewed; 3-star threshold is achievable without perfect foreknowledge for levels
      w1_l4–w1_l6 (adjust par offsets by +1–2 moves if needed)

### Technical Debt (mandatory clearance)

- [ ] **TD-001 fixed**: `tests/test_level_data.gd:243` — `var tile: Node` → `var tile:
      GridSystem.GridTileData`; zero SCRIPT ERRORs on test run
- [ ] **TD-002 fixed**: dead overlay block removed from `level_coordinator.gd` —
      `LEVEL_COMPLETE_OVERLAY_DELAY_SEC`, `var _overlay`, `_show_level_complete_overlay()`,
      `_on_overlay_retry()`, `_on_overlay_next()` all deleted (~122 lines)
- [ ] **TD-003 resolved**: SaveManager stub replaced with real disk I/O (see Core Systems)
- [ ] **TD-006 resolved**: ownership decision recorded for `playtest_capture.gd` and
      `playtest_runner.gd` — either assigned sprint tasks with a test file or explicitly
      documented as "unowned tooling, no maintenance contract"

### Quality Gates

- [ ] **0 open Severity-1 bugs**
- [ ] **0 open Severity-2 bugs**
- [ ] **GUT tests: ≥500 passing, 0 failing**
- [ ] **Automated playtest: all levels PASS** (6+ levels, 3-star optimal verified)
- [ ] **0 TODO / FIXME / HACK markers** in `src/` or `tests/`

---

## Systems Delivered by This Milestone

| System                      | M1 Status          | M2 Target                                            |
| --------------------------- | ------------------ | ---------------------------------------------------- |
| Save / Load System          | ⚠️ Stub only       | ✅ Real disk I/O (`user://save.cfg`)                 |
| Obstacle System (static)    | ❌ Not started     | ✅ Static walls in grid, ≥2 levels using obstacles   |
| World Map / Level Select    | ❌ Not started     | ✅ Scene navigable from Level Complete screen        |
| Main Menu                   | ❌ Not started     | ✅ Entry point scene with Play button                |
| SFX Manager                 | ❌ Not started     | ✅ Autoload, ≥4 SFX wired                            |
| Music Manager               | ❌ Not started     | ✅ Autoload, ≥1 background track                     |
| Level content (L4–L6)       | ⚠️ No route forks  | ✅ Redesigned with choice points                     |
| Level Complete Screen       | ✅ Done (S2)       | ✅ Bug fixes: World Map btn + star visuals            |
| Star Rating System          | ✅ Done (S2)       | ✅ Threshold balance pass                            |
| All M1 systems              | ✅ Done            | ✅ Unchanged, no regressions permitted               |

### Not In Scope for M2 (MVP-Skins tier — M3 target or Sprint 4 bonus)

| System                       | Rationale                                                               |
| ---------------------------- | ----------------------------------------------------------------------- |
| Cosmetic / Skin Database     | No content dependency for core submission; adds scope risk              |
| Skin Unlock / Milestone Tracker | Requires Cosmetic DB + save integration; blocked until save is real  |
| Skin Select Screen           | UI surface that requires above two systems                              |

---

## Sprint Allocation

| Sprint   | Primary Focus                                                                        | Estimated Tasks |
| -------- | ------------------------------------------------------------------------------------ | --------------- |
| Sprint 3 | TD-001/002/003/006 · World Map scene · World Map btn fix · SaveManager disk I/O · Star visuals | 16–20 |
| Sprint 4 | Obstacle System · Main Menu · SFX Manager · Level redesign L4–L6 · New levels · Music Manager stub | 16–20 |

> **Velocity reference**: Sprints 1–2 completed 11 and 18 tasks respectively in ~1 calendar day
> each. 16-task sprints are a conservative floor. Total M2 work (~32–40 tasks) fits within
> 2 sprints at historical velocity.

---

## Risk Assessment

| ID  | Risk                                                            | Probability | Impact | Mitigation                                                                                              |
| --- | --------------------------------------------------------------- | ----------- | ------ | ------------------------------------------------------------------------------------------------------- |
| R-06 | Jam deadline scope creep                                       | Medium      | High   | MVP-Skins tier is explicitly excluded from M2. No new systems without producer sign-off.               |
| R-13 | Obstacle System integration touches GridSystem + LevelData API | Medium      | Medium | Use additive API changes only (new `is_obstacle()` flag, no breaking changes to existing methods)      |
| R-14 | Level redesign invalidates existing BFS-verified solutions     | Low         | Medium | Re-run BFS solver on every redesigned level file before close. CI step or manual pre-commit check.     |
| R-15 | SaveManager real I/O introduces corruption/migration edge cases | Low         | High  | Version field in save file; graceful fallback to fresh save on version mismatch; test corrupted save.  |
| R-16 | Audio assets not available in time                             | Medium      | Low    | SFX Manager must compile and play silence/stub without crashing; audio assets can be placeholders.     |

---

## Velocity Analysis (projection)

| Metric                        | Value                                                                          |
| ----------------------------- | ------------------------------------------------------------------------------ |
| M1 actual velocity            | 29 tasks / 2.5 calendar days (~11.6 tasks/day)                                 |
| M2 estimated task count       | 32–40 tasks                                                                    |
| Estimated calendar days (M2)  | 3–4 days at historical velocity (well within 2026-04-14 target)                |
| Confidence                    | High — no novel technical unknowns; all systems have approved GDDs             |
| Jam deadline                  | ~2026-05-11 (6 weeks from project start 2026-03-30) — **9 weeks remaining**   |
| Buffer after M2               | 3–4 weeks for M3 (skins), playtesting, store submission prep                   |

---

## Action Items Before Sprint 3 Kickoff

| # | Action                                                                              | Owner                     | Deadline           |
| - | ----------------------------------------------------------------------------------- | ------------------------- | ------------------ |
| 1 | Run `/sprint-plan new` with this M2 definition as context                           | producer                  | 2026-04-02 (today) |
| 2 | Fix TD-001 as Sprint 3, Day 1 task (one-line type fix)                              | godot-gdscript-specialist | Sprint 3, Day 1    |
| 3 | Delete dead overlay block TD-002 as Sprint 3, Day 1 task                            | gameplay-programmer       | Sprint 3, Day 1    |
| 4 | Add R-13, R-14, R-15, R-16 to risk register                                        | producer                  | Sprint 3, Day 1    |
| 5 | Confirm audio asset sourcing plan (original SFX, CC0 library, or placeholder files) | audio-director            | Sprint 3, Day 2    |
